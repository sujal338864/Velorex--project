const express = require("express");
const router = express.Router();
const pool = require("../models/db");


// ===================================================================
// 1️⃣ Get All Orders For User (WITH ITEMS)
// ===================================================================
router.get("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    // Fetch orders
    const { rows: orders } = await pool.query(
      `
      SELECT 
        o.order_id,
        o.user_id,
        o.total_amount,
        o.order_status,
        o.payment_method,
        o.shipping_address,
        o.tracking_url,
        TO_CHAR(o.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at
      FROM orders o
      WHERE o.user_id = $1
      ORDER BY o.created_at DESC
      `,
      [userId]
    );

    if (orders.length === 0) return res.json([]);

    // Fetch all items for ALL orders in one query (no N+1)
    const orderIds = orders.map(o => o.order_id);

    const { rows: items } = await pool.query(
      `
      SELECT 
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        p.name,
        oi.quantity,
        oi.price,
        oi.final_amount,
        oi.rating,
        COALESCE(oi.item_tracking_url, 'Not Available') AS item_tracking_url
      FROM order_items oi
      JOIN products p ON p.product_id = oi.product_id
      WHERE oi.order_id = ANY($1)
      `,
      [orderIds]
    );

    // Attach items to orders
    const orderMap = {};
    orders.forEach(o => orderMap[o.order_id] = { ...o, items: [] });
    items.forEach(i => orderMap[i.order_id].items.push(i));

    res.json(Object.values(orderMap));

  } catch (err) {
    console.error("❌ Error fetching orders:", err);
    res.status(500).json({ error: "Failed to fetch orders" });
  }
});


// ===================================================================
// 2️⃣ Single Order Details (WITH ITEMS)
// ===================================================================
router.get("/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;

    const { rows } = await pool.query(
      `SELECT * FROM orders WHERE order_id = $1`,
      [orderId]
    );

    if (rows.length === 0)
      return res.status(404).json({ error: "Order not found" });

    const order = rows[0];

    const { rows: items } = await pool.query(
      `
      SELECT 
        oi.order_item_id,
        p.name,
        oi.quantity,
        oi.price,
        oi.final_amount,
        oi.rating,
        COALESCE(oi.item_tracking_url, 'Not Available') AS item_tracking_url
      FROM order_items oi
      JOIN products p ON p.product_id = oi.product_id
      WHERE oi.order_id = $1
      `,
      [orderId]
    );

    order.items = items;

    res.json(order);

  } catch (err) {
    console.error("❌ Error fetching order details:", err);
    res.status(500).json({ error: "Failed to fetch order details" });
  }
});


// ===================================================================
// 3️⃣ Update Tracking (ADMIN)
// ===================================================================
router.put("/update-tracking/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    const { trackingLocation, expectedDelivery, status } = req.body;

    await pool.query(
      `
      UPDATE orders
      SET tracking_url = $1,
          order_status = $2
      WHERE order_id = $3
      `,
      [trackingLocation || null, status || null, orderId]
    );

    res.json({ success: true, message: "Tracking updated" });

  } catch (err) {
    console.error("❌ Error updating tracking:", err);
    res.status(500).json({ error: "Failed to update tracking" });
  }
});


// ===================================================================
// 4️⃣ Rate Product From Order
// ===================================================================
router.put("/rate-item/:orderItemId", async (req, res) => {
  try {
    const { orderItemId } = req.params;
    const { rating } = req.body;

    await pool.query(
      `
      UPDATE order_items
      SET rating = $1
      WHERE order_item_id = $2
      `,
      [rating, orderItemId]
    );

    res.json({ success: true, message: "Rating submitted" });

  } catch (err) {
    console.error("❌ Error updating rating:", err);
    res.status(500).json({ error: "Failed to update rating" });
  }
});

module.exports = router;


// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// // ===================================================================
// // 1️⃣ Get all orders for a user (with items + finalAmount)
// // ===================================================================
// router.get("/user/:userId", async (req, res) => {
//   try {
//     const pool = await poolPromise;

//     // Fetch Order List
//     const result = await pool.request()
//       .input("userId", sql.Int, req.params.userId)
//       .query(`
//         SELECT 
//           orderId, userId, totalAmount, status, paymentMethod,
//           shippingAddress, shippingCity, shippingState, shippingZip,
//           shippingCountry, trackingLocation, expectedDelivery, orderDate
//         FROM Orders
//         WHERE userId = @userId
//         ORDER BY orderDate DESC
//       `);

