const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// ✅ Get all categories
router.get('/', async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .query('SELECT CategoryID, Name, ImageUrl, CreatedAt FROM Categories ORDER BY CreatedAt DESC');
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
