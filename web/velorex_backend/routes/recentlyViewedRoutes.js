const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// ✅ Add to Recently Viewed
router.post("/", async (req, res) => {
  const { userId, productId } = req.body;
  try {
    const pool = await sql.connect(config);

    // If product already viewed, update timestamp
    await pool.request()
      .input("UserId", sql.NVarChar, userId)
      .input("ProductID", sql.Int, productId)
      .query(`
        IF EXISTS (SELECT 1 FROM RecentlyViewed WHERE UserId=@UserId AND ProductID=@ProductID)
          UPDATE RecentlyViewed SET ViewedAt=GETDATE() WHERE UserId=@UserId AND ProductID=@ProductID
        ELSE
          INSERT INTO RecentlyViewed (UserId, ProductID) VALUES (@UserId, @ProductID)
      `);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ✅ Get user’s recently viewed items (limit 10)
router.get("/:userId", async (req, res) => {
  const pool = await sql.connect(config);
  const result = await pool.request()
    .input("UserId", sql.NVarChar, req.params.userId)
    .query(`
      SELECT TOP 10 rv.Id AS ViewedId, p.*
      FROM RecentlyViewed rv
      JOIN Products p ON rv.ProductID = p.ProductID
      WHERE rv.UserId = @UserId
      ORDER BY rv.ViewedAt DESC
    `);
  res.json(result.recordset);
});

module.exports = router;
