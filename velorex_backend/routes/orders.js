const express = require("express");
const router = express.Router();
const morgan = require("morgan");
const { sql, poolPromise } = require("../models/db");

// ===============================
// 🌐 Middleware & Logging
// ===============================
router.use(morgan("dev"));
router.use((req, res, next) => {
  console.log("➡️", req.method, req.originalUrl);
  next();
});

// ===================================================
// 🟢 1️⃣ CREATE ORDERS (ONE ORDER PER ITEM)
// ===================================================
router.post("/create", async (req, res) => {
  const {
    userId,
    paymentMethod,
    cartItems,
    shippingAddress,
    shippingId,
    couponCode,
    discountAmount = 0,   // total coupon discount from Flutter
  } = req.body;

  if (!userId || !paymentMethod || !Array.isArray(cartItems)) {
    return res
      .status(400)
      .json({ success: false, message: "Missing required fields" });
  }

  try {
    const pool = await poolPromise;

    // ----------------------------------
    // 1️⃣ PREPARE ITEMS META + SUBTOTAL
    // ----------------------------------
    let offerSubtotal = 0;
    const itemsMeta = cartItems.map((item) => {
      const offerPrice = Number(item.offerPrice) || Number(item.price) || 0;
      const quantity = Number(item.quantity) || 1;
      const baseAmount = offerPrice * quantity; // price * qty

      offerSubtotal += baseAmount;

      return {
        productId: Number(item.productId),
        offerPrice,
        quantity,
        baseAmount,
      };
    });

    const totalCoupon = Number(discountAmount) || 0;
    let remainingCoupon = totalCoupon;

    const createdOrderIds = [];

    // ----------------------------------
    // 2️⃣ LOOP EACH ITEM → CREATE ORDER
    // ----------------------------------
    for (let i = 0; i < itemsMeta.length; i++) {
      const meta = itemsMeta[i];

      // 🔹 Delivery per item:
      //    If this item's offerPrice > 2500 → free delivery
      //    else → 49 for that order
      const itemDelivery = meta.offerPrice > 2500 ? 0 : 49;

      // 🔹 Split coupon discount proportionally per item
      let itemCoupon = 0;
      if (totalCoupon > 0 && offerSubtotal > 0) {
        if (i === itemsMeta.length - 1) {
          // last item gets whatever is left (to avoid rounding issues)
          itemCoupon = remainingCoupon;
        } else {
          const ratio = meta.baseAmount / offerSubtotal;
          itemCoupon = Number((totalCoupon * ratio).toFixed(2));
          remainingCoupon = Number(
            (remainingCoupon - itemCoupon).toFixed(2)
          );
        }
      }

      // 🔹 Final total for this item/order
      let itemFinalAmount = meta.baseAmount + itemDelivery - itemCoupon;
      if (itemFinalAmount < 0) itemFinalAmount = 0;

      // ----------------------------------
      // 2.1 INSERT INTO Orders (ONE ROW)
      // ----------------------------------
      const orderRes = await pool.request()
        .input("userId", sql.NVarChar, userId)
        .input("totalAmount", sql.Decimal(10, 2), itemFinalAmount)
        .input("paymentMethod", sql.NVarChar, paymentMethod)
        .input("shippingAddress", sql.NVarChar, shippingAddress)
        .input("shippingId", sql.Int, shippingId)
        .input("couponCode", sql.NVarChar, couponCode || null)
        .input("couponDiscount", sql.Decimal(10, 2), itemCoupon)
        .query(`
          INSERT INTO Orders (
            userId, totalAmount, paymentMethod, shippingAddress,
            shippingId, couponCode, couponDiscount
          )
          OUTPUT INSERTED.orderId
          VALUES (
            @userId, @totalAmount, @paymentMethod, @shippingAddress,
            @shippingId, @couponCode, @couponDiscount
          )
        `);

      const orderId = orderRes.recordset[0].orderId;
      createdOrderIds.push(orderId);

      // ----------------------------------
      // 2.2 INSERT INTO OrderItems (ONE ROW)
      // ----------------------------------
      await pool.request()
        .input("orderId", sql.Int, orderId)
        .input("productId", sql.Int, meta.productId)
        .input("quantity", sql.Int, meta.quantity)
        .input("price", sql.Decimal(10, 2), meta.offerPrice)
        .input("deliveryCharge", sql.Decimal(10, 2), itemDelivery)
        .input("itemCouponDiscount", sql.Decimal(10, 2), itemCoupon)
        .input("couponDiscount", sql.Decimal(10, 2), itemCoupon)
        .input("couponShare", sql.Decimal(10, 2), itemCoupon)
        .input("finalAmount", sql.Decimal(10, 2), itemFinalAmount)
        .query(`
          INSERT INTO OrderItems (
            orderId, productId, quantity, price,
            deliveryCharge, itemCouponDiscount, couponDiscount, couponShare,
            finalAmount
          )
          VALUES (
            @orderId, @productId, @quantity, @price,
            @deliveryCharge, @itemCouponDiscount, @couponDiscount, @couponShare,
            @finalAmount
          )
        `);

      // ----------------------------------
      // 2.3 REDUCE STOCK
      // ----------------------------------
      await pool.request()
        .input("productId", sql.Int, meta.productId)
        .input("quantity", sql.Int, meta.quantity)
        .query(`
          UPDATE Products
          SET Stock = Stock - @quantity
          WHERE ProductID = @productId
        `);
    }

    return res.json({
      success: true,
      orderIds: createdOrderIds, // 🔹 IMPORTANT: ARRAY (one order per item)
      message: "Orders created successfully (one order per item)",
    });
  } catch (err) {
    console.error("❌ Order error:", err);
    return res.status(500).json({ success: false, message: err.message });
  }
});

