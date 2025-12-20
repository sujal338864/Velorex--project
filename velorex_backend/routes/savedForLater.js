const express = require("express");
const router = express.Router();
const pool = require("../models/db");


// ==========================================
// MOVE CART → SAVED
// ==========================================
router.post("/move-to-saved", async (req, res) => {
  const { userId, productId } = req.body;

  if (!userId || !productId)
    return res.status(400).json({ message: "userId and productId are required" });

  try {
    // already exists?
    const exists = await pool.query(
      `SELECT 1 FROM saved_for_later WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    if (exists.rows.length > 0) {
      return res.json({ message: "Item already in Saved for Later" });
    }

    // insert
    await pool.query(
      `
      INSERT INTO saved_for_later (user_id, product_id, saved_at)
      VALUES ($1, $2, NOW())
      `,
      [userId, productId]
    );

    // remove from cart
    await pool.query(
      `DELETE FROM cart WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    res.json({ message: "Moved to Saved for Later" });
  } catch (err) {
    console.error("move to saved error", err);
    res.status(500).json({ message: "Error moving to saved" });
  }
});


// ==========================================
// MOVE SAVED → CART
// ==========================================
router.post("/move-to-cart", async (req, res) => {
  const { userId, productId } = req.body;

  if (!userId || !productId)
    return res.status(400).json({ message: "userId and productId required" });

  try {
    // check if already in cart
    const inCart = await pool.query(
      `SELECT 1 FROM cart WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    if (inCart.rows.length === 0) {
      await pool.query(
        `
        INSERT INTO cart (user_id, product_id, quantity)
        VALUES ($1, $2, 1)
        `,
        [userId, productId]
      );
    }

    // remove from saved
    await pool.query(
      `DELETE FROM saved_for_later WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    res.json({ message: "Moved back to Cart" });
  } catch (err) {
    console.error("move to cart error", err);
    res.status(500).json({ message: "Error moving to cart" });
  }
});


// ==========================================
// GET SAVED ITEMS + PRODUCT DETAILS
// ==========================================
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await pool.query(
      `
      SELECT 
          s.id AS saved_id,
        p.product_id,
        p.name,
        p.description,
        p.price,
        p.offer_price,
        (
          SELECT STRING_AGG(pi.image_url, ',')
          FROM product_images pi
          WHERE pi.product_id = p.product_id
        ) AS imageUrls
      FROM saved_for_later s
      JOIN products p ON s.product_id = p.product_id
      WHERE s.user_id = $1
      `,
      [userId]
    );

    const savedItems = result.rows.map(item => ({
      id: item.product_id,
      name: item.name,
      description: item.description,
      price: item.price,
      offerPrice: item.offer_price,
      imageUrls: item.imageurls
        ? item.imageurls.split(",").map(u => u.trim())
        : ["https://via.placeholder.com/300"]
    }));

    res.json(savedItems);
  } catch (err) {
    console.error("get saved error", err);
    res.status(500).json({ error: "Failed to fetch saved items" });
  }
});


