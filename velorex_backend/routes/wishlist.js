const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// ✅ Fetch wishlist with all product images
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const pool = await poolPromise;

    const result = await pool.request()
      .input("userId", sql.VarChar, userId)
      .query(`
        SELECT 
          w.WishlistID,
          w.UserID,
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
        FROM Wishlist w
        INNER JOIN Products p ON w.ProductID = p.ProductID
        WHERE w.UserID = @userId
        ORDER BY w.CreatedAt DESC
      `);

    const products = result.recordset.map((item) => ({
      ...item,
      imageUrls: item.imageUrls
        ? item.imageUrls.split(",").map((url) => url.trim())
        : ["https://via.placeholder.com/300"],
    }));

    res.json(products);
  } catch (err) {
    console.error("❌ Wishlist fetch error:", err);
    res.status(500).send("Server error");
  }
});


// ✅ Add to wishlist
router.post("/add", async (req, res) => {
  try {
    const { userId, productId } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input("userId", sql.VarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`
        IF NOT EXISTS (
          SELECT 1 FROM Wishlist WHERE UserID = @userId AND ProductID = @productId
        )
        INSERT INTO Wishlist (UserID, ProductID, CreatedAt)
        VALUES (@userId, @productId, GETDATE())
      `);

    res.json({ success: true, message: "✅ Added to wishlist" });
  } catch (err) {
    console.error("❌ Add to wishlist error:", err);
    res.status(500).send("Server error");
  }
});

// ✅ Remove from wishlist
router.post("/remove", async (req, res) => {
  try {
    const { userId, productId } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input("userId", sql.VarChar, userId)
      .input("productId", sql.Int, productId)
      .query(`
        DELETE FROM Wishlist
        WHERE UserID = @userId AND ProductID = @productId
      `);

    res.json({ success: true, message: "✅ Removed from wishlist" });
  } catch (err) {
    console.error("❌ Remove from wishlist error:", err);
    res.status(500).send("Server error");
  }
});

module.exports = router;
