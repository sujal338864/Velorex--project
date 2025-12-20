const express = require("express");
const router = express.Router();
const pool = require("../models/db");

// ============================
// 🛒 GET CART BY USER
// ============================
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const { rows } = await pool.query(`
      SELECT 
        c.id AS cart_id,
        c.user_id,
        c.product_id,
        c.quantity,
        p.name AS product_name,
        p.price,
        p.offer_price,
        (
          SELECT image_url 
          FROM product_images 
          WHERE product_id = p.product_id 
          ORDER BY product_image_id ASC 
          LIMIT 1
        ) AS image_url
      FROM cart c
      JOIN products p 
      ON c.product_id = p.product_id
      WHERE c.user_id = $1
    `, [userId]);

    const cartItems = rows.map(item => {
      const hasOffer = item.offer_price && Number(item.offer_price) > 0;

      return {
        cartId: item.cart_id,
        userId: item.user_id,
        productId: item.product_id,
        productName: item.product_name,
        price: Number(item.price),
        offerPrice: hasOffer ? Number(item.offer_price) : Number(item.price),
        imageUrl: item.image_url || "https://via.placeholder.com/300",
        quantity: Number(item.quantity),
        savedAmount: hasOffer ? Number(item.price - item.offer_price) : 0,
        discountPercent: hasOffer
          ? Math.round(((item.price - item.offer_price) / item.price) * 100)
          : 0,
      };
    });

    res.json(cartItems);
  } catch (err) {
    console.error("❌ Error fetching cart:", err);
    res.status(500).json({ error: "Failed to fetch cart" });
  }
});


