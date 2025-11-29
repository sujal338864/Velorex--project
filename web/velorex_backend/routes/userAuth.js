const express = require("express");
const router = express.Router();
const nodemailer = require("nodemailer");

let otpStore = {}; // in-memory store

// ✅ Generate OTP
router.post("/auth/send-otp", async (req, res) => {
  const { identifier: email } = req.body;
  if (!email) return res.status(400).json({ message: "Email is required" });

  const otp = Math.floor(100000 + Math.random() * 900000); // 6-digit
  otpStore[email] = { otp, createdAt: Date.now() };

  try {
    // setup your email
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    await transporter.sendMail({
      from: `"OneSolution" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Your OTP Code",
      text: `Your verification code is ${otp}. It expires in 5 minutes.`,
    });

    res.json({ message: "OTP sent successfully" });
  } catch (err) {
    console.error("Error sending OTP:", err);
    res.status(500).json({ message: "Failed to send OTP", error: err.message });
  }
});

// ✅ Verify OTP
router.post("/auth/verify-otp", (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ message: "Email and OTP required" });

  const record = otpStore[email];
  if (!record) return res.status(400).json({ message: "No OTP found for this email" });

  if (Date.now() - record.createdAt > 5 * 60 * 1000)
    return res.status(400).json({ message: "OTP expired" });

  if (record.otp.toString() !== otp.toString())
    return res.status(400).json({ message: "Invalid OTP" });

  delete otpStore[email];
  res.json({ message: "OTP verified successfully" });
});

module.exports = router;
