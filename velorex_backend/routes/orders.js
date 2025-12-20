const express = require("express");
const router = express.Router();
const morgan = require("morgan");
const pool = require("../models/db");

router.use(morgan("dev"));
router.use((req, _, next) => {
  console.log("➡️", req.method, req.originalUrl);
  next();
});


// ===================================================================
// 1️⃣ CREATE ORDERS (ONE ORDER PER ITEM)
// ===================================================================
router.post("/create", async (req, res) => {
  const {
    userId,
    paymentMethod,
    cartItems,
    shippingAddress,
    shippingId,
    couponCode,
    discountAmount = 0
  } = req.body;

  if (!userId || !paymentMethod || !Array.isArray(cartItems)) {
    return res.status(400).json({
      success: false,
      message: "Missing required fields"
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    let offerSubtotal = 0;

    const itemsMeta = cartItems.map((item) => {
      const offerPrice = Number(item.offerPrice) || Number(item.price) || 0;
      const quantity = Number(item.quantity) || 1;
      const baseAmount = offerPrice * quantity;

      offerSubtotal += baseAmount;

      return {
        productId: Number(item.productId),
        offerPrice,
        quantity,
        baseAmount
      };
    });

    const totalCoupon = Number(discountAmount) || 0;
    let remainingCoupon = totalCoupon;

    const createdOrderIds = [];

    for (let i = 0; i < itemsMeta.length; i++) {
      const meta = itemsMeta[i];

      const itemDelivery = meta.offerPrice > 2500 ? 0 : 49;

      let itemCoupon = 0;
      if (totalCoupon > 0 && offerSubtotal > 0) {
        if (i === itemsMeta.length - 1) {
          itemCoupon = remainingCoupon;
        } else {
          const ratio = meta.baseAmount / offerSubtotal;
          itemCoupon = Number((totalCoupon * ratio).toFixed(2));
          remainingCoupon = Number((remainingCoupon - itemCoupon).toFixed(2));
        }
      }

      let itemFinalAmount = meta.baseAmount + itemDelivery - itemCoupon;
      if (itemFinalAmount < 0) itemFinalAmount = 0;

      // INSERT ORDER
      const orderRes = await client.query(
        `
        INSERT INTO orders 
        (user_id,total_amount,payment_method,shipping_address,
         shipping_id,coupon_code,coupon_discount)
        VALUES ($1,$2,$3,$4,$5,$6,$7)
        RETURNING order_id
        `,
        [
          userId,
          itemFinalAmount,
          paymentMethod,
          shippingAddress,
          shippingId || null,
          couponCode || null,
          itemCoupon
        ]
      );

      const orderId = orderRes.rows[0].order_id;
      createdOrderIds.push(orderId);

      // INSERT ORDER ITEM
      await client.query(
        `
        INSERT INTO order_items
        (order_id,product_id,quantity,price,
         delivery_charge,item_coupon_discount,coupon_discount,
         coupon_share,final_amount)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
        `,
        [
          orderId,
          meta.productId,
          meta.quantity,
          meta.offerPrice,
          itemDelivery,
          itemCoupon,
          itemCoupon,
          itemCoupon,
          itemFinalAmount
        ]
      );

      // REDUCE STOCK
      await client.query(
        `
        UPDATE products
        SET stock = stock - $1
        WHERE product_id = $2
        `,
        [meta.quantity, meta.productId]
      );
    }

    await client.query("COMMIT");

    res.json({
      success: true,
      orderIds: createdOrderIds,
      message: "Orders created successfully"
    });

  } catch (err) {
    await client.query("ROLLBACK");
    console.error("❌ Order error:", err);
    res.status(500).json({ success: false, message: err.message });
  } finally {
    client.release();
  }
});


// ===================================================================
// 2️⃣ USER: Get Orders (Grouped)
// ===================================================================
router.get("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const { rows } = await pool.query(
      `
      SELECT
        o.order_id, o.user_id, o.order_status, o.total_amount,
        o.payment_method, o.shipping_address, o.created_at,
        o.coupon_code, o.coupon_discount,

        oi.order_item_id,
        oi.product_id,
        oi.quantity,
        oi.price,
        oi.final_amount,
        oi.delivery_charge,
        oi.coupon_share,
        oi.item_coupon_discount,
        COALESCE(oi.order_item_status,'Pending') AS item_status,
        COALESCE(oi.item_tracking_url,'') AS item_tracking_url,

        p.name,
        (
          SELECT STRING_AGG(pi.image_url, ',')
          FROM product_images pi 
          WHERE pi.product_id = p.product_id
        ) AS image_urls

      FROM orders o
      JOIN order_items oi ON o.order_id = oi.order_id
      LEFT JOIN products p ON p.product_id = oi.product_id
      WHERE o.user_id = $1
      ORDER BY o.created_at DESC
      `,
      [userId]
    );

    const grouped = {};

    rows.forEach(r => {
      if (!grouped[r.order_id]) {
        grouped[r.order_id] = {
          orderId: r.order_id,
          userId: r.user_id,
          totalAmount: r.total_amount,
          orderStatus: r.order_status,
          paymentMethod: r.payment_method,
          shippingAddress: r.shipping_address,
          createdAt: r.created_at,
          couponCode: r.coupon_code,
          couponDiscount: r.coupon_discount,
          items: []
        };
      }

      grouped[r.order_id].items.push({
        orderItemId: r.order_item_id,
        productId: r.product_id,
        name: r.name,
        quantity: r.quantity,
        price: r.price,
        finalAmount: r.final_amount,
        deliveryCharge: r.delivery_charge,
        couponShare: r.coupon_share,
        itemCouponDiscount: r.item_coupon_discount,
        itemStatus: r.item_status,
        itemTrackingUrl: r.item_tracking_url,
        imageUrls: r.image_urls
          ? r.image_urls.split(",").map(u => u.trim())
          : ["https://via.placeholder.com/300"]
      });
    });

    res.json({ success: true, data: Object.values(grouped) });

  } catch (err) {
    console.error("❌ Error fetching user orders:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
});


// ===================================================================
// 3️⃣ USER: Single Order
// ===================================================================
router.get("/user/order/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;

    const orderRes = await pool.query(
      `SELECT * FROM orders WHERE order_id = $1`,
      [orderId]
    );

    if (orderRes.rows.length === 0)
      return res.status(404).json({ success: false, message: "Order not found" });

    const order = orderRes.rows[0];

    const { rows: items } = await pool.query(
      `
      SELECT 
        oi.order_item_id,
        oi.product_id,
        oi.quantity,
        oi.price,
        oi.final_amount,
        oi.delivery_charge,
        oi.coupon_share,
        oi.item_coupon_discount,
        COALESCE(oi.order_item_status,'Pending') AS item_status,
        COALESCE(oi.item_tracking_url,'') AS item_tracking_url,
        p.name,
        (
          SELECT STRING_AGG(pi.image_url, ',')
          FROM product_images pi WHERE pi.product_id = p.product_id
        ) AS image_urls
      FROM order_items oi
      LEFT JOIN products p ON p.product_id = oi.product_id
      WHERE oi.order_id = $1
      `,
      [orderId]
    );

    order.items = items.map(i => ({
      ...i,
      image_urls: i.image_urls
        ? i.image_urls.split(",").map(u => u.trim())
        : ["https://via.placeholder.com/300"]
    }));

    res.json({ success: true, data: order });

  } catch (err) {
    console.error("❌ Error fetching single order:", err);
    res.status(500).json({ success: false, message: "Failed to fetch order" });
  }
});