//     const orders = result.recordset;

//     // Fetch Items for Each Order
//     for (const order of orders) {
//       const items = await pool.request()
//         .input("orderId", sql.Int, order.orderId)
//         .query(`
//           SELECT 
//             oi.orderItemId,
//             oi.productId,
//             p.name,
//             p.image,
//             oi.quantity,
//             oi.price,             -- offer price
//             oi.finalAmount,       -- ⭐ discounted final amount
//             oi.rating,
//             ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl
//           FROM OrderItems oi
//           JOIN Products p ON oi.productId = p.id
//           WHERE oi.orderId = @orderId
//         `);

//       // Add fallback for tracking URL
//       order.items = items.recordset.map(item => ({
//         ...item,
//         itemTrackingUrl: item.itemTrackingUrl.trim() !== "" 
//           ? item.itemTrackingUrl 
//           : "Not Available"
//       }));
//     }

//     res.json(orders);

//   } catch (err) {
//     console.error("❌ Error fetching orders:", err);
//     res.status(500).json({ error: "Failed to fetch orders" });
//   }
// });


// // ===================================================================
// // 2️⃣ Get a single order detail (with items + finalAmount)
// // ===================================================================
// router.get("/:orderId", async (req, res) => {
//   try {
//     const pool = await poolPromise;

//     // Fetch Master Order Info
//     const result = await pool.request()
//       .input("orderId", sql.Int, req.params.orderId)
//       .query(`SELECT * FROM Orders WHERE orderId = @orderId`);

//     if (result.recordset.length === 0)
//       return res.status(404).json({ error: "Order not found" });

//     const order = result.recordset[0];

//     // Fetch Items for the Order
//     const items = await pool.request()
//       .input("orderId", sql.Int, req.params.orderId)
//       .query(`
//         SELECT 
//           oi.orderItemId,
//           p.name,
//           p.image,
//           oi.quantity,
//           oi.price,              -- offer price
//           oi.finalAmount,        -- ⭐ final discounted price
//           oi.rating,
//           ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl
//         FROM OrderItems oi
//         JOIN Products p ON oi.productId = p.id
//         WHERE oi.orderId = @orderId
//       `);

//     order.items = items.recordset.map(item => ({
//       ...item,
//       itemTrackingUrl: item.itemTrackingUrl.trim() !== "" 
//         ? item.itemTrackingUrl 
//         : "Not Available"
//     }));

//     res.json(order);

//   } catch (err) {
//     console.error("❌ Error fetching order details:", err);
//     res.status(500).json({ error: "Failed to fetch order details" });
//   }
// });


// // ===================================================================
// // 3️⃣ Update Order Tracking (Admin)
// // ===================================================================
// router.put("/update-tracking/:orderId", async (req, res) => {
//   const { trackingLocation, expectedDelivery, status } = req.body;
//   try {
//     const pool = await poolPromise;

//     await pool.request()
//       .input("orderId", sql.Int, req.params.orderId)
//       .input("trackingLocation", sql.VarChar, trackingLocation)
//       .input("expectedDelivery", sql.VarChar, expectedDelivery)
//       .input("status", sql.VarChar, status)
//       .query(`
//         UPDATE Orders
//         SET trackingLocation = @trackingLocation,
//             expectedDelivery = @expectedDelivery,
//             status = @status
//         WHERE orderId = @orderId
//       `);

//     res.json({ success: true, message: "Tracking updated" });

//   } catch (err) {
//     console.error("❌ Error updating tracking:", err);
//     res.status(500).json({ error: "Failed to update tracking" });
//   }
// });


// // ===================================================================
// // 4️⃣ Update Product Rating
// // ===================================================================
// router.put("/rate-item/:orderItemId", async (req, res) => {
//   const { rating } = req.body;
//   try {
//     const pool = await poolPromise;

//     await pool.request()
//       .input("orderItemId", sql.Int, req.params.orderItemId)
//       .input("rating", sql.Int, rating)
//       .query(`
//         UPDATE OrderItems 
//         SET rating = @rating 
//         WHERE orderItemId = @orderItemId
//       `);

//     res.json({ success: true, message: "Rating submitted" });

//   } catch (err) {
//     console.error("❌ Error updating rating:", err);
//     res.status(500).json({ error: "Failed to update rating" });
//   }
// });

// module.exports = router;
