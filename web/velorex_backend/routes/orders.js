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
// 🟢 1️⃣ CREATE ORDER — Each cart item = Separate Order
// ===================================================
// ===================================================
// 🟢 1️⃣ CREATE ORDER — Each cart item = Separate Order
// ===================================================
router.post("/create", async (req, res) => {
  const { userId, totalAmount, paymentMethod, cartItems, shippingAddress, couponCode } = req.body;

  if (!userId || !totalAmount || !paymentMethod || !Array.isArray(cartItems)) {
    return res.status(400).json({ success: false, message: "Missing required fields" });
  }

  try {
    const pool = await poolPromise;
    const createdOrders = [];

    for (const item of cartItems) {
      const productId = parseInt(item.productId || item.id);
      if (!productId || isNaN(productId)) continue;

      const itemTotal = parseFloat(item.price) * parseInt(item.quantity);

      const orderResult = await pool.request()
        .input("userId", sql.NVarChar, userId)
        .input("totalAmount", sql.Decimal(10, 2), itemTotal)
        .input("paymentMethod", sql.NVarChar, paymentMethod)
        .input("shippingAddress", sql.NVarChar, shippingAddress || "Not Provided")
        .input("couponCode", sql.NVarChar, couponCode || null)
        .query(`
          INSERT INTO Orders (userId, totalAmount, paymentMethod, shippingAddress, couponCode, orderStatus)
          OUTPUT INSERTED.orderId
          VALUES (@userId, @totalAmount, @paymentMethod, @shippingAddress, @couponCode, 'Pending')
        `);

      const orderId = orderResult.recordset[0].orderId;

      await pool.request()
        .input("orderId", sql.Int, orderId)
        .input("productId", sql.Int, productId)
        .input("quantity", sql.Int, item.quantity)
        .input("price", sql.Decimal(10, 2), item.price)
        .query(`
          INSERT INTO OrderItems (orderId, productId, quantity, price)
          VALUES (@orderId, @productId, @quantity, @price)
        `);

      // 🟣 DECREASE STOCK HERE
      await pool.request()
        .input("productId", sql.Int, productId)
        .input("quantity", sql.Int, item.quantity)
        .query(`
          UPDATE Products
          SET Stock = CASE 
                        WHEN Stock >= @quantity THEN Stock - @quantity
                        ELSE 0
                      END
          WHERE ProductID = @productId;
        `);

      createdOrders.push(orderId);
    }

    res.json({
      success: true,
      message: `✅ ${createdOrders.length} orders created successfully`,
      orderIds: createdOrders
    });
  } catch (err) {
    console.error("❌ Order creation failed:", err);
    res.status(500).json({ success: false, message: err.message });
  }
});



