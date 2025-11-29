const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

router.get("/subcategories", async (req, res) => {
  const { categoryId } = req.query;
  if (!categoryId) return res.status(400).json({ message: "categoryId is required" });

  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .input("categoryId", sql.Int, categoryId)
      .query(`
        SELECT 
          SubcategoryID AS subcategoryId,
          CategoryID AS categoryId,
          Name AS name,
          Description AS description,
          ImageURL AS imageUrl
        FROM Subcategories
        WHERE CategoryID = @categoryId
        ORDER BY Name ASC
      `);

    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Error fetching subcategories:", err);
    res.status(500).json({ message: "Internal server error" });
  }
});

module.exports = router;
