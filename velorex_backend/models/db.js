const sql = require("mssql");
require("dotenv").config();

const sqlConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  port: parseInt(process.env.DB_PORT),
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
};

const poolPromise = new sql.ConnectionPool(sqlConfig)
  .connect()
  .then(pool => {
    console.log("✅ Connected to SQL Server:", process.env.DB_DATABASE);
    return pool;
  })
  .catch(err => {
    console.error("❌ Database Connection Failed:", err);
    throw err;  // instead of return null
  });


module.exports = { sql, poolPromise };