// ===================================================
// 🟡 2️⃣ USER: Get All Orders
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
          oi.orderItemId, oi.productId, oi.quantity, oi.price AS itemPrice,
          ISNULL(oi.orderItemStatus, 'Pending') AS itemStatus,
          ISNULL(oi.ItemTrackingUrl, '') AS itemTrackingUrl,
          p.ProductID AS id, p.Name AS name, p.Description AS description, 
          p.Price AS price, p.OfferPrice AS offerPrice,
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

    const groupedOrders = {};
    for (const row of result.recordset) {
      if (!groupedOrders[row.orderId]) {
        groupedOrders[row.orderId] = {
          orderId: row.orderId,
          userId: row.userId,
          totalAmount: row.totalAmount,
          orderStatus: row.orderStatus,
          paymentMethod: row.paymentMethod,
          shippingAddress: row.shippingAddress,
          createdAt: row.createdAt,
          items: [],
        };
      }

      groupedOrders[row.orderId].items.push({
        orderItemId: row.orderItemId,
        productId: row.id || row.productId,
        name: row.name || "Unknown Product",
        description: row.description || "No description",
        price: row.price,
        offerPrice: row.offerPrice,
        quantity: row.quantity,
        itemStatus: row.itemStatus,
        itemTrackingUrl: row.itemTrackingUrl,
        imageUrls: row.imageUrls
          ? row.imageUrls.split(",").map(url => url.trim())
          : ["https://via.placeholder.com/300?text=No+Image"]
      });
    }

    res.json({ success: true, data: Object.values(groupedOrders) });
  } catch (error) {
    console.error("❌ Fetch user orders error:", error);
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
      .query("SELECT * FROM Orders WHERE orderId = @orderId");

    if (orderRes.recordset.length === 0)
      return res.status(404).json({ success: false, message: "Order not found" });

    const order = orderRes.recordset[0];

    const itemsRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`
        SELECT 
          oi.orderItemId, oi.productId, oi.quantity, oi.price,
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

    order.items = itemsRes.recordset.map(i => ({
      ...i,
      imageUrls: i.imageUrls
        ? i.imageUrls.split(",").map(u => u.trim())
        : ["https://via.placeholder.com/300?text=No+Image"]
    }));

    res.json({ success: true, data: order });
  } catch (err) {
    console.error("❌ Fetch single order error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch order" });
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
        o.totalAmount, o.paymentMethod, o.shippingAddress, o.orderStatus, o.createdAt,
        oi.orderItemId, oi.productId, oi.quantity, oi.price AS itemPrice,
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
    console.error("❌ Admin fetch all orders error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});


// ===================================================
// 🟡 5️⃣ ADMIN: Get Single Order (With Items)
// ===================================================
router.get("/admin/:orderId", async (req, res) => {
  const { orderId } = req.params;
  try {
    const pool = await poolPromise;

    const orderRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`SELECT * FROM Orders WHERE orderId = @orderId`);

    if (orderRes.recordset.length === 0)
      return res.status(404).json({ success: false, message: "Order not found" });

    const order = orderRes.recordset[0];

    const itemRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`
        SELECT 
          oi.orderItemId, oi.productId, oi.quantity, oi.price,
          oi.orderItemStatus, oi.ItemTrackingUrl,
          p.Name AS productName,
          (
            SELECT STRING_AGG(pi.ImageURL, ',')
            FROM ProductImages pi WHERE pi.ProductID = p.ProductID
          ) AS imageUrls
        FROM OrderItems oi
        LEFT JOIN Products p ON CAST(oi.productId AS INT) = p.ProductID
        WHERE oi.orderId = @orderId
      `);

    order.items = itemRes.recordset.map(i => ({
      ...i,
      imageUrls: i.imageUrls
        ? i.imageUrls.split(",").map(u => u.trim())
        : ["https://via.placeholder.com/300?text=No+Image"]
    }));

    res.json({ success: true, data: order });
  } catch (err) {
    console.error("❌ Admin single order error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch order" });
  }
});


// ===================================================
// 🟠 6️⃣ ADMIN: Update Item Status / Tracking
// ===================================================
router.put("/item/:orderItemId/update", async (req, res) => {
  const { orderItemId } = req.params;
  const { status, trackingUrl } = req.body;

  if (!status && !trackingUrl)
    return res.status(400).json({ success: false, message: "Status or trackingUrl required" });

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
      return res.status(404).json({ success: false, message: "Order item not found" });

    res.json({ success: true, message: "✅ Item updated", updated: result.recordset[0] });
  } catch (error) {
    console.error("❌ Update item error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});


// ===================================================
// 🔴 8️⃣ USER: Cancel Order
// ===================================================
router.put("/:orderId/cancel", async (req, res) => {
  const { orderId } = req.params;

  try {
    const pool = await poolPromise;

    const orderRes = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query("SELECT orderStatus FROM Orders WHERE orderId = @orderId");

    if (orderRes.recordset.length === 0) {
      return res.status(404).json({ success: false, message: "Order not found" });
    }

    const currentStatus = orderRes.recordset[0].orderStatus;

    if (["Delivered", "Completed", "Cancelled"].includes(currentStatus)) {
      return res.status(400).json({ success: false, message: `Cannot cancel ${currentStatus} order` });
    }

    await pool.request()
      .input("orderId", sql.Int, orderId)
      .query(`
        UPDATE Orders SET orderStatus = 'Cancelled' WHERE orderId = @orderId;
        UPDATE OrderItems SET orderItemStatus = 'Cancelled' WHERE orderId = @orderId;
      `);

    // 🟢 Restore stock
    const items = await pool.request()
      .input("orderId", sql.Int, orderId)
      .query("SELECT productId, quantity FROM OrderItems WHERE orderId = @orderId");

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

    res.json({ success: true, message: `🛑 Order #${orderId} cancelled successfully` });
  } catch (err) {
    console.error("❌ Cancel order error:", err);
    res.status(500).json({ success: false, message: "Failed to cancel order" });
  }
});


module.exports = router;