// ===================================================================
// 4️⃣ ADMIN: All Orders FLAT
// ===================================================================
router.get("/", async (_, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT 
        o.order_id, o.user_id,
        o.total_amount, o.payment_method,
        o.shipping_address, o.order_status,
        o.created_at, o.coupon_code, o.coupon_discount,

        oi.order_item_id,
        oi.product_id,
        oi.quantity,
        oi.price,
        oi.final_amount,
        oi.delivery_charge,
        oi.coupon_share,
        oi.item_coupon_discount,
        oi.order_item_status,
        oi.item_tracking_url,

        p.name AS product_name,

        (
          SELECT STRING_AGG(pi.image_url, ',')
          FROM product_images pi WHERE pi.product_id = p.product_id
        ) AS image_urls

      FROM orders o
      JOIN order_items oi ON o.order_id = oi.order_id
      LEFT JOIN products p ON p.product_id = oi.product_id
      ORDER BY o.created_at DESC
    `);

    res.json({ success: true, data: rows });

  } catch (err) {
    console.error("❌ Admin orders error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});


// ===================================================================
// 5️⃣ ADMIN: Single Order
// ===================================================================
router.get("/admin/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;

    const orderRes = await pool.query(
      `SELECT * FROM orders WHERE order_id = $1`,
      [orderId]
    );

    if (!orderRes.rows.length)
      return res.status(404).json({ success: false, message: "Order not found" });

    const order = orderRes.rows[0];

    const { rows } = await pool.query(
      `
      SELECT 
        oi.*, 
        p.name AS product_name,
        (
          SELECT STRING_AGG(pi.image_url, ',')
          FROM product_images pi WHERE pi.product_id = p.product_id
        ) AS image_urls
      FROM order_items oi
      LEFT JOIN products p ON p.product_id = oi.product_id
      WHERE oi.order_id = $1
      `,
      [orderId]
    );

    order.items = rows.map(i => ({
      ...i,
      image_urls: i.image_urls
        ? i.image_urls.split(",").map(u => u.trim())
        : []
    }));

    res.json({ success: true, data: order });

  } catch (err) {
    console.error("❌ Admin order error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch order" });
  }
});


// ===================================================================
// 6️⃣ ADMIN: Update Item Status / Tracking
// ===================================================================
router.put("/item/:orderItemId/update", async (req, res) => {
  try {
    const { orderItemId } = req.params;
    const { status, trackingUrl } = req.body;

    const { rowCount, rows } = await pool.query(
      `
      UPDATE order_items
      SET 
        order_item_status = COALESCE($1, order_item_status),
        item_tracking_url = COALESCE($2, item_tracking_url)
      WHERE order_item_id = $3
      RETURNING *
      `,
      [status || null, trackingUrl || null, orderItemId]
    );

    if (!rowCount)
      return res.status(404).json({ success: false, message: "Order item not found" });

    res.json({ success: true, message: "Item updated", updated: rows[0] });

  } catch (err) {
    console.error("❌ Update item error:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});


// ===================================================================
// 7️⃣ USER: Cancel Order
// ===================================================================
router.put("/:orderId/cancel", async (req, res) => {
  const client = await pool.connect();

  try {
    const { orderId } = req.params;

    const order = await client.query(
      `SELECT order_status FROM orders WHERE order_id = $1`,
      [orderId]
    );

    if (!order.rows.length)
      return res.status(404).json({ success: false, message: "Order not found" });

    const status = order.rows[0].order_status;

    if (["Delivered", "Completed", "Cancelled"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel ${status} order`
      });
    }

    await client.query("BEGIN");

    await client.query(
      `UPDATE orders SET order_status = 'Cancelled' WHERE order_id = $1`,
      [orderId]
    );

    await client.query(
      `UPDATE order_items SET order_item_status = 'Cancelled' WHERE order_id = $1`,
      [orderId]
    );

    const { rows: items } = await client.query(
      `SELECT product_id, quantity FROM order_items WHERE order_id = $1`,
      [orderId]
    );

    for (const item of items) {
      await client.query(
        `
        UPDATE products
        SET stock = stock + $1
        WHERE product_id = $2
        `,
        [item.quantity, item.product_id]
      );
    }

    await client.query("COMMIT");

    res.json({ success: true, message: `Order #${orderId} cancelled successfully` });

  } catch (err) {
    await client.query("ROLLBACK");
    console.error("❌ Cancel error:", err);
    res.status(500).json({ success: false, message: "Failed to cancel order" });
  } finally {
    client.release();
  }
});

