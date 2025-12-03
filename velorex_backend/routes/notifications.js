const express = require("express");
const router = express.Router();
const { sql, poolPromise } = require("../models/db");

// ✅ GET user-specific + global notifications
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const pool = await poolPromise;

    const result = await pool.request()
      .input("UserID", sql.VarChar, userId)
      .query(`
        SELECT 
          NotificationID,
          Title,
          Description,
          ImageUrl,
          FORMAT(CreatedAt, 'yyyy-MM-dd HH:mm:ss') AS CreatedAt
        FROM Notifications
        WHERE IsActive = 1
          AND (UserID IS NULL OR UserID = @UserID)
        ORDER BY CreatedAt DESC
      `);

    // ✅ Always return JSON array
    res.status(200).json(result.recordset);
  } catch (err) {
    console.error("❌ Error fetching user notifications:", err);
    res.status(500).json({ error: err.message });
  }
});



module.exports = router;