// ===================================================
// 🟡 2️⃣ USER: Get All Orders (group with items)
// ===================================================
router.get("/user/:userId", async (req, res) => {
  const { userId } = req.params;
  try {
    const pool = await poolPromise;

    const result = await pool.request()
      .input("userId", sql.NVarChar, userId)
      .query(`
        SELECT 
          o.orderId, o.userId, o.orderStatus, o.totalAmount,
          o.paymentMethod, o.shippingAddress, o.createdAt,
          o.couponCode, o.couponDiscount,

          oi.orderItemId,
          oi.productId,
          oi.quantity,
          oi.price AS itemPrice,
          oi.finalAmount,
          oi.deliveryCharge,
          oi.couponShare,
          oi.itemCouponDiscount,
          ISNULL(oi.orderItemStatus, 'Pending') AS itemStatus,
          ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl,

          p.ProductID AS id,
          p.Name AS name,
          p.Description AS description,
          p.Price AS price,
          p.OfferPrice AS offerPrice,

          (
            SELECT STRING_AGG(pi.ImageURL, ',')
            FROM ProductImages pi WHERE pi.ProductID = p.ProductID
          ) AS imageUrls

        FROM Orders o
        INNER JOIN OrderItems oi ON o.orderId = oi.orderId
        LEFT JOIN Products p ON CAST(oi.productId AS INT) = p.ProductID
        WHERE o.userId = @userId
        ORDER BY o.createdAt DESC
      `);

    const grouped = {};

    result.recordset.forEach((r) => {
      if (!grouped[r.orderId]) {
        grouped[r.orderId] = {
          orderId: r.orderId,
          userId: r.userId,
          totalAmount: r.totalAmount,
          orderStatus: r.orderStatus,
          paymentMethod: r.paymentMethod,
          shippingAddress: r.shippingAddress,
          createdAt: r.createdAt,
          couponCode: r.couponCode,
          couponDiscount: r.couponDiscount,
          items: [],
        };
      }

      grouped[r.orderId].items.push({
        orderItemId: r.orderItemId,
        productId: r.id || r.productId,
        name: r.name,
        description: r.description,
        price: r.price,
        offerPrice: r.offerPrice,
        quantity: r.quantity,
        finalAmount: r.finalAmount,
        deliveryCharge: r.deliveryCharge,
        couponShare: r.couponShare,
        itemCouponDiscount: r.itemCouponDiscount,
        itemStatus: r.itemStatus,
        itemTrackingUrl: r.itemTrackingUrl,
        imageUrls: r.imageUrls
          ? r.imageUrls.split(",").map((u) => u.trim())
          : ["https://via.placeholder.com/300"],
      });
    });

    res.json({ success: true, data: Object.values(grouped) });
  } catch (error) {
    console.error("❌ Error fetching user orders:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

// ===================================================
// 🟢 3️⃣ USER: Get Single Order Detail
// ===================================================
router.get("/user/order/:orderId", async (req, res) => {
  try {
    const pool = await poolPromise;
    const { orderId } = req.params;

    const orderRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`SELECT * FROM Orders WHERE orderId = @orderId`);

    if (orderRes.recordset.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    const order = orderRes.recordset[0];

    const itemsRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`
        SELECT 
          oi.orderItemId,
          oi.productId,
          oi.quantity,
          oi.price,
          oi.finalAmount,
          oi.deliveryCharge,
          oi.couponShare,
          oi.itemCouponDiscount,
          ISNULL(oi.orderItemStatus, 'Pending') AS itemStatus,
          ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl,
          p.Name AS name,
          (
            SELECT STRING_AGG(pi.ImageURL, ',')
            FROM ProductImages pi WHERE pi.ProductID = p.ProductID
          ) AS imageUrls
        FROM OrderItems oi
        LEFT JOIN Products p ON CAST(oi.productId AS INT) = p.ProductID
        WHERE oi.orderId = @orderId
      `);

    order.items = itemsRes.recordset.map((i) => ({
      ...i,
      imageUrls: i.imageUrls
        ? i.imageUrls.split(",").map((u) => u.trim())
        : ["https://via.placeholder.com/300"],
    }));

    res.json({ success: true, data: order });
  } catch (err) {
    console.error("❌ Error fetching single order:", err);
    res
      .status(500)
      .json({ success: false, message: "Failed to fetch order" });
  }
});

// ===================================================
// 🔵 4️⃣ ADMIN: Get All Orders (Flattened)
// ===================================================
router.get("/", async (req, res) => {
  try {
    const pool = await poolPromise;

    const result = await pool.request().query(`
      SELECT 
        o.orderId, o.userId, u.Name AS userName, u.Email AS userEmail,
        o.totalAmount, o.paymentMethod, o.shippingAddress, o.orderStatus, 
        o.createdAt, o.couponCode, o.couponDiscount,

        oi.orderItemId,
        oi.productId,
        oi.quantity,
        oi.price AS itemPrice,
        oi.finalAmount,
        oi.deliveryCharge,
        oi.couponShare,
        oi.itemCouponDiscount,
        oi.orderItemStatus,
        oi.ItemTrackingUrl,

        p.Name AS productName,
        (
          SELECT STRING_AGG(pi.ImageURL, ',')
          FROM ProductImages pi WHERE pi.ProductID = p.ProductID
        ) AS imageUrls

      FROM Orders o
      INNER JOIN OrderItems oi ON o.orderId = oi.orderId
      LEFT JOIN Products p ON oi.productId = p.ProductID
      LEFT JOIN Users u ON o.userId = u.UserID
      ORDER BY o.createdAt DESC
    `);

    res.json({ success: true, data: result.recordset });
  } catch (error) {
    console.error("❌ Error fetching all admin orders:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error" });
  }
});

// ===================================================
// 🟡 5️⃣ ADMIN: Get Single Order
// ===================================================
router.get("/admin/:orderId", async (req, res) => {
  const { orderId } = req.params;

  try {
    const pool = await poolPromise;

    const orderRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query("SELECT * FROM Orders WHERE orderId = @orderId");

    if (orderRes.recordset.length === 0)
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });

    const order = orderRes.recordset[0];

    const itemRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`
        SELECT 
          oi.orderItemId,
          oi.productId,
          oi.quantity,
          oi.price,
          oi.finalAmount,
          oi.deliveryCharge,
          oi.couponShare,
          oi.itemCouponDiscount,
          oi.orderItemStatus,
          oi.ItemTrackingUrl,
          p.Name AS productName,
          (
            SELECT STRING_AGG(pi.ImageURL, ',')
            FROM ProductImages pi WHERE pi.ProductID = p.ProductID
          ) AS imageUrls
        FROM OrderItems oi
        LEFT JOIN Products p ON CAST(oi.productId AS INT) = p.ProductID
        WHERE oi.orderId = @orderId
      `);

    order.items = itemRes.recordset.map((i) => ({
      ...i,
      imageUrls: i.imageUrls
        ? i.imageUrls.split(",").map((u) => u.trim())
        : ["https://via.placeholder.com/300"],
    }));

    res.json({ success: true, data: order });
  } catch (err) {
    console.error("❌ Error fetching admin order:", err);
    res
      .status(500)
      .json({ success: false, message: "Failed to fetch order" });
  }
});

