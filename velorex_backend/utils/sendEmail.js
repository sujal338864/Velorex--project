const nodemailer = require("nodemailer");

const sendEmail = async (to, subject, text) => {
  try {
    // ✅ Create email transporter (Gmail + App Password)
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    // ✅ Define email details
    const mailOptions = {
      from: `"Velorex" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      text,
    };

    // ✅ Send email
    await transporter.sendMail(mailOptions);
    console.log("✅ Email sent successfully to:", to);
  } catch (error) {
    console.error("❌ Email sending failed:", error);
  }
};

module.exports = sendEmail;
