const express = require("express");
const router = express.Router();
const pool = require("../models/db");

// ✅ Get all categories
router.get("/", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT category_id, name, image_url, created_at
       FROM categories
       ORDER BY created_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;



// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// // ✅ Get all categories
// router.get('/', async (req, res) => {
//   try {
//     const pool = await poolPromise;
//     const result = await pool.request()
//       .query('SELECT CategoryID, Name, ImageUrl, CreatedAt FROM Categories ORDER BY CreatedAt DESC');
//     res.json(result.recordset);
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: err.message });
//   }
// });


// module.exports = router;