module.exports = router;



// const express = require("express");
// const router = express.Router();
// const morgan = require("morgan");
// const { sql, poolPromise } = require("../models/db");

// // ===============================
// // 🌐 Middleware & Logging
// // ===============================
// router.use(morgan("dev"));
// router.use((req, res, next) => {
//   console.log("➡️", req.method, req.originalUrl);
//   next();
// });

// // ===================================================
// // 🟢 1️⃣ CREATE ORDERS (ONE ORDER PER ITEM)
// // ===================================================
// router.post("/create", async (req, res) => {
//   const {
//     userId,
//     paymentMethod,
//     cartItems,
//     shippingAddress,
//     shippingId,
//     couponCode,
//     discountAmount = 0,   // total coupon discount from Flutter
//   } = req.body;

//   if (!userId || !paymentMethod || !Array.isArray(cartItems)) {
//     return res
//       .status(400)
//       .json({ success: false, message: "Missing required fields" });
//   }

//   try {
//     const pool = await poolPromise;

//     // ----------------------------------
//     // 1️⃣ PREPARE ITEMS META + SUBTOTAL
//     // ----------------------------------
//     let offerSubtotal = 0;
//     const itemsMeta = cartItems.map((item) => {
//       const offerPrice = Number(item.offerPrice) || Number(item.price) || 0;
//       const quantity = Number(item.quantity) || 1;
//       const baseAmount = offerPrice * quantity; // price * qty

