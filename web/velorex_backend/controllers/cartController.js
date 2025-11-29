const { sql, poolPromise } = require("../db");

exports.getCart = async (req, res) => {
  try {
    const { userId } = req.params;
    const pool = await poolPromise;
    const result = await pool.request()
      .input("userId", sql.NVarChar, userId)
      .query(`
        SELECT c.id, c.productId, c.quantity, p.name, p.price, p.image 
        FROM Cart c 
        JOIN Products p ON c.productId = p.ProductId 
        WHERE c.userId = @userId
      `);
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ getCart error:", err);
    res.status(500).send("Error fetching cart");
  }
};

exports.addToCart = async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;
    const pool = await poolPromise;

    // Check if already exists
    const check = await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query("SELECT * FROM Cart WHERE userId = @userId AND productId = @productId");

    if (check.recordset.length > 0) {
      await pool.request()
        .input("userId", sql.NVarChar, userId)
        .input("productId", sql.Int, productId)
        .input("quantity", sql.Int, quantity || 1)
        .query("UPDATE Cart SET quantity = quantity + @quantity WHERE userId = @userId AND productId = @productId");
    } else {
      await pool.request()
        .input("userId", sql.NVarChar, userId)
        .input("productId", sql.Int, productId)
        .input("quantity", sql.Int, quantity || 1)
        .query("INSERT INTO Cart (userId, productId, quantity) VALUES (@userId, @productId, @quantity)");
    }

    res.send("✅ Product added/updated in cart");
  } catch (err) {
    console.error("❌ addToCart error:", err);
    res.status(500).send("Error adding to cart");
  }
};

exports.removeFromCart = async (req, res) => {
  try {
    const { userId, productId } = req.params;
    const pool = await poolPromise;

    // Get current quantity
    const existing = await pool.request()
      .input("userId", sql.NVarChar, userId)
      .input("productId", sql.Int, productId)
      .query("SELECT quantity FROM Cart WHERE userId = @userId AND productId = @productId");

    if (existing.recordset.length === 0) {
      return res.status(404).send("Item not found in cart");
    }

    const quantity = existing.recordset[0].quantity;
    if (quantity > 1) {
      await pool.request()
        .input("userId", sql.NVarChar, userId)
        .input("productId", sql.Int, productId)
        .query("UPDATE Cart SET quantity = quantity - 1 WHERE userId = @userId AND productId = @productId");
    } else {
      await pool.request()
        .input("userId", sql.NVarChar, userId)
        .input("productId", sql.Int, productId)
        .query("DELETE FROM Cart WHERE userId = @userId AND productId = @productId");
    }

    res.send("✅ Item updated/removed from cart");
  } catch (err) {
    console.error("❌ removeFromCart error:", err);
    res.status(500).send("Error removing from cart");
  }
};

exports.clearCart = async (req, res) => {
  try {
    const { userId } = req.params;
    const pool = await poolPromise;

    await pool.request()
      .input("userId", sql.NVarChar, userId)
      .query("DELETE FROM Cart WHERE userId = @userId");

    res.send("🧹 Cart cleared");
  } catch (err) {
    console.error("❌ clearCart error:", err);
    res.status(500).send("Error clearing cart");
  }
};
