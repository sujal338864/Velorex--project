const express = require("express");
const router = express.Router();
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() });

const pool = require("../models/db"); // pg Pool
const supabase = require("../models/supabaseClient");

// ===========================
// Helper: Upload to Supabase
// ===========================
async function uploadToSupabase(file) {
  const fileName = `${Date.now()}_${file.originalname}`;

  const { data, error } = await supabase.storage
    .from("posters")
    .upload(`posters/${fileName}`, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
    });

  if (error) throw error;

  return `https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/${data.fullPath}`;
}

// ===========================
// POST /api/posters
// ===========================
router.post("/", upload.array("images", 5), async (req, res) => {
  try {
    const { title, imageUrls } = req.body;
    let finalImageUrls = [];

    // Case 1: Multipart upload
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const url = await uploadToSupabase(file);
        finalImageUrls.push(url);
      }
    }
    // Case 2: URLs from Flutter
    else if (imageUrls) {
      if (typeof imageUrls === "string") {
        try {
          const parsed = JSON.parse(imageUrls);
          finalImageUrls = Array.isArray(parsed) ? parsed : [parsed];
        } catch {
          finalImageUrls = [imageUrls];
        }
      } else {
        finalImageUrls = Array.isArray(imageUrls) ? imageUrls : [imageUrls];
      }
    }

    if (!title || finalImageUrls.length === 0) {
      return res.status(400).json({ error: "Title and image are required" });
    }

    await pool.query(
      `
      INSERT INTO posters (title, image_url)
      VALUES ($1, $2)
      `,
      [title, finalImageUrls[0]]
    );

    res.status(201).json({
      message: "✅ Poster added successfully",
      imageUrl: finalImageUrls[0],
    });
  } catch (err) {
    console.error("❌ Error adding poster:", err);
    res.status(500).json({ error: err.message });
  }
});

// ===========================
// GET /api/posters
// ===========================
router.get("/", async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT * FROM posters ORDER BY id DESC`
    );
    res.json(rows);
  } catch (err) {
    console.error("❌ Error fetching posters:", err);
    res.status(500).json({ error: "Failed to fetch posters" });
  }
});

// ===========================
// DELETE /api/posters/:id
// ===========================
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(`DELETE FROM posters WHERE id = $1`, [id]);

    res.json({ message: "Poster deleted successfully" });
  } catch (err) {
    console.error("❌ Error deleting poster:", err);
    res.status(500).json({ error: "Failed to delete poster" });
  }
});

module.exports = router;




// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// router.post("/create", async (req, res) => {
//   try {
//     const { orderId, userId, amount, paymentMethod, status } = req.body;
//     if (!orderId || !userId || !amount || !paymentMethod) {
//       return res.status(400).json({ success: false, error: "Missing required fields" });
//     }

//     const pool = await poolPromise;
//     const transactionId = `TXN_${Date.now()}`;

//     const result = await pool
//       .request()
//       .input("OrderId", sql.BigInt, orderId)
//       .input("UserId", sql.NVarChar, userId)
//       .input("Amount", sql.Decimal(10, 2), amount)
//       .input("PaymentMethod", sql.NVarChar, paymentMethod)
//       .input("PaymentStatus", sql.NVarChar, status || "Success")
//       .input("TransactionId", sql.NVarChar, transactionId)
//       .query(`
//         INSERT INTO Payments (OrderId, UserId, Amount, PaymentMethod, PaymentStatus, TransactionId)
//         OUTPUT INSERTED.PaymentId
//         VALUES (@OrderId, @UserId, @Amount, @PaymentMethod, @PaymentStatus, @TransactionId)
//       `);

//     res.json({
//       success: true,
//       message: "Payment recorded successfully",
//       paymentId: result.recordset[0].PaymentId,
//       transactionId,
//     });
//   } catch (err) {
//     console.error("❌ Payment error:", err);
//     res.status(500).json({ success: false, error: err.message });
//   }
// });

// router.get("/user/:userId", async (req, res) => {
//   try {
//     const pool = await poolPromise;
//     const result = await pool.request()
//       .input("UserId", sql.NVarChar, req.params.userId)
//       .query("SELECT * FROM Payments WHERE UserId = @UserId ORDER BY PaymentDate DESC");
//     res.json({ success: true, payments: result.recordset });
//   } catch (err) {
//     res.status(500).json({ success: false, error: err.message });
//   }
// });

// router.get("/:paymentId", async (req, res) => {
//   try {
//     const pool = await poolPromise;
//     const result = await pool.request()
//       .input("PaymentId", sql.Int, req.params.paymentId)
//       .query("SELECT * FROM Payments WHERE PaymentId = @PaymentId");
//     if (result.recordset.length === 0)
//       return res.status(404).json({ success: false, message: "Payment not found" });
//     res.json({ success: true, payment: result.recordset[0] });
//   } catch (err) {
//     res.status(500).json({ success: false, error: err.message });
//   }
// });

// module.exports = router;