//       offerSubtotal += baseAmount;

//       return {
//         productId: Number(item.productId),
//         offerPrice,
//         quantity,
//         baseAmount,
//       };
//     });

//     const totalCoupon = Number(discountAmount) || 0;
//     let remainingCoupon = totalCoupon;

//     const createdOrderIds = [];

//     // ----------------------------------
//     // 2️⃣ LOOP EACH ITEM → CREATE ORDER
//     // ----------------------------------
//     for (let i = 0; i < itemsMeta.length; i++) {
//       const meta = itemsMeta[i];

//       // 🔹 Delivery per item:
//       //    If this item's offerPrice > 2500 → free delivery
//       //    else → 49 for that order
//       const itemDelivery = meta.offerPrice > 2500 ? 0 : 49;

//       // 🔹 Split coupon discount proportionally per item
//       let itemCoupon = 0;
//       if (totalCoupon > 0 && offerSubtotal > 0) {
//         if (i === itemsMeta.length - 1) {
//           // last item gets whatever is left (to avoid rounding issues)
//           itemCoupon = remainingCoupon;
//         } else {
//           const ratio = meta.baseAmount / offerSubtotal;
//           itemCoupon = Number((totalCoupon * ratio).toFixed(2));
//           remainingCoupon = Number(
//             (remainingCoupon - itemCoupon).toFixed(2)
//           );
//         }
//       }

//       // 🔹 Final total for this item/order
//       let itemFinalAmount = meta.baseAmount + itemDelivery - itemCoupon;
//       if (itemFinalAmount < 0) itemFinalAmount = 0;

//       // ----------------------------------
//       // 2.1 INSERT INTO Orders (ONE ROW)
//       // ----------------------------------
//       const orderRes = await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("totalAmount", sql.Decimal(10, 2), itemFinalAmount)
//         .input("paymentMethod", sql.NVarChar, paymentMethod)
//         .input("shippingAddress", sql.NVarChar, shippingAddress)
//         .input("shippingId", sql.Int, shippingId)
//         .input("couponCode", sql.NVarChar, couponCode || null)
//         .input("couponDiscount", sql.Decimal(10, 2), itemCoupon)
//         .query(`
//           INSERT INTO Orders (
//             userId, totalAmount, paymentMethod, shippingAddress,
//             shippingId, couponCode, couponDiscount
//           )
//           OUTPUT INSERTED.orderId
//           VALUES (
//             @userId, @totalAmount, @paymentMethod, @shippingAddress,
//             @shippingId, @couponCode, @couponDiscount
//           )
//         `);

//       const orderId = orderRes.recordset[0].orderId;
//       createdOrderIds.push(orderId);

//       // ----------------------------------
//       // 2.2 INSERT INTO OrderItems (ONE ROW)
//       // ----------------------------------
//       await pool.request()
//         .input("orderId", sql.Int, orderId)
//         .input("productId", sql.Int, meta.productId)
//         .input("quantity", sql.Int, meta.quantity)
//         .input("price", sql.Decimal(10, 2), meta.offerPrice)
//         .input("deliveryCharge", sql.Decimal(10, 2), itemDelivery)
//         .input("itemCouponDiscount", sql.Decimal(10, 2), itemCoupon)
//         .input("couponDiscount", sql.Decimal(10, 2), itemCoupon)
//         .input("couponShare", sql.Decimal(10, 2), itemCoupon)
//         .input("finalAmount", sql.Decimal(10, 2), itemFinalAmount)
//         .query(`
//           INSERT INTO OrderItems (
//             orderId, productId, quantity, price,
//             deliveryCharge, itemCouponDiscount, couponDiscount, couponShare,
//             finalAmount
//           )
//           VALUES (
//             @orderId, @productId, @quantity, @price,
//             @deliveryCharge, @itemCouponDiscount, @couponDiscount, @couponShare,
//             @finalAmount
//           )
//         `);

