const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// =====================================================
// ✅ GET ALL BRANDS
// =====================================================
router.get("/", async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request().query(`
      SELECT BrandID, Name, Description, CreatedAt
      FROM Brands
      ORDER BY CreatedAt DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Error fetching brands:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;

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