// ==========================================
// DELETE SAVED ITEM
// ==========================================
router.delete("/:userId/:productId", async (req, res) => {
  const { userId, productId } = req.params;

  try {
    await pool.query(
      `DELETE FROM saved_for_later WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    res.json({ message: "Item removed from Saved for Later" });
  } catch (err) {
    console.error("delete save error", err);
    res.status(500).json({ message: "Failed to delete saved item" });
  }
});

module.exports = router;



// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// // ==========================================
// // 💾 MOVE item from CART → SAVED FOR LATER
// // ==========================================
// router.post("/move-to-saved", async (req, res) => {
//   const { userId, productId } = req.body;
//   console.log("📩 move-to-saved called with:", req.body);

//   if (!userId || !productId)
//     return res.status(400).json({ message: "userId and productId are required" });

//   try {
//     const pool = await poolPromise;

//     // ✅ Check if already exists in SavedForLater
//     const check = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query(`
//         SELECT 1 FROM SavedForLater 
//         WHERE UserId = @userId AND ProductId = @productId
//       `);

//     if (check.recordset.length > 0) {
//       return res.json({ message: "⚠️ Item already in Saved for Later" });
//     }

//     // ✅ Insert into SavedForLater
//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query(`
//         INSERT INTO SavedForLater (UserId, ProductId, SavedAt)
//         VALUES (@userId, @productId, GETDATE())
//       `);

//     // ✅ Remove from Cart
//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query(`
//         DELETE FROM Cart WHERE UserId = @userId AND ProductId = @productId
//       `);

//     res.json({ message: "✅ Moved to Saved for Later" });
//   } catch (err) {
//     console.error("❌ Error moving to saved:", err.message);
//     res.status(500).json({ message: "Error moving to saved", error: err.message });
//   }
// });

// // ==========================================
// // 🛒 MOVE item from SAVED FOR LATER → CART
// // ==========================================
// router.post("/move-to-cart", async (req, res) => {
//   const { userId, productId } = req.body;

//   if (!userId || !productId)
//     return res.status(400).json({ message: "userId and productId are required" });

//   try {
//     const pool = await poolPromise;

//     // ✅ Prevent duplicate cart entry
//     const exists = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query(`SELECT 1 FROM Cart WHERE UserID = @userId AND ProductID = @productId`);

//     if (exists.recordset.length === 0) {
//       // 1️⃣ Add to Cart
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("productId", sql.Int, productId)
//         .query(`
//           INSERT INTO Cart (UserID, ProductID, Quantity)
//           VALUES (@userId, @productId, 1)
//         `);
//     }

//     // 2️⃣ Remove from SavedForLater
//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query(`
//         DELETE FROM SavedForLater WHERE UserID = @userId AND ProductID = @productId
//       `);

//     res.json({ message: "✅ Moved back to Cart" });
//   } catch (err) {
//     console.error("❌ Error moving to cart:", err);
//     res.status(500).json({ message: "Error moving to cart" });
//   }
// });

// // ==========================================
// // 📦 GET all Saved for Later Items (with Product Data)
// // ==========================================
// // ==========================================
// // 📦 GET all Saved for Later Items (with Product Data)
// // ==========================================
// // 📂 routes/savedForLater.js
// router.get("/:userId", async (req, res) => {
//   const { userId } = req.params;

//   try {
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query(`
//         SELECT 
//           s.Id AS savedId,
//           s.UserId,
//           p.ProductID AS id,
//           p.Name AS name,
//           p.Description AS description,
//           p.Price AS price,
//           p.OfferPrice AS offerPrice,
//           (
//             SELECT STRING_AGG(pi.ImageURL, ',')
//             FROM ProductImages pi
//             WHERE pi.ProductID = p.ProductID
//           ) AS imageUrls
//         FROM SavedForLater s
//         JOIN Products p ON s.ProductID = p.ProductID
//         WHERE s.UserId = @userId
//       `);

//     const savedItems = result.recordset.map((item) => ({
//       id: item.id,
//       name: item.name,
//       description: item.description,
//       price: item.price,
//       offerPrice: item.offerPrice,
//       imageUrls: item.imageUrls
//         ? item.imageUrls.split(",").map((url) => url.trim())
//         : ["https://via.placeholder.com/300"],
//     }));

//     res.json(savedItems);
//   } catch (err) {
//     console.error("❌ Error fetching saved items:", err);
//     res.status(500).json({ error: "Failed to fetch saved items" });
//   }
// });


// // router.get("/:userId", async (req, res) => {
// //   const { userId } = req.params;

// //   try {
// //     const pool = await poolPromise;

// //     const result = await pool.request()
// //       .input("userId", sql.NVarChar, userId)
// //       .query(`
// //         SELECT 
// //           s.id AS savedId,
// //           s.UserID,
// //           s.ProductID,
// //           p.Name AS ProductName,
// //           p.Price,
// //           (
// //             SELECT TOP 1 pi.ImageURL
// //             FROM ProductImages pi
// //             WHERE pi.ProductID = p.ProductID
// //           ) AS ImageUrl
// //         FROM SavedForLater s
// //         JOIN Products p ON s.ProductID = p.ProductID
// //         WHERE s.UserID = @userId
// //       `);

// //     const savedItems = result.recordset.map(item => ({
// //       savedId: item.savedId,
// //       userId: item.UserID,
// //       productId: item.ProductID,
// //       productName: item.ProductName,
// //       price: item.Price,
// //       imageUrl: item.ImageUrl || "https://via.placeholder.com/300",
// //     }));

// //     res.json(savedItems);
// //   } catch (err) {
// //     console.error("❌ Error fetching saved items:", err);
// //     res.status(500).json({ error: "Failed to fetch saved items" });
// //   }
// // });


// // ==========================================
// // ❌ DELETE item from Saved for Later
// // ==========================================
// router.delete("/:userId/:productId", async (req, res) => {
//   const { userId, productId } = req.params;

//   try {
//     const pool = await poolPromise;
//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query(`
//         DELETE FROM SavedForLater WHERE UserID = @userId AND ProductID = @productId
//       `);

//     res.json({ message: "✅ Item removed from Saved for Later" });
//   } catch (err) {
//     console.error("❌ Error deleting saved item:", err);
//     res.status(500).json({ message: "Failed to delete saved item" });
//   }
// });

// module.exports = router;
