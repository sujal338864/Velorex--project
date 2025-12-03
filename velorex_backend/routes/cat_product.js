// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// // ✅ Get products by category and/or subcategory
// router.get("/products", async (req, res) => {
//   const { categoryId, subcategoryId } = req.query;

//   try {
//     const pool = await poolPromise;
//     let query = `
//       SELECT 
//         ProductID AS id,
//         Name AS name,
//         Description AS description,
//         Price AS price,
//         OfferPrice AS offerPrice,
//         Quantity AS quantity,
//         CategoryID AS categoryId,
//         SubcategoryID AS subcategoryId,
//         BrandID AS brandId,
//         ImageURLs AS images
//       FROM Products
//       WHERE 1=1
//     `;

//     if (categoryId) query += ` AND CategoryID = ${categoryId}`;
//     if (subcategoryId) query += ` AND SubcategoryID = ${subcategoryId}`;

//     const result = await pool.request().query(query);
//     res.json(result.recordset);
//   } catch (err) {
//     console.error("❌ Error fetching products:", err);
//     res.status(500).json({ message: "Internal server error" });
//   }
// });

// module.exports = router;

