// routes/brands.js
const express = require("express");
const router = express.Router();
const pool = require("../models/db");

/**
 * ===============================
 *  GET /api/brands  → List brands
 * ===============================
 */
router.get("/", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        b.brand_id,
        b.name,
        b.category_id,
        b.subcategory_id,
        b.created_at,
        COALESCE(c.name, '') AS category_name,
        COALESCE(s.name, '') AS subcategory_name
      FROM brands b
      LEFT JOIN categories c ON b.category_id = c.category_id
      LEFT JOIN subcategories s ON b.subcategory_id = s.subcategory_id
      ORDER BY b.brand_id ASC
    `);

    res.status(200).json(result.rows);
  } catch (err) {
    console.error("❌ GET /brands:", err.message);
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;



// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// // =====================================================
// // ✅ GET ALL BRANDS
// // =====================================================
// router.get("/", async (req, res) => {
//   try {
//     const pool = await poolPromise;
//     const result = await pool.request().query(`
//       SELECT BrandID, Name, Description, CreatedAt
//       FROM Brands
//       ORDER BY CreatedAt DESC
//     `);
//     res.json(result.recordset);
//   } catch (err) {
//     console.error("❌ Error fetching brands:", err);
//     res.status(500).json({ error: "Internal server error" });
//   }
// });

// module.exports = router;

// // =====================================================
// // ✅ ADD BRAND
// // =====================================================
// router.post("/", async (req, res) => {
//   const { name, description } = req.body;

//   if (!name) {
//     return res.status(400).json({ error: "Brand name is required" });
//   }

//   try {
//     const pool = await poolPromise;
//     await pool.request()
//       .input("Name", sql.NVarChar, name)
//       .input("Description", sql.NVarChar, description || null)
//       .query(`
//         INSERT INTO Brands (Name, Description, CreatedAt)
//         VALUES (@Name, @Description, GETDATE())
//       `);

//     res.status(201).json({ message: "Brand added successfully" });
//   } catch (err) {
//     console.error("❌ Error adding brand:", err);
//     res.status(500).json({ error: "Internal server error" });
//   }
// });

// // =====================================================
// // ✅ DELETE BRAND
// // =====================================================
// router.delete("/:id", async (req, res) => {
//   const { id } = req.params;

//   try {
//     const pool = await poolPromise;
//     await pool.request()
//       .input("BrandID", sql.Int, id)
//       .query("DELETE FROM Brands WHERE BrandID = @BrandID");

//     res.json({ message: "Brand deleted successfully" });
//   } catch (err) {
//     console.error("❌ Error deleting brand:", err);
//     res.status(500).json({ error: "Internal server error" });
//   }
// });


