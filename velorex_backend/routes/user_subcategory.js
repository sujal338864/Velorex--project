const express = require("express");
const router = express.Router();
const pool = require("../models/db");

/* =====================================================
   GET all subcategories (optional filter by categoryId)
   GET /api/subcategories?categoryId=1
   ===================================================== */
router.get("/", async (req, res) => {
  try {
    const { categoryId } = req.query;

    let query = `
      SELECT
        s.subcategory_id AS subcategory_id,
        s.name AS name,
        s.category_id AS category_id,
        c.name AS category_name,
        s.created_at AS created_at
      FROM subcategories s
      INNER JOIN categories c ON s.category_id = c.category_id
    `;

    const values = [];
    if (categoryId) {
      query += ` WHERE s.category_id = $1`;
      values.push(categoryId);
    }

    const { rows } = await pool.query(query, values);
    res.json(rows);
  } catch (err) {
    console.error("❌ Error fetching subcategories:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;




// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// router.get("/subcategories", async (req, res) => {
//   const { categoryId } = req.query;
//   if (!categoryId) return res.status(400).json({ message: "categoryId is required" });

//   try {
//     const pool = await poolPromise;
//     const result = await pool.request()
//       .input("categoryId", sql.Int, categoryId)
//       .query(`
//         SELECT 
//           SubcategoryID AS subcategoryId,
//           CategoryID AS categoryId,
//           Name AS name,
//           Description AS description,
//           ImageURL AS imageUrl
//         FROM Subcategories
//         WHERE CategoryID = @categoryId
//         ORDER BY Name ASC
//       `);

//     res.json(result.recordset);
//   } catch (err) {
//     console.error("❌ Error fetching subcategories:", err);
//     res.status(500).json({ message: "Internal server error" });
//   }
// });

// module.exports = router;
