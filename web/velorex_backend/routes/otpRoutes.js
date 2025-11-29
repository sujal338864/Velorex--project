const express = require("express");
const router = express.Router();
const nodemailer = require("nodemailer");

let otpStore = {}; // In-memory OTP storage

// ✅ Send OTP
router.post("/auth/send-otp", async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: "Email is required" });

  const otp = Math.floor(100000 + Math.random() * 900000);

  // Store OTP with timestamp
  otpStore[email] = { otp, createdAt: Date.now() };
  console.log("✅ OTP generated:", otp, "for", email);

  try {
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
      text: `Your OTP code is ${otp}. It expires in 5 minutes.`,
    });

    res.json({ message: "OTP sent successfully" });
  } catch (error) {
    console.error("❌ Error sending OTP:", error);
    res.status(500).json({ message: "Failed to send OTP", error: error.message });
  }
});

// ✅ Verify OTP
router.post("/auth/verify-otp", (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp)
    return res.status(400).json({ message: "Email and OTP required" });

  const record = otpStore[email];
  if (!record) return res.status(400).json({ message: "No OTP found for this email" });

  // Check expiration (5 minutes)
  if (Date.now() - record.createdAt > 5 * 60 * 1000)
    return res.status(400).json({ message: "OTP expired" });

  if (record.otp.toString() !== otp.toString())
    return res.status(400).json({ message: "Invalid OTP" });

  console.log("✅ Verifying OTP:", otp, "for", email, "Stored:", record.otp);

  delete otpStore[email]; // remove after verification
  res.json({ message: "OTP verified successfully" });
});

module.exports = router;

