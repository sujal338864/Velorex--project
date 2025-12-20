// controllers/productController.js
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

// ============================
// GET ALL PRODUCTS
// ============================
exports.getAllProducts = async (req, res) => {
  try {
    const result = await pool.query(`SELECT * FROM "Products"`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Fetch Products Error:", err);
    res.status(500).send("Server error");
  }
};

// ============================
// CREATE PRODUCT
// ============================
exports.createProduct = async (req, res) => {
  const { name, desc, price, mobileno, image } = req.body;

  try {
    await pool.query(
      `
      INSERT INTO "Products" ("Name","Desc","Price","MobileNo","Image")
      VALUES ($1,$2,$3,$4,$5)
    `,
      [name, desc, price, mobileno, image]
    );

    res.status(201).send("Product created");
  } catch (err) {
    console.error("❌ Create Product Error:", err);
    res.status(500).send("Server error");
  }
};

// ============================
// UPDATE PRODUCT
// ============================
exports.updateProduct = async (req, res) => {
  const { id } = req.params;
  const { name, desc, price, mobileno, image } = req.body;

  try {
    await pool.query(
      `
      UPDATE "Products"
      SET "Name"=$1, "Desc"=$2, "Price"=$3, "MobileNo"=$4, "Image"=$5
      WHERE "ProductID"=$6
    `,
      [name, desc, price, mobileno, image, id]
    );

    res.send("Product updated");
  } catch (err) {
    console.error("❌ Update Product Error:", err);
    res.status(500).send("Server error");
  }
};

// ============================
// DELETE PRODUCT
// ============================
exports.deleteProduct = async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query(
      `DELETE FROM "Products" WHERE "ProductID"=$1`,
      [id]
    );

    res.send("Product deleted");
  } catch (err) {
    console.error("❌ Delete Product Error:", err);
    res.status(500).send("Server error");
  }
};




// // controllers/productController.js
// const db = require('../models/db');

// exports.getAllProducts = async (req, res) => {
//   try {
//     const result = await db.query`SELECT * FROM Products`;
//     res.json(result.recordset);
//   } catch (err) {
//     console.error(err);
//     res.status(500).send('Server error');
//   }
// };

// exports.createProduct = async (req, res) => {
//   const { name, desc, price, mobileno, image } = req.body;
//   try {
//     await db.query`
//       INSERT INTO Products (name, desc, price, mobileno, image)
//       VALUES (${name}, ${desc}, ${price}, ${mobileno}, ${image})
//     `;
//     res.status(201).send('Product created');
//   } catch (err) {
//     console.error(err);
//     res.status(500).send('Server error');
//   }
// };

// exports.updateProduct = async (req, res) => {
//   const { id } = req.params;
//   const { name, desc, price, mobileno, image } = req.body;
//   try {
//     await db.query`
//       UPDATE Products
//       SET name = ${name}, desc = ${desc}, price = ${price}, mobileno = ${mobileno}, image = ${image}
//       WHERE id = ${id}
//     `;
//     res.send('Product updated');
//   } catch (err) {
//     console.error(err);
//     res.status(500).send('Server error');
//   }
// };

// exports.deleteProduct = async (req, res) => {
//   const { id } = req.params;
//   try {
//     await db.query`
//       DELETE FROM Products WHERE id = ${id}
//     `;
//     res.send('Product deleted');
//   } catch (err) {
//     console.error(err);
//     res.status(500).send('Server error');
//   }
// };
