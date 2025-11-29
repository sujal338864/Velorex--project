const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");


// ✅ 1️⃣ Get all orders for a user (with tracking URL for each item)
router.get("/user/:userId", async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .input("userId", sql.Int, req.params.userId)
      .query(`
        SELECT 
          o.orderId, 
          o.userId,
          o.totalAmount,
          o.status,
          o.paymentMethod,
          o.shippingAddress,
          o.shippingCity,
          o.shippingState,
          o.shippingZip,
          o.shippingCountry,
          o.trackingLocation,
          o.expectedDelivery,
          o.orderDate
        FROM Orders o
        WHERE o.userId = @userId
        ORDER BY o.orderDate DESC
      `);

    const orders = result.recordset;

    // Fetch order items for each order
    for (const order of orders) {
      const itemResult = await pool.request()
        .input("orderId", sql.Int, order.orderId)
        .query(`
          SELECT 
            oi.orderItemId,
            oi.productId,
            p.name,
            p.image,
            oi.quantity,
            oi.price,
            oi.rating,
            ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl
          FROM OrderItems oi
          JOIN Products p ON oi.productId = p.id
          WHERE oi.orderId = @orderId
        `);

      // include fallback if URL not uploaded yet
      order.items = itemResult.recordset.map(item => ({
        ...item,
        itemTrackingUrl: item.itemTrackingUrl && item.itemTrackingUrl.trim() !== ""
          ? item.itemTrackingUrl
          : "Not Available"
      }));
    }

    res.json(orders);
  } catch (err) {
    console.error("❌ Error fetching orders:", err);
    res.status(500).json({ error: "Failed to fetch orders" });
  }
});


// ✅ 2️⃣ Get a single order detail (with tracking URL for each item)
router.get("/:orderId", async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .input("orderId", sql.Int, req.params.orderId)
      .query(`
        SELECT * FROM Orders WHERE orderId = @orderId
      `);

    if (result.recordset.length === 0)
      return res.status(404).json({ error: "Order not found" });

    const order = result.recordset[0];

    const items = await pool.request()
      .input("orderId", sql.Int, req.params.orderId)
      .query(`
        SELECT 
          oi.orderItemId,
          p.name,
          p.image,
          oi.quantity,
          oi.price,
          oi.rating,
          ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl
        FROM OrderItems oi
        JOIN Products p ON oi.productId = p.id
        WHERE oi.orderId = @orderId
      `);

    // Fallback message for missing tracking URL
    order.items = items.recordset.map(item => ({
      ...item,
      itemTrackingUrl: item.itemTrackingUrl && item.itemTrackingUrl.trim() !== ""
        ? item.itemTrackingUrl
        : "Not Available"
    }));

    res.json(order);
  } catch (err) {
    console.error("❌ Error fetching order details:", err);
    res.status(500).json({ error: "Failed to fetch order details" });
  }
});


// ✅ 3️⃣ Update tracking info (for admin updates only)
router.put("/update-tracking/:orderId", async (req, res) => {
  const { trackingLocation, expectedDelivery, status } = req.body;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input("orderId", sql.Int, req.params.orderId)
      .input("trackingLocation", sql.VarChar, trackingLocation)
      .input("expectedDelivery", sql.VarChar, expectedDelivery)
      .input("status", sql.VarChar, status)
      .query(`
        UPDATE Orders
        SET trackingLocation = @trackingLocation,
            expectedDelivery = @expectedDelivery,
            status = @status
        WHERE orderId = @orderId
      `);
    res.json({ success: true, message: "Tracking updated" });
  } catch (err) {
    console.error("❌ Error updating tracking:", err);
    res.status(500).json({ error: "Failed to update tracking" });
  }
});


// ✅ 4️⃣ Update product rating (from user)
router.put("/rate-item/:orderItemId", async (req, res) => {
  const { rating } = req.body;
  try {
    const pool = await poolPromise;
    await pool.request()
      .input("orderItemId", sql.Int, req.params.orderItemId)
      .input("rating", sql.Int, rating)
      .query(`
        UPDATE OrderItems SET rating = @rating WHERE orderItemId = @orderItemId
      `);
    res.json({ success: true, message: "Rating submitted" });
  } catch (err) {
    console.error("❌ Error updating rating:", err);
    res.status(500).json({ error: "Failed to update rating" });
  }
});

module.exports = router;
