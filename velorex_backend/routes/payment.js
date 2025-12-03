const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

router.post("/create", async (req, res) => {
  try {
    const { orderId, userId, amount, paymentMethod, status } = req.body;
    if (!orderId || !userId || !amount || !paymentMethod) {
      return res.status(400).json({ success: false, error: "Missing required fields" });
    }

    const pool = await poolPromise;
    const transactionId = `TXN_${Date.now()}`;

    const result = await pool
      .request()
      .input("OrderId", sql.BigInt, orderId)
      .input("UserId", sql.NVarChar, userId)
      .input("Amount", sql.Decimal(10, 2), amount)
      .input("PaymentMethod", sql.NVarChar, paymentMethod)
      .input("PaymentStatus", sql.NVarChar, status || "Success")
      .input("TransactionId", sql.NVarChar, transactionId)
      .query(`
        INSERT INTO Payments (OrderId, UserId, Amount, PaymentMethod, PaymentStatus, TransactionId)
        OUTPUT INSERTED.PaymentId
        VALUES (@OrderId, @UserId, @Amount, @PaymentMethod, @PaymentStatus, @TransactionId)
      `);

    res.json({
      success: true,
      message: "Payment recorded successfully",
      paymentId: result.recordset[0].PaymentId,
      transactionId,
    });
  } catch (err) {
    console.error("❌ Payment error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get("/user/:userId", async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .input("UserId", sql.NVarChar, req.params.userId)
      .query("SELECT * FROM Payments WHERE UserId = @UserId ORDER BY PaymentDate DESC");
    res.json({ success: true, payments: result.recordset });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get("/:paymentId", async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .input("PaymentId", sql.Int, req.params.paymentId)
      .query("SELECT * FROM Payments WHERE PaymentId = @PaymentId");
    if (result.recordset.length === 0)
      return res.status(404).json({ success: false, message: "Payment not found" });
    res.json({ success: true, payment: result.recordset[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
