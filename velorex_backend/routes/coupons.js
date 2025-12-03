const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// ---------------------------------------------------------
// GET ALL COUPONS (Admin + User)
// ---------------------------------------------------------
router.get("/", async (_, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .query("SELECT * FROM Coupons ORDER BY CouponID DESC");

    res.status(200).json(result.recordset);
  } catch (err) {
    console.error("❌ GET /api/coupons:", err);
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------
// APPLY COUPON (USER CART PAGE)
// /api/coupons/apply/:code
// ---------------------------------------------------------
router.get("/apply/:code", async (req, res) => {
  const { code } = req.params;

  try {
    const pool = await poolPromise;

    const result = await pool.request()
      .input("Code", sql.NVarChar, code)
      .query(`
        SELECT *
        FROM Coupons
        WHERE Code = @Code
          AND Status = 'Active'
          AND (StartDate IS NULL OR StartDate <= CAST(GETDATE() AS DATE))
          AND (EndDate IS NULL OR EndDate >= CAST(GETDATE() AS DATE))
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({ message: "Invalid or expired coupon" });
    }

    res.status(200).json(result.recordset[0]);

  } catch (err) {
    console.error("❌ APPLY COUPON ERROR:", err);
    res.status(500).json({ error: "Server error" });
  }
});

module.exports = router;
