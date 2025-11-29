const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// ==========================================
// 💾 MOVE item from CART → SAVED FOR LATER
// ==========================================
router.post("/move-to-saved", async (req, res) => {
  const { userId, productId } = req.body;
  console.log("📩 move-to-saved called with:", req.body);

  if (!userId || !productId)
    return res.status(400).json({ message: "userId and productId are required" });

  try {
    const pool = await poolPromise;

    // ✅ Check if already exists in SavedForLater
    const check = await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`
        SELECT 1 FROM SavedForLater 
        WHERE UserId = @userId AND ProductId = @productId
      `);

    if (check.recordset.length > 0) {
      return res.json({ message: "⚠️ Item already in Saved for Later" });
    }

    // ✅ Insert into SavedForLater
    await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`
        INSERT INTO SavedForLater (UserId, ProductId, SavedAt)
        VALUES (@userId, @productId, GETDATE())
      `);

    // ✅ Remove from Cart
    await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`
        DELETE FROM Cart WHERE UserId = @userId AND ProductId = @productId
      `);

    res.json({ message: "✅ Moved to Saved for Later" });
  } catch (err) {
    console.error("❌ Error moving to saved:", err.message);
    res.status(500).json({ message: "Error moving to saved", error: err.message });
  }
});

// ==========================================
// 🛒 MOVE item from SAVED FOR LATER → CART
// ==========================================
router.post("/move-to-cart", async (req, res) => {
  const { userId, productId } = req.body;

  if (!userId || !productId)
    return res.status(400).json({ message: "userId and productId are required" });

  try {
    const pool = await poolPromise;

    // ✅ Prevent duplicate cart entry
    const exists = await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`SELECT 1 FROM Cart WHERE UserID = @userId AND ProductID = @productId`);

    if (exists.recordset.length === 0) {
      // 1️⃣ Add to Cart
      await pool.request()
        .input("userId", sql.NVarChar, userId)
        .input("productId", sql.Int, productId)
        .query(`
          INSERT INTO Cart (UserID, ProductID, Quantity)
          VALUES (@userId, @productId, 1)
        `);
    }

    // 2️⃣ Remove from SavedForLater
    await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`
        DELETE FROM SavedForLater WHERE UserID = @userId AND ProductID = @productId
      `);

    res.json({ message: "✅ Moved back to Cart" });
  } catch (err) {
    console.error("❌ Error moving to cart:", err);
    res.status(500).json({ message: "Error moving to cart" });
  }
});

// ==========================================
// 📦 GET all Saved for Later Items (with Product Data)
// ==========================================
// ==========================================
// 📦 GET all Saved for Later Items (with Product Data)
// ==========================================
// 📂 routes/savedForLater.js
router.get("/:userId", async (req, res) => {
  const { userId } = req.params;

  try {
    const pool = await poolPromise;

    const result = await pool.request()
      .input("userId", sql.NVarChar, userId)
      .query(`
        SELECT 
          s.Id AS savedId,
          s.UserId,
          p.ProductID AS id,
          p.Name AS name,
          p.Description AS description,
          p.Price AS price,
          p.OfferPrice AS offerPrice,
          (
            SELECT STRING_AGG(pi.ImageURL, ',')
            FROM ProductImages pi
            WHERE pi.ProductID = p.ProductID
          ) AS imageUrls
        FROM SavedForLater s
        JOIN Products p ON s.ProductID = p.ProductID
        WHERE s.UserId = @userId
      `);

    const savedItems = result.recordset.map((item) => ({
      id: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      offerPrice: item.offerPrice,
      imageUrls: item.imageUrls
        ? item.imageUrls.split(",").map((url) => url.trim())
        : ["https://via.placeholder.com/300"],
    }));

    res.json(savedItems);
  } catch (err) {
    console.error("❌ Error fetching saved items:", err);
    res.status(500).json({ error: "Failed to fetch saved items" });
  }
});


// router.get("/:userId", async (req, res) => {
//   const { userId } = req.params;

//   try {
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query(`
//         SELECT 
//           s.id AS savedId,
//           s.UserID,
//           s.ProductID,
//           p.Name AS ProductName,
//           p.Price,
//           (
//             SELECT TOP 1 pi.ImageURL
//             FROM ProductImages pi
//             WHERE pi.ProductID = p.ProductID
//           ) AS ImageUrl
//         FROM SavedForLater s
//         JOIN Products p ON s.ProductID = p.ProductID
//         WHERE s.UserID = @userId
//       `);

//     const savedItems = result.recordset.map(item => ({
//       savedId: item.savedId,
//       userId: item.UserID,
//       productId: item.ProductID,
//       productName: item.ProductName,
//       price: item.Price,
//       imageUrl: item.ImageUrl || "https://via.placeholder.com/300",
//     }));

//     res.json(savedItems);
//   } catch (err) {
//     console.error("❌ Error fetching saved items:", err);
//     res.status(500).json({ error: "Failed to fetch saved items" });
//   }
// });


// ==========================================
// ❌ DELETE item from Saved for Later
// ==========================================
router.delete("/:userId/:productId", async (req, res) => {
  const { userId, productId } = req.params;

  try {
    const pool = await poolPromise;
    await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`
        DELETE FROM SavedForLater WHERE UserID = @userId AND ProductID = @productId
      `);

    res.json({ message: "✅ Item removed from Saved for Later" });
  } catch (err) {
    console.error("❌ Error deleting saved item:", err);
    res.status(500).json({ message: "Failed to delete saved item" });
  }
});

module.exports = router;