// ============================
// ❌ CLEAR CART
// ============================
router.post("/clear/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    await pool.query(
      `DELETE FROM cart WHERE user_id = $1`,
      [userId]
    );

    res.json({ success: true });
  } catch (err) {
    console.error("❌ Clear cart error:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});


// ============================
// ❌ REMOVE BY PRODUCT
// ============================
router.post("/remove-by-product", async (req, res) => {
  try {
    const { userId, productId } = req.body;

    await pool.query(
      `DELETE FROM cart WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    res.json({ message: "✅ Item removed" });
  } catch (err) {
    console.error("❌ Error removing item:", err);
    res.status(500).json({ error: "Failed to remove item" });
  }
});


// ============================
// ➕ ADD TO CART  (UPSERT)
// ============================
router.post("/", async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;

    console.log("📥 Add to cart:", { userId, productId, quantity });

    await pool.query(`
      INSERT INTO cart (user_id, product_id, quantity)
      VALUES ($1,$2,$3)
      ON CONFLICT (user_id, product_id)
      DO UPDATE SET quantity = cart.quantity + EXCLUDED.quantity
    `, [userId, productId, quantity]);

    res.json({ message: "✅ Cart updated" });
  } catch (err) {
    console.error("❌ Error adding to cart:", err);
    res.status(500).json({ error: "Failed to add to cart" });
  }
});


// ============================
// ❌ DELETE BY CART ID
// ============================
router.delete("/remove/:cartId", async (req, res) => {
  try {
    const { cartId } = req.params;

    await pool.query(
      `DELETE FROM cart WHERE id = $1`,
      [cartId]
    );

    res.json({ message: "✅ Item removed" });
  } catch (err) {
    console.error("❌ Error removing item:", err);
    res.status(500).json({ error: "Failed to remove item" });
  }
});


// ============================
// 🔄 UPDATE QUANTITY
// ============================
router.put("/update", async (req, res) => {
  try {
    const { cartId, quantity } = req.body;

    if (!cartId || quantity == null) {
      return res.status(400).json({ error: "cartId & quantity required" });
    }

    await pool.query(
      `UPDATE cart SET quantity = $1 WHERE id = $2`,
      [quantity, cartId]
    );

    res.json({ message: "✅ Quantity updated" });
  } catch (err) {
    console.error("❌ Error updating quantity:", err);
    res.status(500).json({ error: "Failed to update quantity" });
  }
});

module.exports = router;



// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// // ============================
// // 🛒 GET: Cart Items by User ID
// // ============================
// // ✅ Get all cart items for a specific user
// router.get("/:userId", async (req, res) => {
//   const { userId } = req.params;

//   try {
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query(`
//         SELECT 
//           c.id AS cartId,
//           c.userId,
//           c.productId,
//           c.quantity,
//           p.Name AS ProductName,
//           p.Price,
//           p.OfferPrice,
//           (
//             SELECT TOP 1 pi.ImageURL
//             FROM ProductImages pi
//             WHERE pi.ProductID = p.ProductID
//           ) AS ImageUrl
//         FROM Cart c
//         JOIN Products p ON c.productId = p.ProductID
//         WHERE c.userId = @userId
//       `);

//     // ✅ Normalize and clarify data
//     const cartItems = result.recordset.map(item => {
//       const hasOffer = item.OfferPrice && item.OfferPrice > 0;

//       return {
//         cartId: item.cartId,
//         userId: item.userId,
//         productId: item.productId,
//         productName: item.ProductName,
//         price: Number(item.Price),                 // ✅ Original (MRP)
//         offerPrice: hasOffer ? Number(item.OfferPrice) : Number(item.offerPricePrice), // ✅ Offer or fallback
//         imageUrl: item.ImageUrl || "https://via.placeholder.com/300",
//         quantity: Number(item.quantity),
//         savedAmount: hasOffer ? Number(item.Price - item.OfferPrice) : 0,   // ✅ Added for “You saved ₹…”
//         discountPercent: hasOffer 
//           ? Math.round(((item.Price - item.OfferPrice) / item.Price) * 100)
//           : 0,                                                             // ✅ Added for “% off”
//       };
//     });

//     res.status(200).json(cartItems);
//   } catch (err) {
//     console.error("❌ Error fetching cart:", err);
//     res.status(500).json({ error: "Failed to fetch cart" });
//   }
// });

// // ============================
// // ❌ POST: Clear entire cart
// // ============================
// router.post('/clear/:userId', async (req, res) => {
//   const { userId } = req.params;
//   try {
//     const pool = await poolPromise;
//     await pool.request()
//       .input('UserID', sql.NVarChar, userId)
//       .query('DELETE FROM Cart WHERE UserID = @UserID');
//     res.json({ success: true });
//   } catch (err) {
//     console.error("Clear cart error:", err);
//     res.status(500).json({ success: false, error: err.message });
//   }
// });

// // ============================
// // ❌ POST: Remove Item by Product ID
// // ============================
// router.post('/remove-by-product', async (req, res) => {
//   try {
//     const { userId, productId } = req.body;
//     const pool = await poolPromise;

//     await pool.request()
//       .input('userId', sql.NVarChar, userId)
//       .input('productId', sql.Int, productId)
//       .query('DELETE FROM Cart WHERE userId = @userId AND productId = @productId');

//     return res.json({ message: '✅ Item removed' });
//   } catch (err) {
//     console.error('❌ Error removing (by product):', err);
//     return res.status(500).json({ error: 'Failed to remove item' });
//   }
// });

// // ============================
// // ➕ POST: Add Item to Cart
// // ============================
// router.post("/", async (req, res) => {
//   const { userId, productId, quantity } = req.body;
//   console.log("📥 Add to cart request:", { userId, productId, quantity });

//   try {
//     const pool = await poolPromise;

//     // ✅ Check if product already exists
//     const check = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query("SELECT * FROM Cart WHERE userId = @userId AND productId = @productId");

//     if (check.recordset.length > 0) {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("productId", sql.Int, productId)
//         .input("quantity", sql.Int, quantity)
//         .query("UPDATE Cart SET quantity = quantity + @quantity WHERE userId = @userId AND productId = @productId");

//       return res.json({ message: "✅ Quantity updated" });
//     } else {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("productId", sql.Int, productId)
//         .input("quantity", sql.Int, quantity)
//         .query(`
//           INSERT INTO Cart (userId, productId, quantity)
//           VALUES (@userId, @productId, @quantity)
//         `);

//       return res.json({ message: "✅ Item added to cart" });
//     }
//   } catch (err) {
//     console.error("❌ SQL Error adding to cart:", err);
//     res.status(500).json({ error: "Failed to add to cart" });
//   }
// });

// // ============================
// // ❌ DELETE: Remove Cart Item by Cart ID
// // ============================
// router.delete("/remove/:cartId", async (req, res) => {
//   try {
//     const { cartId } = req.params;
//     const pool = await poolPromise;

//     await pool.request()
//       .input("cartId", sql.Int, cartId)
//       .query("DELETE FROM Cart WHERE id = @cartId");

//     res.json({ message: "✅ Item removed from cart" });
//   } catch (err) {
//     console.error("❌ Error removing cart item:", err);
//     res.status(500).json({ error: "Failed to remove item" });
//   }
// });

// // ============================
// // 🔄 PUT: Update Cart Quantity
// // ============================
// router.put("/update", async (req, res) => {
//   try {
//     const { cartId, quantity } = req.body;

//     if (!cartId || quantity == null) {
//       return res.status(400).json({ error: "cartId and quantity are required" });
//     }

//     const pool = await poolPromise;
//     await pool.request()
//       .input("cartId", sql.Int, cartId)
//       .input("quantity", sql.Int, quantity)
//       .query(`
//         UPDATE Cart
//         SET quantity = @quantity
//         WHERE id = @cartId
//       `);

//     res.json({ message: "✅ Cart quantity updated successfully" });
//   } catch (err) {
//     console.error("❌ Error updating cart quantity:", err);
//     res.status(500).json({ error: "Failed to update cart quantity" });
//   }
// });

// module.exports = router;
