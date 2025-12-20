const express = require("express");
const router = express.Router();
const pool = require("../models/db");

// ======================================================
// USER PROFILE ROUTES
// ======================================================

// CREATE USER + PROFILE ADDRESS
router.post("/", async (req, res) => {
  try {
    const {
      userId,
      email,
      name,
      mobile,
      address,
      city,
      state,
      country,
      pincode
    } = req.body;

    if (!userId || !email)
      return res.status(400).json({ success: false, message: "userId & email required" });

    // check if exists
    const existing = await pool.query(
      `SELECT user_id FROM users WHERE user_id = $1`,
      [userId]
    );

    if (existing.rows.length > 0) {
      return res.status(200).json({ message: "User already exists", userId });
    }

    // insert user
    await pool.query(
      `
      INSERT INTO users (
        user_id, email, name, mobile,
        address, city, state, country, pincode
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      `,
      [
        userId,
        email,
        name || null,
        mobile || null,
        address || null,
        city || null,
        state || null,
        country || null,
        pincode || null
      ]
    );

    // insert profile address
    await pool.query(
      `
      INSERT INTO shipping_addresses (
        user_id, address, city, state,
        country, pincode, phone
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7)
      `,
      [userId, address, city, state, country, pincode, mobile || null]
    );

    res.status(201).json({
      success: true,
      message: "User + profile address created",
      userId
    });
  } catch (err) {
    console.error("create profile error", err);
    res.status(500).json({ success: false, message: err.message });
  }
});


