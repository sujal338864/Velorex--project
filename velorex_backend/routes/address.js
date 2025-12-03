const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// ✅ GET all addresses for a specific user
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const pool = await poolPromise;

    const result = await pool.request()
      .input("UserID", sql.VarChar, userId)
      .query(`
        SELECT * FROM Addresses 
        WHERE UserID = @UserID 
        ORDER BY isDefault DESC, createdAt DESC
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json([]);
    }

    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Error fetching addresses:", err);
    res.status(500).json({ message: "Error fetching addresses" });
  }
});

// ✅ POST: Add new address
router.post("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { name, address, city, state, country, pincode } = req.body;

    const pool = await poolPromise;

    await pool.request()
      .input("UserID", sql.NVarChar, userId)
      .input("Name", sql.NVarChar, name)
      .input("Address", sql.NVarChar, address)
      .input("City", sql.NVarChar, city)
      .input("State", sql.NVarChar, state)
      .input("Country", sql.NVarChar, country)
      .input("Pincode", sql.NVarChar, pincode)
      .query(`
        INSERT INTO Addresses (UserID, Name, Address, City, State, Country, Pincode)
        VALUES (@UserID, @Name, @Address, @City, @State, @Country, @Pincode)
      `);

    res.status(201).json({ message: "Address added successfully" });
  } catch (err) {
    console.error("❌ Error adding address:", err);
    res.status(500).json({ error: "Failed to add address" });
  }
});

// ✅ POST: Add new address
router.post("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      name,
      mobile,
      address,
      city,
      state,
      country,
      pincode,
      isDefault = 0,
      isProfileAddress = 0,
    } = req.body;

    const pool = await poolPromise;

    await pool.request()
      .input("UserID", sql.NVarChar, userId)
      .input("Name", sql.NVarChar, name)
      .input("Mobile", sql.NVarChar, mobile)
      .input("Address", sql.NVarChar, address)
      .input("City", sql.NVarChar, city)
      .input("State", sql.NVarChar, state)
      .input("Country", sql.NVarChar, country)
      .input("Pincode", sql.NVarChar, pincode)
      .input("IsDefault", sql.Bit, isDefault)
      .input("IsProfileAddress", sql.Bit, isProfileAddress)
      .query(`
        INSERT INTO Addresses
        (UserID, Name, Mobile, Address, City, State, Country, Pincode, IsDefault, IsProfileAddress, CreatedAt)
        VALUES (@UserID, @Name, @Mobile, @Address, @City, @State, @Country, @Pincode, @IsDefault, @IsProfileAddress, GETDATE())
      `);

    res.status(201).json({ message: "✅ Address added successfully" });
  } catch (err) {
    console.error("❌ Error adding address:", err);
    res.status(500).json({ error: "Failed to add address" });
  }
});

// ✅ DELETE address
router.delete("/:addressId", async (req, res) => {
  try {
    const { addressId } = req.params;
    const pool = await poolPromise;

    await pool.request()
      .input("AddressID", sql.Int, addressId)
      .query("DELETE FROM Addresses WHERE AddressID=@AddressID");

    res.status(200).json({ message: "Address deleted successfully" });
  } catch (err) {
    console.error("❌ Error deleting address:", err);
    res.status(500).json({ error: "Failed to delete address" });
  }
});

module.exports = router;
