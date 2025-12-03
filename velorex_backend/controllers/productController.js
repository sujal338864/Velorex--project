
// controllers/productController.js
const db = require('../models/db');

exports.getAllProducts = async (req, res) => {
  try {
    const result = await db.query`SELECT * FROM Products`;
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
};

exports.createProduct = async (req, res) => {
  const { name, desc, price, mobileno, image } = req.body;
  try {
    await db.query`
      INSERT INTO Products (name, desc, price, mobileno, image)
      VALUES (${name}, ${desc}, ${price}, ${mobileno}, ${image})
    `;
    res.status(201).send('Product created');
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
};

exports.updateProduct = async (req, res) => {
  const { id } = req.params;
  const { name, desc, price, mobileno, image } = req.body;
  try {
    await db.query`
      UPDATE Products
      SET name = ${name}, desc = ${desc}, price = ${price}, mobileno = ${mobileno}, image = ${image}
      WHERE id = ${id}
    `;
    res.send('Product updated');
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
};

exports.deleteProduct = async (req, res) => {
  const { id } = req.params;
  try {
    await db.query`
      DELETE FROM Products WHERE id = ${id}
    `;
    res.send('Product deleted');
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
};