//       // ----------------------------------
//       // 2.3 REDUCE STOCK
//       // ----------------------------------
//       await pool.request()
//         .input("productId", sql.Int, meta.productId)
//         .input("quantity", sql.Int, meta.quantity)
//         .query(`
//           UPDATE Products
//           SET Stock = Stock - @quantity
//           WHERE ProductID = @productId
//         `);
//     }

//     return res.json({
//       success: true,
//       orderIds: createdOrderIds, // 🔹 IMPORTANT: ARRAY (one order per item)
//       message: "Orders created successfully (one order per item)",
//     });
//   } catch (err) {
//     console.error("❌ Order error:", err);
//     return res.status(500).json({ success: false, message: err.message });
//   }
// });

// // ===================================================
// // 🟡 2️⃣ USER: Get All Orders (group with items)
// // ===================================================
// router.get("/user/:userId", async (req, res) => {
//   const { userId } = req.params;
//   try {
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query(`
//         SELECT 
//           o.orderId, o.userId, o.orderStatus, o.totalAmount,
//           o.paymentMethod, o.shippingAddress, o.createdAt,
//           o.couponCode, o.couponDiscount,

//           oi.orderItemId,
//           oi.productId,
//           oi.quantity,
//           oi.price AS itemPrice,
//           oi.finalAmount,
//           oi.deliveryCharge,
//           oi.couponShare,
//           oi.itemCouponDiscount,
//           ISNULL(oi.orderItemStatus, 'Pending') AS itemStatus,
//           ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl,

//           p.ProductID AS id,
//           p.Name AS name,
//           p.Description AS description,
//           p.Price AS price,
//           p.OfferPrice AS offerPrice,

//           (
//             SELECT STRING_AGG(pi.ImageURL, ',')
//             FROM ProductImages pi WHERE pi.ProductID = p.ProductID
//           ) AS imageUrls

//         FROM Orders o
//         INNER JOIN OrderItems oi ON o.orderId = oi.orderId
//         LEFT JOIN Products p ON CAST(oi.productId AS INT) = p.ProductID
//         WHERE o.userId = @userId
//         ORDER BY o.createdAt DESC
//       `);

//     const grouped = {};

//     result.recordset.forEach((r) => {
//       if (!grouped[r.orderId]) {
//         grouped[r.orderId] = {
//           orderId: r.orderId,
//           userId: r.userId,
//           totalAmount: r.totalAmount,
//           orderStatus: r.orderStatus,
//           paymentMethod: r.paymentMethod,
//           shippingAddress: r.shippingAddress,
//           createdAt: r.createdAt,
//           couponCode: r.couponCode,
//           couponDiscount: r.couponDiscount,
//           items: [],
//         };
//       }

//       grouped[r.orderId].items.push({
//         orderItemId: r.orderItemId,
//         productId: r.id || r.productId,
//         name: r.name,
//         description: r.description,
//         price: r.price,
//         offerPrice: r.offerPrice,
//         quantity: r.quantity,
//         finalAmount: r.finalAmount,
//         deliveryCharge: r.deliveryCharge,
//         couponShare: r.couponShare,
//         itemCouponDiscount: r.itemCouponDiscount,
//         itemStatus: r.itemStatus,
//         itemTrackingUrl: r.itemTrackingUrl,
//         imageUrls: r.imageUrls
//           ? r.imageUrls.split(",").map((u) => u.trim())
//           : ["https://via.placeholder.com/300"],
//       });
//     });

//     res.json({ success: true, data: Object.values(grouped) });
//   } catch (error) {
//     console.error("❌ Error fetching user orders:", error);
//     res.status(500).json({ message: "Internal Server Error" });
//   }
// });

// // ===================================================
// // 🟢 3️⃣ USER: Get Single Order Detail
// // ===================================================
// router.get("/user/order/:orderId", async (req, res) => {
//   try {
//     const pool = await poolPromise;
//     const { orderId } = req.params;

