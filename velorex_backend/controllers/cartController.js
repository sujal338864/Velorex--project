// controllers/cartController.js
const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  host: process.env.SUPABASE_DB_HOST,
  port: Number(process.env.SUPABASE_DB_PORT),
  user: process.env.SUPABASE_DB_USER,
  password: process.env.SUPABASE_DB_PASSWORD,
  database: process.env.SUPABASE_DB_NAME,
  ssl: { rejectUnauthorized: false },
  max: 3,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// ======================================
// 🛒 GET USER CART
// ======================================
exports.getCart = async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await pool.query(
      `
      SELECT 
        c.id,
        c.product_id,
        c.quantity,
        p.product_id,
        p.name,
        p.price,
        p.offer_price,
        (
          SELECT image_url 
          FROM product_images 
          WHERE product_id = p.product_id 
          LIMIT 1
        ) AS image_url
      FROM cart c
      JOIN products p ON c.product_id = p.product_id
      WHERE c.user_id = $1
      ORDER BY c.id DESC
      `,
      [userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("❌ getCart error:", err);
    res.status(500).send("Error fetching cart");
  }
};



// ======================================
// ➕ ADD / UPDATE CART
// ======================================
exports.addToCart = async (req, res) => {
  try {
    const { userId, productId, quantity = 1 } = req.body;

    const check = await pool.query(
      `SELECT quantity FROM cart WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    if (check.rows.length > 0) {
      await pool.query(
        `UPDATE cart 
         SET quantity = quantity + $1 
         WHERE user_id = $2 AND product_id = $3`,
        [quantity, userId, productId]
      );
    } else {
      await pool.query(
        `INSERT INTO cart(user_id, product_id, quantity)
         VALUES($1,$2,$3)`,
        [userId, productId, quantity]
      );
    }

    res.send("✅ Product added/updated in cart");
  } catch (err) {
    console.error("❌ addToCart error:", err);
    res.status(500).send("Error adding to cart");
  }
};



// ======================================
// ❌ REMOVE ONE QTY OR DELETE
// ======================================
exports.removeFromCart = async (req, res) => {
  try {
    const { userId, productId } = req.params;

    const existing = await pool.query(
      `SELECT quantity FROM cart 
       WHERE user_id = $1 AND product_id = $2`,
      [userId, productId]
    );

    if (existing.rows.length === 0)
      return res.status(404).send("Item not found in cart");

    const qty = existing.rows[0].quantity;

    if (qty > 1) {
      await pool.query(
        `UPDATE cart 
         SET quantity = quantity - 1
         WHERE user_id = $1 AND product_id = $2`,
        [userId, productId]
      );
    } else {
      await pool.query(
        `DELETE FROM cart 
         WHERE user_id = $1 AND product_id = $2`,
        [userId, productId]
      );
    }

    res.send("✅ Item updated/removed from cart");
  } catch (err) {
    console.error("❌ removeFromCart error:", err);
    res.status(500).send("Error removing from cart");
  }
};



// ======================================
// 🧹 CLEAR CART
// ======================================
exports.clearCart = async (req, res) => {
  try {
    const { userId } = req.params;

    await pool.query(
      `DELETE FROM cart WHERE user_id = $1`,
      [userId]
    );

    res.send("🧹 Cart cleared");
  } catch (err) {
    console.error("❌ clearCart error:", err);
    res.status(500).send("Error clearing cart");
  }
};




// const { sql, poolPromise } = require("../db");

// exports.getCart = async (req, res) => {
//   try {
//     const { userId } = req.params;
//     const pool = await poolPromise;
//     const result = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query(`
//         SELECT c.id, c.productId, c.quantity, p.name, p.price, p.image 
//         FROM Cart c 
//         JOIN Products p ON c.productId = p.ProductId 
//         WHERE c.userId = @userId
//       `);
//     res.json(result.recordset);
//   } catch (err) {
//     console.error("❌ getCart error:", err);
//     res.status(500).send("Error fetching cart");
//   }
// };

// exports.addToCart = async (req, res) => {
//   try {
//     const { userId, productId, quantity } = req.body;
//     const pool = await poolPromise;

//     // Check if already exists
//     const check = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query("SELECT * FROM Cart WHERE userId = @userId AND productId = @productId");

//     if (check.recordset.length > 0) {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("productId", sql.Int, productId)
//         .input("quantity", sql.Int, quantity || 1)
//         .query("UPDATE Cart SET quantity = quantity + @quantity WHERE userId = @userId AND productId = @productId");
//     } else {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("productId", sql.Int, productId)
//         .input("quantity", sql.Int, quantity || 1)
//         .query("INSERT INTO Cart (userId, productId, quantity) VALUES (@userId, @productId, @quantity)");
//     }

//     res.send("✅ Product added/updated in cart");
//   } catch (err) {
//     console.error("❌ addToCart error:", err);
//     res.status(500).send("Error adding to cart");
//   }
// };

// exports.removeFromCart = async (req, res) => {
//   try {
//     const { userId, productId } = req.params;
//     const pool = await poolPromise;

//     // Get current quantity
//     const existing = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("productId", sql.Int, productId)
//       .query("SELECT quantity FROM Cart WHERE userId = @userId AND productId = @productId");

//     if (existing.recordset.length === 0) {
//       return res.status(404).send("Item not found in cart");
//     }

//     const quantity = existing.recordset[0].quantity;
//     if (quantity > 1) {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("productId", sql.Int, productId)
//         .query("UPDATE Cart SET quantity = quantity - 1 WHERE userId = @userId AND productId = @productId");
//     } else {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("productId", sql.Int, productId)
//         .query("DELETE FROM Cart WHERE userId = @userId AND productId = @productId");
//     }

//     res.send("✅ Item updated/removed from cart");
//   } catch (err) {
//     console.error("❌ removeFromCart error:", err);
//     res.status(500).send("Error removing from cart");
//   }
// };

// exports.clearCart = async (req, res) => {
//   try {
//     const { userId } = req.params;
//     const pool = await poolPromise;

//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query("DELETE FROM Cart WHERE userId = @userId");

//     res.send("🧹 Cart cleared");
//   } catch (err) {
//     console.error("❌ clearCart error:", err);
//     res.status(500).send("Error clearing cart");
//   }
// };
