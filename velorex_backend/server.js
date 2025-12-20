require("dotenv").config();
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// 🔥 PostgreSQL (Supabase) Pool
const pgPool = require("./models/db");

const app = express();
const PORT = 3000;

// ========================
// Middlewares
// ========================
app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// ========================
// Uploads Handling
// ========================
const uploadDir = path.join(__dirname, "uploads", "products");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) =>
    cb(null, `${Date.now()}${path.extname(file.originalname)}`),
});

const upload = multer({ storage });

// ========================
// DB Status Check
// ========================
pgPool
  .connect()
  .then(() => console.log("🟢 Connected to Supabase PostgreSQL"))
  .catch((err) => console.error("🔥 PostgreSQL connection failed:", err));

// ========================
// Routes
// ========================
const otpAuthRoutes = require("./routes/userAuth");
const otpRoutes = require("./routes/otpRoutes");
const profileRoutes = require("./routes/profile");
const userRoutes = require("./routes/users");
const productRoutes = require("./routes/products");
const userSubcategoryRoutes = require("./routes/user_subcategory");
const postersRoutes = require("./routes/posters");
const wishlistRoutes = require("./routes/wishlist");
const cartRoutes = require("./routes/cart");
const recentlyViewedRoutes = require("./routes/recentlyViewedRoutes");
const savedForLaterRoutes = require("./routes/savedForLater");
const paymentRoutes = require("./routes/payment");
const orderRoutes = require("./routes/orders");
const orderDetailsRoutes = require("./routes/orderDetails");
const addressRoutes = require("./routes/address");
const notificationsRoutes = require("./routes/notifications");
const productRatingsRoutes = require("./routes/productRatings");
const couponsRoutes = require("./routes/coupons");

// ========================
// Use Routes
// ========================
app.use("/api/auth", otpAuthRoutes);
app.use("/api", otpRoutes);

app.use("/api/profile", profileRoutes);
app.use("/api/users", userRoutes);

app.use("/api/products", productRoutes);
app.use("/api", userSubcategoryRoutes);