//     const orderRes = await pool.request()
//       .input("orderId", sql.Int, orderId)
//       .query(`SELECT * FROM Orders WHERE orderId = @orderId`);

//     if (orderRes.recordset.length === 0) {
//       return res
//         .status(404)
//         .json({ success: false, message: "Order not found" });
//     }

//     const order = orderRes.recordset[0];

//     const itemsRes = await pool.request()
//       .input("orderId", sql.Int, orderId)
//       .query(`
//         SELECT 
//           oi.orderItemId,
//           oi.productId,
//           oi.quantity,
//           oi.price,
//           oi.finalAmount,
//           oi.deliveryCharge,
//           oi.couponShare,
//           oi.itemCouponDiscount,
//           ISNULL(oi.orderItemStatus, 'Pending') AS itemStatus,
//           ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl,
//           p.Name AS name,
//           (
//             SELECT STRING_AGG(pi.ImageURL, ',')
//             FROM ProductImages pi WHERE pi.ProductID = p.ProductID
//           ) AS imageUrls
//         FROM OrderItems oi
//         LEFT JOIN Products p ON CAST(oi.productId AS INT) = p.ProductID
//         WHERE oi.orderId = @orderId
//       `);

//     order.items = itemsRes.recordset.map((i) => ({
//       ...i,
//       imageUrls: i.imageUrls
//         ? i.imageUrls.split(",").map((u) => u.trim())
//         : ["https://via.placeholder.com/300"],
//     }));

//     res.json({ success: true, data: order });
//   } catch (err) {
//     console.error("❌ Error fetching single order:", err);
//     res
//       .status(500)
//       .json({ success: false, message: "Failed to fetch order" });
//   }
// });

// // ===================================================
// // 🔵 4️⃣ ADMIN: Get All Orders (Flattened)
// // ===================================================
// router.get("/", async (req, res) => {
//   try {
//     const pool = await poolPromise;

//     const result = await pool.request().query(`
//       SELECT 
//         o.orderId, o.userId, u.Name AS userName, u.Email AS userEmail,
//         o.totalAmount, o.paymentMethod, o.shippingAddress, o.orderStatus, 
//         o.createdAt, o.couponCode, o.couponDiscount,

//         oi.orderItemId,
//         oi.productId,
//         oi.quantity,
//         oi.price AS itemPrice,
//         oi.finalAmount,
//         oi.deliveryCharge,
//         oi.couponShare,
//         oi.itemCouponDiscount,
//         oi.orderItemStatus,
//         oi.ItemTrackingUrl,

//         p.Name AS productName,
//         (
//           SELECT STRING_AGG(pi.ImageURL, ',')
//           FROM ProductImages pi WHERE pi.ProductID = p.ProductID
//         ) AS imageUrls

//       FROM Orders o
//       INNER JOIN OrderItems oi ON o.orderId = oi.orderId
//       LEFT JOIN Products p ON oi.productId = p.ProductID
//       LEFT JOIN Users u ON o.userId = u.UserID
//       ORDER BY o.createdAt DESC
//     `);

//     res.json({ success: true, data: result.recordset });
//   } catch (error) {
//     console.error("❌ Error fetching all admin orders:", error);
//     res
//       .status(500)
//       .json({ success: false, message: "Server error" });
//   }
// });

// // ===================================================
// // 🟡 5️⃣ ADMIN: Get Single Order
// // ===================================================
// router.get("/admin/:orderId", async (req, res) => {
//   const { orderId } = req.params;

//   try {
//     const pool = await poolPromise;

//     const orderRes = await pool.request()
//       .input("orderId", sql.Int, orderId)
//       .query("SELECT * FROM Orders WHERE orderId = @orderId");

//     if (orderRes.recordset.length === 0)
//       return res
//         .status(404)
//         .json({ success: false, message: "Order not found" });

//     const order = orderRes.recordset[0];

//     const itemRes = await pool.request()
//       .input("orderId", sql.Int, orderId)
//       .query(`
//         SELECT 
//           oi.orderItemId,
//           oi.productId,
//           oi.quantity,
//           oi.price,
//           oi.finalAmount,
//           oi.deliveryCharge,
//           oi.couponShare,
//           oi.itemCouponDiscount,
//           oi.orderItemStatus,
//           oi.ItemTrackingUrl,
//           p.Name AS productName,
//           (
//             SELECT STRING_AGG(pi.ImageURL, ',')
//             FROM ProductImages pi WHERE pi.ProductID = p.ProductID
//           ) AS imageUrls
//         FROM OrderItems oi
//         LEFT JOIN Products p ON CAST(oi.productId AS INT) = p.ProductID
//         WHERE oi.orderId = @orderId
//       `);