// GET USER PROFILE
router.get("/:userId", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM users WHERE user_id = $1`,
      [req.params.userId]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ message: "User not found" });

    res.json(result.rows[0]);
  } catch (err) {
    console.error("get profile error", err);
    res.status(500).json({ message: err.message });
  }
});


// UPDATE PROFILE + SYNC ADDRESS
router.put("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      name,
      email,
      mobile,
      address,
      city,
      state,
      country,
      pincode
    } = req.body;

    // update user table
    await pool.query(
      `
      UPDATE users
      SET name=$1, email=$2, mobile=$3,
          address=$4, city=$5, state=$6,
          country=$7, pincode=$8,
          updated_at = NOW()
      WHERE user_id=$9
      `,
      [name, email, mobile, address, city, state, country, pincode, userId]
    );

    // check if a shipping profile exists
    const exists = await pool.query(
      `
      SELECT shipping_id
      FROM shipping_addresses
      WHERE user_id = $1
      ORDER BY shipping_id ASC
      LIMIT 1
      `,
      [userId]
    );

    if (exists.rows.length > 0) {
      // update existing shipping address
      await pool.query(
        `
        UPDATE shipping_addresses
        SET address=$1, city=$2, state=$3,
            country=$4, pincode=$5, phone=$6
        WHERE shipping_id=$7
        `,
        [
          address,
          city,
          state,
          country,
          pincode,
          mobile,
          exists.rows[0].shipping_id
        ]
      );
    } else {
      // create new
      await pool.query(
        `
        INSERT INTO shipping_addresses (
          user_id, address, city, state,
          country, pincode, phone
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7)
        `,
        [userId, address, city, state, country, pincode, mobile]
      );
    }

    res.json({
      success: true,
      message: "Profile + address synced successfully"
    });
  } catch (err) {
    console.error("update profile error", err);
    res.status(500).json({ message: err.message });
  }
});


// GET USER ADDRESSES
router.get("/:userId/addresses", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT 
        shipping_id,
        address,
        city,
        state,
        country,
        pincode,
        phone
      FROM shipping_addresses
      WHERE user_id = $1
      ORDER BY shipping_id DESC
      `,
      [req.params.userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error("get addresses error", err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;




// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");

// // ======================================================
// // 👤 USER PROFILE ROUTES
// // ======================================================

// // ✅ Create or Sync user profile
// router.post("/", async (req, res) => {
//   try {
//     const { userId, email, name, mobile, address, city, state, country, pincode } = req.body;
//     const pool = await poolPromise;

//     const existing = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query("SELECT userId FROM Users WHERE userId = @userId");

//     if (existing.recordset.length > 0) {
//       return res.status(200).json({ message: "User already exists", userId });
//     }

//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("email", sql.NVarChar, email)
//       .input("name", sql.NVarChar, name)
//       .input("mobile", sql.NVarChar, mobile)
//       .input("address", sql.NVarChar, address)
//       .input("city", sql.NVarChar, city)
//       .input("state", sql.NVarChar, state)
//       .input("country", sql.NVarChar, country)
//       .input("pincode", sql.NVarChar, pincode)
//       .query(`
//         INSERT INTO Users (userId, email, name, mobile, address, city, state, country, pincode)
//         VALUES (@userId, @email, @name, @mobile, @address, @city, @state, @country, @pincode)
//       `);

//     // ✅ Also insert into Addresses table (as profile address)
//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("name", sql.NVarChar, name)
//       .input("mobile", sql.NVarChar, mobile)
//       .input("address", sql.NVarChar, address)
//       .input("city", sql.NVarChar, city)
//       .input("state", sql.NVarChar, state)
//       .input("country", sql.NVarChar, country)
//       .input("pincode", sql.NVarChar, pincode)
//       .input("isDefault", sql.Bit, 1)
//       .input("isProfileAddress", sql.Bit, 1)
//       .query(`
//         INSERT INTO Addresses (UserID, Name, Mobile, Address, City, State, Country, Pincode, IsDefault, IsProfileAddress)
//         VALUES (@userId, @name, @mobile, @address, @city, @state, @country, @pincode, @isDefault, @isProfileAddress)
//       `);

//     res.status(201).json({ success: true, message: "✅ User and profile address created successfully", userId });
//   } catch (err) {
//     console.error("❌ Error creating user profile:", err);
//     res.status(500).json({ success: false, message: "Failed to create user", error: err.message });
//   }
// });


// // ✅ Get user profile
// router.get("/:userId", async (req, res) => {
//   try {
//     const { userId } = req.params;
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query("SELECT * FROM Users WHERE userId = @userId");

//     if (result.recordset.length === 0)
//       return res.status(404).json({ message: "User not found" });

//     res.json(result.recordset[0]);
//   } catch (err) {
//     console.error("❌ Error fetching profile:", err);
//     res.status(500).json({ message: "Failed to get profile", error: err.message });
//   }
// });


// // ✅ Update user profile (and sync to address)
// router.put("/:userId", async (req, res) => {
//   try {
//     const { userId } = req.params;
//     const { name, email, mobile, address, city, state, country, pincode } = req.body;
//     const pool = await poolPromise;

//     // 1️⃣ Update profile table
//     await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .input("name", sql.NVarChar, name)
//       .input("email", sql.NVarChar, email)
//       .input("mobile", sql.NVarChar, mobile)
//       .input("address", sql.NVarChar, address)
//       .input("city", sql.NVarChar, city)
//       .input("state", sql.NVarChar, state)
//       .input("country", sql.NVarChar, country)
//       .input("pincode", sql.NVarChar, pincode)
//       .query(`
//         UPDATE Users SET
//           name=@name, email=@email, mobile=@mobile,
//           address=@address, city=@city, state=@state,
//           country=@country, pincode=@pincode
//         WHERE userId=@userId
//       `);

//     // 2️⃣ Sync to address table
//     const exists = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query("SELECT 1 FROM Addresses WHERE UserID=@userId AND IsProfileAddress=1");

//     if (exists.recordset.length > 0) {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("name", sql.NVarChar, name)
//         .input("mobile", sql.NVarChar, mobile)
//         .input("address", sql.NVarChar, address)
//         .input("city", sql.NVarChar, city)
//         .input("state", sql.NVarChar, state)
//         .input("country", sql.NVarChar, country)
//         .input("pincode", sql.NVarChar, pincode)
//         .query(`
//           UPDATE Addresses
//           SET Name=@name, Mobile=@mobile, Address=@address,
//               City=@city, State=@state, Country=@country, Pincode=@pincode
//           WHERE UserID=@userId AND IsProfileAddress=1
//         `);
//     } else {
//       await pool.request()
//         .input("userId", sql.NVarChar, userId)
//         .input("name", sql.NVarChar, name)
//         .input("mobile", sql.NVarChar, mobile)
//         .input("address", sql.NVarChar, address)
//         .input("city", sql.NVarChar, city)
//         .input("state", sql.NVarChar, state)
//         .input("country", sql.NVarChar, country)
//         .input("pincode", sql.NVarChar, pincode)
//         .input("isDefault", sql.Bit, 1)
//         .input("isProfileAddress", sql.Bit, 1)
//         .query(`
//           INSERT INTO Addresses (UserID, Name, Mobile, Address, City, State, Country, Pincode, IsDefault, IsProfileAddress)
//           VALUES (@userId, @name, @mobile, @address, @city, @state, @country, @pincode, @isDefault, @isProfileAddress)
//         `);
//     }

//     res.json({ success: true, message: "✅ Profile and address synced successfully" });
//   } catch (err) {
//     console.error("❌ Error updating profile:", err);
//     res.status(500).json({ message: "Failed to update profile", error: err.message });
//   }
// });


// // ✅ Get all addresses (always includes profile address)
// router.get("/:userId/addresses", async (req, res) => {
//   try {
//     const { userId } = req.params;
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("userId", sql.NVarChar, userId)
//       .query(`
//         SELECT AddressID, Name, Mobile, Address, City, State, Country, Pincode, IsDefault, IsProfileAddress
//         FROM Addresses WHERE UserID=@userId
//         ORDER BY IsDefault DESC, AddressID DESC
//       `);

//     res.json(result.recordset);
//   } catch (err) {
//     console.error("❌ Error fetching addresses:", err);
//     res.status(500).json({ message: "Failed to get addresses", error: err.message });
//   }
// });

// module.exports = router;