// ===================================================
// 🟠 6️⃣ ADMIN: Update Item Status / Tracking URL
// ===================================================
router.put("/item/:orderItemId/update", async (req, res) => {
  const { orderItemId } = req.params;
  const { status, trackingUrl } = req.body;

  if (!status && !trackingUrl)
    return res.status(400).json({
      success: false,
      message: "Status or trackingUrl required",
    });

  try {
    const pool = await poolPromise;

    const result = await pool.request()
      .input("orderItemId", sql.Int, orderItemId)
      .input("orderItemStatus", sql.NVarChar, status || null)
      .input("ItemTrackingUrl", sql.NVarChar, trackingUrl || null)
      .query(`
        UPDATE OrderItems
        SET 
          orderItemStatus = COALESCE(@orderItemStatus, orderItemStatus),
          ItemTrackingUrl = COALESCE(@ItemTrackingUrl, ItemTrackingUrl)
        WHERE orderItemId = @orderItemId;

        SELECT * FROM OrderItems WHERE orderItemId = @orderItemId;
      `);

    if (result.recordset.length === 0)
      return res
        .status(404)
        .json({ success: false, message: "Order item not found" });

    res.json({
      success: true,
      message: "Item updated",
      updated: result.recordset[0],
    });
  } catch (error) {
    console.error("❌ Error updating item:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error" });
  }
});

