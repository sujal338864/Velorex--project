const express = require("express");
const router = express.Router();
const pool = require("../models/db");
const nodemailer = require("nodemailer");


// =========================
// SEND OTP
// =========================
router.post("/auth/send-otp", async (req, res) => {
  const { identifier: email } = req.body;

  if (!email) return res.status(400).json({ message: "Email is required" });

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

  try {
    // ❌ Invalidate previous OTP
    await pool.query(
      `DELETE FROM auth_otps WHERE email = $1`,
      [email]
    );

    // ✅ Insert new OTP
    await pool.query(
      `
      INSERT INTO auth_otps (email, otp, expires_at)
      VALUES ($1, $2, $3)
      `,
      [email, otp, expiresAt]
    );

    // Send Email
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      }
    });

    await transporter.sendMail({
      from: `"OneSolution" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Your OTP Verification Code",
      text: `Your OneSolution verification OTP is ${otp}. It expires in 5 minutes.`
    });

    res.json({ success: true, message: "OTP sent successfully" });

  } catch (err) {
    console.error("OTP Send Error:", err);
    res.status(500).json({ success: false, message: "Failed to send OTP" });
  }
});


// =========================
// VERIFY OTP
// =========================
router.post("/auth/verify-otp", async (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp)
    return res.status(400).json({ message: "Email and OTP required" });

  try {
    const result = await pool.query(
      `
      SELECT *
      FROM auth_otps
      WHERE email = $1 AND otp = $2
      ORDER BY created_at DESC
      LIMIT 1
      `,
      [email, otp]
    );

    if (!result.rows.length)
      return res.status(400).json({ message: "Invalid OTP" });

    const record = result.rows[0];

    if (record.verified)
      return res.status(400).json({ message: "OTP already used" });

    if (new Date() > new Date(record.expires_at))
      return res.status(400).json({ message: "OTP expired" });

    // Mark as verified
    await pool.query(
      `UPDATE auth_otps SET verified = TRUE WHERE id = $1`,
      [record.id]
    );

    res.json({ success: true, message: "OTP verified successfully" });

  } catch (err) {
    console.error("OTP verify error:", err);
    res.status(500).json({ success: false, message: "Failed to verify OTP" });
  }
});


module.exports = router;



// const express = require("express");
// const router = express.Router();
// const nodemailer = require("nodemailer");

// let otpStore = {}; // in-memory store

// // ✅ Generate OTP
// router.post("/auth/send-otp", async (req, res) => {
//   const { identifier: email } = req.body;
//   if (!email) return res.status(400).json({ message: "Email is required" });

//   const otp = Math.floor(100000 + Math.random() * 900000); // 6-digit
//   otpStore[email] = { otp, createdAt: Date.now() };

//   try {
//     // setup your email
//     const transporter = nodemailer.createTransport({
//       service: "gmail",
//       auth: {
//         user: process.env.EMAIL_USER,
//         pass: process.env.EMAIL_PASS,
//       },
//     });

//     await transporter.sendMail({
//       from: `"OneSolution" <${process.env.EMAIL_USER}>`,
//       to: email,
//       subject: "Your OTP Code",
//       text: `Your verification code is ${otp}. It expires in 5 minutes.`,
//     });

//     res.json({ message: "OTP sent successfully" });
//   } catch (err) {
//     console.error("Error sending OTP:", err);
//     res.status(500).json({ message: "Failed to send OTP", error: err.message });
//   }
// });

// // ✅ Verify OTP
// router.post("/auth/verify-otp", (req, res) => {
//   const { email, otp } = req.body;
//   if (!email || !otp) return res.status(400).json({ message: "Email and OTP required" });

//   const record = otpStore[email];
//   if (!record) return res.status(400).json({ message: "No OTP found for this email" });

//   if (Date.now() - record.createdAt > 5 * 60 * 1000)
//     return res.status(400).json({ message: "OTP expired" });

//   if (record.otp.toString() !== otp.toString())
//     return res.status(400).json({ message: "Invalid OTP" });

//   delete otpStore[email];
//   res.json({ message: "OTP verified successfully" });
// });

// module.exports = router;