//     order.items = itemRes.recordset.map((i) => ({
//       ...i,
//       imageUrls: i.imageUrls
//         ? i.imageUrls.split(",").map((u) => u.trim())
//         : ["https://via.placeholder.com/300"],
//     }));

//     res.json({ success: true, data: order });
//   } catch (err) {
//     console.error("❌ Error fetching admin order:", err);
//     res
//       .status(500)
//       .json({ success: false, message: "Failed to fetch order" });
//   }
// });

// // ===================================================
// // 🟠 6️⃣ ADMIN: Update Item Status / Tracking URL
// // ===================================================
// router.put("/item/:orderItemId/update", async (req, res) => {
//   const { orderItemId } = req.params;
//   const { status, trackingUrl } = req.body;

//   if (!status && !trackingUrl)
//     return res.status(400).json({
//       success: false,
//       message: "Status or trackingUrl required",
//     });

//   try {
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("orderItemId", sql.Int, orderItemId)
//       .input("orderItemStatus", sql.NVarChar, status || null)
//       .input("ItemTrackingUrl", sql.NVarChar, trackingUrl || null)
//       .query(`
//         UPDATE OrderItems
//         SET 
//           orderItemStatus = COALESCE(@orderItemStatus, orderItemStatus),
//           ItemTrackingUrl = COALESCE(@ItemTrackingUrl, ItemTrackingUrl)
//         WHERE orderItemId = @orderItemId;

//         SELECT * FROM OrderItems WHERE orderItemId = @orderItemId;
//       `);

//     if (result.recordset.length === 0)
//       return res
//         .status(404)
//         .json({ success: false, message: "Order item not found" });

//     res.json({
//       success: true,
//       message: "Item updated",
//       updated: result.recordset[0],
//     });
//   } catch (error) {
//     console.error("❌ Error updating item:", error);
//     res
//       .status(500)
//       .json({ success: false, message: "Server error" });
//   }
// });

// // ===================================================
// // 🔴 7️⃣ USER: Cancel Order (ONE orderId = ONE item)
// // ===================================================
// router.put("/:orderId/cancel", async (req, res) => {
//   const { orderId } = req.params;

//   try {
//     const pool = await poolPromise;

//     const orderRes = await pool.request()
//       .input("orderId", sql.Int, orderId)
//       .query("SELECT orderStatus FROM Orders WHERE orderId = @orderId");

//     if (orderRes.recordset.length === 0)
//       return res
//         .status(404)
//         .json({ success: false, message: "Order not found" });

//     const currentStatus = orderRes.recordset[0].orderStatus;

//     if (["Delivered", "Completed", "Cancelled"].includes(currentStatus)) {
//       return res.status(400).json({
//         success: false,
//         message: `Cannot cancel ${currentStatus} order`,
//       });
//     }

//     // cancel order + its item
//     await pool.request()
//       .input("orderId", sql.Int, orderId)
//       .query(`
//         UPDATE Orders SET orderStatus = 'Cancelled' WHERE orderId = @orderId;
//         UPDATE OrderItems SET orderItemStatus = 'Cancelled' WHERE orderId = @orderId;
//       `);

//     // restore stock for this order
//     const items = await pool.request()
//       .input("orderId", sql.Int, orderId)
//       .query(
//         "SELECT productId, quantity FROM OrderItems WHERE orderId = @orderId"
//       );

//     for (const item of items.recordset) {
//       await pool.request()
//         .input("productId", sql.Int, item.productId)
//         .input("quantity", sql.Int, item.quantity)
//         .query(`
//           UPDATE Products
//           SET Stock = Stock + @quantity
//           WHERE ProductID = @productId;
//         `);
//     }

//     res.json({
//       success: true,
//       message: `Order #${orderId} cancelled successfully`,
//     });
//   } catch (err) {
//     console.error("❌ Error cancelling order:", err);
//     res
//       .status(500)
//       .json({ success: false, message: "Failed to cancel order" });
//   }
// });

// module.exports = router;