// ===================================================
// 🔴 7️⃣ USER: Cancel Order (ONE orderId = ONE item)
// ===================================================
router.put("/:orderId/cancel", async (req, res) => {
  const { orderId } = req.params;

  try {
    const pool = await poolPromise;

    const orderRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query("SELECT orderStatus FROM Orders WHERE orderId = @orderId");

    if (orderRes.recordset.length === 0)
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });

    const currentStatus = orderRes.recordset[0].orderStatus;

    if (["Delivered", "Completed", "Cancelled"].includes(currentStatus)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel ${currentStatus} order`,
      });
    }

    // cancel order + its item
    await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`
        UPDATE Orders SET orderStatus = 'Cancelled' WHERE orderId = @orderId;
        UPDATE OrderItems SET orderItemStatus = 'Cancelled' WHERE orderId = @orderId;
      `);

    // restore stock for this order
    const items = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(
        "SELECT productId, quantity FROM OrderItems WHERE orderId = @orderId"
      );

    for (const item of items.recordset) {
      await pool.request()
        .input("productId", sql.Int, item.productId)
        .input("quantity", sql.Int, item.quantity)
        .query(`
          UPDATE Products
          SET Stock = Stock + @quantity
          WHERE ProductID = @productId;
        `);
    }

    res.json({
      success: true,
      message: `Order #${orderId} cancelled successfully`,
    });
  } catch (err) {
    console.error("❌ Error cancelling order:", err);
    res
      .status(500)
      .json({ success: false, message: "Failed to cancel order" });
  }
});

module.exports = router;
