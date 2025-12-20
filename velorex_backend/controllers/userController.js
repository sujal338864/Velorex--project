const { Pool } = require("pg");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
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

// 🟢 Signup User
exports.signupUser = async (req, res) => {
  try {
    const { firstName, lastName, email, password, phone } = req.body;

    // Check if email exists
    const existing = await pool.query(
      `SELECT * FROM "Users" WHERE "Email" = $1`,
      [email]
    );

    if (existing.rows.length > 0) {
      return res.status(400).json({ message: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await pool.query(
      `
      INSERT INTO "Users" ("FirstName","LastName","Email","PasswordHash","Phone")
      VALUES ($1,$2,$3,$4,$5)
      `,
      [firstName, lastName, email, hashedPassword, phone || null]
    );

    res.json({ message: "Signup successful" });

  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// 🟢 Login User
exports.loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await pool.query(
      `SELECT * FROM "Users" WHERE "Email" = $1`,
      [email]
    );

    if (result.rows.length === 0)
      return res.status(400).json({ message: "Invalid email or password" });

    const user = result.rows[0];

    const isMatch = await bcrypt.compare(password, user.passwordhash);
    if (!isMatch)
      return res.status(400).json({ message: "Invalid password" });

    const token = jwt.sign(
      { userId: user.userid },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({
      message: "Login successful",
      token,
      user: {
        userId: user.userid,
        name: `${user.firstname} ${user.lastname}`,
        email: user.email,
      },
    });

  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// 🟢 Get User Profile
exports.getUser = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM "Users" WHERE "UserID" = $1`,
      [req.userId]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ message: "User not found" });

    res.json(result.rows[0]);

  } catch (err) {
    console.error("Get user error:", err);
    res.status(500).json({ message: "Server error" });
  }
};



// const sql = require("mssql");
// const bcrypt = require("bcryptjs");
// const jwt = require("jsonwebtoken");
// require("dotenv").config();

// const dbConfig = {
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD,
//   server: process.env.DB_SERVER,
//   database: process.env.DB_DATABASE,
//   port: parseInt(process.env.DB_PORT),
//   options: { encrypt: false, trustServerCertificate: true },
// };

// const poolPromise = new sql.ConnectionPool(dbConfig)
//   .connect()
//   .then(pool => pool)
//   .catch(err => console.error("Database connection failed:", err));

// // 🟢 Signup User
// exports.signupUser = async (req, res) => {
//   try {
//     const { firstName, lastName, email, password, phone } = req.body;
//     const pool = await poolPromise;

//     const existing = await pool.request()
//       .input("Email", sql.NVarChar, email)
//       .query("SELECT * FROM Users WHERE Email = @Email");

//     if (existing.recordset.length > 0) {
//       return res.status(400).json({ message: "Email already registered" });
//     }

//     const hashedPassword = await bcrypt.hash(password, 10);

//     await pool.request()
//       .input("FirstName", sql.NVarChar, firstName)
//       .input("LastName", sql.NVarChar, lastName)
//       .input("Email", sql.NVarChar, email)
//       .input("PasswordHash", sql.NVarChar, hashedPassword)
//       .input("Phone", sql.NVarChar, phone || null)
//       .query(`
//         INSERT INTO Users (FirstName, LastName, Email, PasswordHash, Phone)
//         VALUES (@FirstName, @LastName, @Email, @PasswordHash, @Phone)
//       `);

//     res.json({ message: "Signup successful" });
//   } catch (err) {
//     console.error("Signup error:", err);
//     res.status(500).json({ message: "Server error" });
//   }
// };

// // 🟢 Login User
// exports.loginUser = async (req, res) => {
//   try {
//     const { email, password } = req.body;
//     const pool = await poolPromise;

//     const result = await pool.request()
//       .input("Email", sql.NVarChar, email)
//       .query("SELECT * FROM Users WHERE Email = @Email");

//     if (result.recordset.length === 0)
//       return res.status(400).json({ message: "Invalid email or password" });

//     const user = result.recordset[0];
//     const isMatch = await bcrypt.compare(password, user.PasswordHash);

//     if (!isMatch)
//       return res.status(400).json({ message: "Invalid password" });

//     const token = jwt.sign({ userId: user.UserID }, process.env.JWT_SECRET, { expiresIn: "7d" });

//     res.json({
//       message: "Login successful",
//       token,
//       user: {
//         userId: user.UserID,
//         name: `${user.FirstName} ${user.LastName}`,
//         email: user.Email,
//       },
//     });
//   } catch (err) {
//     console.error("Login error:", err);
//     res.status(500).json({ message: "Server error" });
//   }
// };

// // 🟢 Get User Profile
// exports.getUser = async (req, res) => {
//   try {
//     const pool = await poolPromise;
//     const result = await pool.request()
//       .input("userId", sql.Int, req.userId)
//       .query("SELECT * FROM Users WHERE UserID = @userId");

//     if (result.recordset.length === 0)
//       return res.status(404).json({ message: "User not found" });

//     res.json(result.recordset[0]);
//   } catch (err) {
//     console.error("Get user error:", err);
//     res.status(500).json({ message: "Server error" });
//   }
// };
