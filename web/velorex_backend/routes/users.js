const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// Example user routes (keep simple)
router.get("/", async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request().query("SELECT * FROM Users");
    res.json(result.recordset);
  } catch (err) {
    console.error("Error fetching users:", err);
    res.status(500).json({ message: "Failed to fetch users" });
  }
});

module.exports = router;