app.use("/api/posters", postersRoutes);
app.use("/api/wishlist", wishlistRoutes);
app.use("/api/cart", cartRoutes);
app.use("/api/recentlyviewed", recentlyViewedRoutes);
app.use("/api/savedforlater", savedForLaterRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/address", addressRoutes);

app.use("/api/orders", orderRoutes);
app.use("/api/orders", orderDetailsRoutes);

app.use("/api/notifications", notificationsRoutes);
app.use("/api", productRatingsRoutes);
app.use("/api/coupons", couponsRoutes);

// ========================
// Root Route
// ========================
app.get("/", (req, res) => {
  res.send("🩵 Velorex Backend API is Running Successfully!");
});

// ========================
// Start Server
// ========================
app.listen(PORT, "0.0.0.0", () => {
  console.log(
    `🩵 Velorex User Backend is Running on http://10.248.214.36:${PORT}`
  );
});


// require('dotenv').config();
// const express = require('express');
// const cors = require('cors');
// const bodyParser = require('body-parser');
// const multer = require('multer');
// const path = require('path');
// const fs = require('fs');

// const app = express();
// const PORT = 3000;

// // require('dotenv').config();
// // const express = require('express');
// // const cors = require('cors');
// // const bodyParser = require('body-parser');
// // const multer = require('multer');
// // const path = require('path');
// // const fs = require('fs');
// // const sql = require('mssql');

// // const app = express();
// // const PORT = 3000;

// app.use(cors());
// app.use(express.json());
// app.use(bodyParser.json());
// app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// const uploadDir = path.join(__dirname, 'uploads', 'products');

// if (!fs.existsSync(uploadDir)) {
//   fs.mkdirSync(uploadDir, { recursive: true });
// }

// const storage = multer.diskStorage({
//   destination: (_, __, cb) => cb(null, uploadDir),
//   filename: (_, file, cb) =>
//     cb(null, `${Date.now()}${path.extname(file.originalname)}`)
// });
// const upload = multer({ storage });

// const dbConfig = {
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD,
//   server: process.env.DB_SERVER,
//   database: process.env.DB_DATABASE,
//   port: parseInt(process.env.DB_PORT, 10),
//   options: { encrypt: false, trustServerCertificate: true },
// };

// // const poolPromise = new sql.ConnectionPool(dbConfig)
// //   .connect()
// //   .then(pool => {
// //     console.log('✅ Connected to SQL Server');
// //     return pool;
// //   })
// //   .catch(err => {
// //     console.error('❌ Database connection failed:', err);
// //     process.exit(1);
// //   });

// // Quick test
// // sql.connect(dbConfig)
// //   .then(() => console.log('✅ DB connected'))
// //   .catch(err => console.error('❌ DB connection failed:', err));

// // =====================================================
// // 📦 Route Imports
// // =====================================================
// const otpAuthRoutes         = require('./routes/userAuth');
// const otpRoutes             = require('./routes/otpRoutes');
// const profileRoutes         = require('./routes/profile');
// const userRoutes            = require('./routes/users');
// const productRoutes         = require('./routes/products');
// const userSubcategoryRoutes = require('./routes/user_subcategory');
// const postersRoutes         = require('./routes/posters');
// const wishlistRoutes        = require('./routes/wishlist');
// const cartRoutes            = require('./routes/cart');
// const recentlyViewedRoutes  = require('./routes/recentlyViewedRoutes');
// const savedForLaterRoutes   = require('./routes/savedForLater');
// const paymentRoutes         = require('./routes/payment');
// const orderRoutes = require("./routes/orders");
// const orderDetailsRoutes = require("./routes/orderDetails");
// const addressRoutes = require('./routes/address'); 
// // =====================================================
// // 🚦 Route Usage
// // =====================================================

// app.use('/api/auth', otpAuthRoutes);
// app.use('/api', otpRoutes);

// app.use('/api/profile', profileRoutes);
// app.use('/api/users', userRoutes);

// app.use('/api/products', productRoutes);

// app.use('/api', userSubcategoryRoutes);

// app.use('/api/posters', postersRoutes);
// app.use('/api/wishlist', wishlistRoutes);
// app.use('/api/cart', cartRoutes);
// app.use('/api/recentlyviewed', recentlyViewedRoutes);
// app.use('/api/savedforlater', savedForLaterRoutes);
// app.use('/api/payments', paymentRoutes);
// app.use('/api/address', addressRoutes);
// app.use("/api/orders", orderRoutes);
// app.use("/api/orders", orderDetailsRoutes); 

// const userNotificationsRoutes = require('./routes/notifications');
// app.use('/api/notifications', userNotificationsRoutes);

// const productRatingsRoutes = require("./routes/productRatings");

// app.use("/api", productRatingsRoutes);
// app.use('/api/coupons', require('./routes/coupons'));




// app.get('/', (req, res) => {
//   res.send('🩵 Velorex Backend API is Running Successfully!');
// });

// // ✅ Start server
// app.listen(PORT, '0.0.0.0', () => {
//   console.log(`🩵 Velorex User Backend is Running on http://10.248.214.36:${PORT}`);
// });





// require('dotenv').config();
// const express = require('express');
// const cors = require('cors');
// const bodyParser = require('body-parser');
// const multer = require('multer');
// const path = require('path');
// const fs = require('fs');
// const sql = require('mssql');

// const app = express();
// const PORT = 3000;

// app.use(cors());
// app.use(express.json());
// app.use(bodyParser.json());
// app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// const uploadDir = path.join(__dirname, 'uploads', 'products');

// if (!fs.existsSync(uploadDir)) {
//   fs.mkdirSync(uploadDir, { recursive: true });
// }

// const storage = multer.diskStorage({
//   destination: (_, __, cb) => cb(null, uploadDir),
//   filename: (_, file, cb) =>
//     cb(null, `${Date.now()}${path.extname(file.originalname)}`)
// });
// const upload = multer({ storage });

// const dbConfig = {
//   user: process.env.DB_USER,
//   password: process.env.DB_PASSWORD,
//   server: process.env.DB_SERVER,
//   database: process.env.DB_DATABASE,
//   port: parseInt(process.env.DB_PORT, 10),
//   options: { encrypt: false, trustServerCertificate: true },
// };

// const poolPromise = new sql.ConnectionPool(dbConfig)
//   .connect()
//   .then(pool => {
//     console.log('✅ Connected to SQL Server');
//     return pool;
//   })
//   .catch(err => {
//     console.error('❌ Database connection failed:', err);
//     process.exit(1);
//   });

// // Quick test
// sql.connect(dbConfig)
//   .then(() => console.log('✅ DB connected'))
//   .catch(err => console.error('❌ DB connection failed:', err));

// // =====================================================
// // 📦 Route Imports
// // =====================================================
// const otpAuthRoutes         = require('./routes/userAuth');
// const otpRoutes             = require('./routes/otpRoutes');
// const profileRoutes         = require('./routes/profile');
// const userRoutes            = require('./routes/users');
// const productRoutes         = require('./routes/products');
// const userSubcategoryRoutes = require('./routes/user_subcategory');
// const postersRoutes         = require('./routes/posters');
// const wishlistRoutes        = require('./routes/wishlist');
// const cartRoutes            = require('./routes/cart');
// const recentlyViewedRoutes  = require('./routes/recentlyViewedRoutes');
// const savedForLaterRoutes   = require('./routes/savedForLater');
// const paymentRoutes         = require('./routes/payment');
// const orderRoutes = require("./routes/orders");
// const orderDetailsRoutes = require("./routes/orderDetails");
// const addressRoutes = require('./routes/address'); 
// // =====================================================
// // 🚦 Route Usage
// // =====================================================

// app.use('/api/auth', otpAuthRoutes);
// app.use('/api', otpRoutes);

// app.use('/api/profile', profileRoutes);
// app.use('/api/users', userRoutes);

// app.use('/api/products', productRoutes);

// app.use('/api', userSubcategoryRoutes);

// app.use('/api/posters', postersRoutes);
// app.use('/api/wishlist', wishlistRoutes);
// app.use('/api/cart', cartRoutes);
// app.use('/api/recentlyviewed', recentlyViewedRoutes);
// app.use('/api/savedforlater', savedForLaterRoutes);
// app.use('/api/payments', paymentRoutes);
// app.use('/api/address', addressRoutes);
// app.use("/api/orders", orderRoutes);
// app.use("/api/orders", orderDetailsRoutes); 

// const userNotificationsRoutes = require('./routes/notifications');
// app.use('/api/notifications', userNotificationsRoutes);

// const productRatingsRoutes = require("./routes/productRatings");

// app.use("/api", productRatingsRoutes);
// app.use('/api/coupons', require('./routes/coupons'));




// app.get('/', (req, res) => {
//   res.send('🩵 Velorex Backend API is Running Successfully!');
// });

// // ✅ Start server
// app.listen(PORT, '0.0.0.0', () => {
//   console.log(`🩵 Velorex User Backend is Running on http://10.248.214.36:${PORT}`);
// });


