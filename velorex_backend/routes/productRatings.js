const express = require("express");
const router = express.Router();
const pool = require("../models/db");

// helper
function round2(num) {
  return Math.round(num * 100) / 100;
}

/**
 * GET SUMMARY
 */
router.get("/products/:productId/ratings/summary", async (req, res) => {
  const productId = parseInt(req.params.productId, 10);
  if (!productId) return res.status(400).json({ error: "Invalid productId" });

  try {
    // 1️⃣ Overall stats
    const stats = await pool.query(
      `
      SELECT 
        COUNT(*) AS total_reviews,
        AVG(rating)::numeric(10,2) AS avg_rating
      FROM reviews
      WHERE product_id = $1
      `,
      [productId]
    );

    const totalReviews = Number(stats.rows[0].total_reviews || 0);

    if (totalReviews === 0) {
      return res.json({
        productId,
        averageRating: 0,
        totalRatings: 0,
        totalReviews: 0,
        distribution: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 },
        topReview: null,
      });
    }

    const avgRating = Number(stats.rows[0].avg_rating || 0);

    // 2️⃣ Star Distribution
    const dist = await pool.query(
      `
      SELECT rating, COUNT(*) AS count
      FROM reviews
      WHERE product_id = $1
      GROUP BY rating
      `,
      [productId]
    );

    const counts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    dist.rows.forEach(r => {
      counts[r.rating] = Number(r.count);
    });

    const distribution = {};
    Object.keys(counts).forEach(k => {
      distribution[k] = Math.round((counts[k] / totalReviews) * 100);
    });

    // 3️⃣ Top Review
    const topReviewRes = await pool.query(
      `
      SELECT 
        review_id,
        user_id,
        rating,
        comment AS body,
        created_at
      FROM reviews
      WHERE product_id = $1
      ORDER BY rating DESC, created_at DESC
      LIMIT 1
      `,
      [productId]
    );

    const r = topReviewRes.rows[0];
    const topReview = r
      ? {
          reviewId: r.review_id,
          userId: r.user_id,
          rating: r.rating,
          title: null,          // you don't have title column in PG
          body: r.body,
          createdAt: r.created_at,
        }
      : null;

    res.json({
      productId,
      averageRating: round2(avgRating),
      totalRatings: totalReviews,
      totalReviews,
      distribution,
      topReview,
    });
  } catch (err) {
    console.error("summary error", err);
    res.status(500).json({ error: "Failed to fetch rating summary" });
  }
});


/**
 * GET ALL REVIEWS + PAGINATION
 */
router.get("/products/:productId/reviews", async (req, res) => {
  const productId = parseInt(req.params.productId, 10);
  if (!productId) return res.status(400).json({ error: "Invalid productId" });

  const page = parseInt(req.query.page || "1", 10);
  const pageSize = parseInt(req.query.pageSize || "10", 10);
  const offset = (page - 1) * pageSize;

  try {
    const result = await pool.query(
      `
      SELECT 
        review_id,
        product_id,
        user_id,
        rating,
        comment,
        created_at
      FROM reviews
      WHERE product_id = $1
      ORDER BY created_at DESC
      LIMIT $2 OFFSET $3
      `,
      [productId, pageSize, offset]
    );

    res.json({
      productId,
      items: result.rows.map(r => ({
        reviewId: r.review_id,
        productId: r.product_id,
        userId: r.user_id,
        rating: r.rating,
        title: null,
        body: r.comment,
        createdAt: r.created_at,
      })),
    });
  } catch (err) {
    console.error("reviews list error", err);
    res.status(500).json({ error: "Failed to fetch reviews" });
  }
});


/**
 * INSERT / UPDATE (UPSERT)
 */
router.post("/products/:productId/reviews", async (req, res) => {
  const productId = parseInt(req.params.productId, 10);
  const { userId, rating, body } = req.body || {};

  if (!productId) return res.status(400).json({ error: "Invalid productId" });
  if (!userId || !rating || !body)
    return res.status(400).json({ error: "userId, rating, body required" });

  const ratingInt = parseInt(rating, 10);
  if (ratingInt < 1 || ratingInt > 5)
    return res.status(400).json({ error: "rating must be 1-5" });

  try {
    // check if exists
    const existing = await pool.query(
      `
      SELECT review_id
      FROM reviews
      WHERE product_id = $1 AND user_id = $2
      `,
      [productId, userId]
    );

    if (existing.rows.length > 0) {
      // update
      await pool.query(
        `
        UPDATE reviews
        SET rating = $1,
            comment = $2,
            updated_at = NOW()
        WHERE review_id = $3
        `,
        [ratingInt, body, existing.rows[0].review_id]
      );

      return res.json({ success: true, action: "updated" });
    }

    // insert
    await pool.query(
      `
      INSERT INTO reviews (product_id, user_id, rating, comment)
      VALUES ($1, $2, $3, $4)
      `,
      [productId, userId, ratingInt, body]
    );

    res.json({ success: true, action: "inserted" });
  } catch (err) {
    console.error("insert review error", err);
    res.status(500).json({ error: "Failed to submit review" });
  }
});

module.exports = router;



// const express = require("express");
// const router = express.Router();
// const { sql, poolPromise } = require("../models/db");
// // Helpers
// function round2(num) {
//   return Math.round(num * 100) / 100;
// }

// /**
//  * GET /api/products/:productId/ratings/summary
//  * Returns:
//  * {
//  *   productId,
//  *   averageRating,
//  *   totalRatings,
//  *   totalReviews,
//  *   distribution: { "5": 72, "4": 18, ... },
//  *   topReview: { ... } | null
//  * }
//  */
// router.get("/products/:productId/ratings/summary", async (req, res) => {
//   const productId = parseInt(req.params.productId, 10);
//   if (!productId || isNaN(productId)) {
//     return res.status(400).json({ error: "Invalid productId" });
//   }

//   try {
//     const pool = await poolPromise;
//     const request = pool.request();
//     request.input("ProductID", sql.Int, productId);

//     // 1) Overall stats
//     const statsResult = await request.query(`
//       SELECT 
//         COUNT(*) AS TotalReviews,
//         AVG(CAST(Rating AS FLOAT)) AS AvgRating
//       FROM ProductReviews
//       WHERE ProductID = @ProductID AND IsActive = 1;
//     `);

//     const statsRow = statsResult.recordset[0];
//     const totalReviews = statsRow.TotalReviews || 0;

//     if (totalReviews === 0) {
//       return res.json({
//         productId,
//         averageRating: 0,
//         totalRatings: 0,
//         totalReviews: 0,
//         distribution: { "5": 0, "4": 0, "3": 0, "2": 0, "1": 0 },
//         topReview: null,
//       });
//     }

//     const avgRating = statsRow.AvgRating || 0;

//     // 2) Distribution
//     const distResult = await request.query(`
//       SELECT Rating, COUNT(*) AS Cnt
//       FROM ProductReviews
//       WHERE ProductID = @ProductID AND IsActive = 1
//       GROUP BY Rating;
//     `);

//     const countsByRating = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
//     distResult.recordset.forEach((row) => {
//       const r = row.Rating;
//       const c = row.Cnt;
//       if (countsByRating[r] != null) {
//         countsByRating[r] = c;
//       }
//     });

//     const distribution = {};
//     Object.keys(countsByRating).forEach((k) => {
//       const star = parseInt(k, 10);
//       const cnt = countsByRating[star];
//       const percent = Math.round((cnt / totalReviews) * 100);
//       distribution[star] = percent;
//     });

//     // 3) Top review (like "Top review from India")
//     const topReviewResult = await request.query(`
//       SELECT TOP 1
//         ReviewID,
//         UserId,
//         UserName,
//         Rating,
//         Title,
//         Body,
//         CreatedAt
//       FROM ProductReviews
//       WHERE ProductID = @ProductID AND IsActive = 1
//       ORDER BY Rating DESC, CreatedAt DESC;
//     `);

//     const r0 = topReviewResult.recordset[0];
//     const topReview = r0
//       ? {
//           reviewId: r0.ReviewID,
//           userId: r0.UserId,
//           userName: r0.UserName,
//           rating: r0.Rating,
//           title: r0.Title,
//           body: r0.Body,
//           createdAt: r0.CreatedAt,
//         }
//       : null;

//     return res.json({
//       productId,
//       averageRating: round2(avgRating),
//       totalRatings: totalReviews, // you can separate ratings vs reviews later
//       totalReviews,
//       distribution,
//       topReview,
//     });
//   } catch (err) {
//     console.error("GET /products/:id/ratings/summary error", err);
//     return res
//       .status(500)
//       .json({ error: "Failed to fetch rating summary", details: err.message });
//   }
// });

// /**
//  * GET /api/products/:productId/reviews
//  * Optional query: ?page=1&pageSize=10
//  */
// router.get("/products/:productId/reviews", async (req, res) => {
//   const productId = parseInt(req.params.productId, 10);
//   if (!productId || isNaN(productId)) {
//     return res.status(400).json({ error: "Invalid productId" });
//   }

//   const page = parseInt(req.query.page || "1", 10);
//   const pageSize = parseInt(req.query.pageSize || "10", 10);
//   const offset = (page - 1) * pageSize;

//   try {
//     const pool = await poolPromise;
//     const request = pool.request();
//     request.input("ProductID", sql.Int, productId);
//     request.input("Offset", sql.Int, offset);
//     request.input("PageSize", sql.Int, pageSize);

//     const result = await request.query(`
//       SELECT 
//         ReviewID,
//         ProductID,
//         UserId,
//         UserName,
//         Rating,
//         Title,
//         Body,
//         CreatedAt
//       FROM ProductReviews
//       WHERE ProductID = @ProductID AND IsActive = 1
//       ORDER BY CreatedAt DESC
//       OFFSET @Offset ROWS
//       FETCH NEXT @PageSize ROWS ONLY;
//     `);

//     return res.json({
//       productId,
//       items: result.recordset.map((r) => ({
//         reviewId: r.ReviewID,
//         productId: r.ProductID,
//         userId: r.UserId,
//         userName: r.UserName,
//         rating: r.Rating,
//         title: r.Title,
//         body: r.Body,
//         createdAt: r.CreatedAt,
//       })),
//     });
//   } catch (err) {
//     console.error("GET /products/:id/reviews error", err);
//     return res
//       .status(500)
//       .json({ error: "Failed to fetch reviews", details: err.message });
//   }
// });

// /**
//  * POST /api/products/:productId/reviews
//  * Body: { userId, userName, rating, title, body }
//  * Upsert: if same (productId, userId) exists → UPDATE, else INSERT.
//  */
// router.post("/products/:productId/reviews", async (req, res) => {
//   const productId = parseInt(req.params.productId, 10);
//   if (!productId || isNaN(productId)) {
//     return res.status(400).json({ error: "Invalid productId" });
//   }

//   const { userId, userName, rating, title, body } = req.body || {};

//   if (!userId || !rating || !body) {
//     return res.status(400).json({
//       error: "userId, rating, and body are required",
//     });
//   }

//   const ratingInt = parseInt(rating, 10);
//   if (ratingInt < 1 || ratingInt > 5) {
//     return res.status(400).json({ error: "rating must be between 1 and 5" });
//   }

//   try {
//     const pool = await poolPromise;
//     const request = pool.request();
//     request.input("ProductID", sql.Int, productId);
//     request.input("UserId", sql.NVarChar(100), userId);

//     // Check if already exists
//     const existing = await request.query(`
//       SELECT ReviewID 
//       FROM ProductReviews
//       WHERE ProductID = @ProductID AND UserId = @UserId;
//     `);

//     if (existing.recordset.length > 0) {
//       // UPDATE
//       const reviewId = existing.recordset[0].ReviewID;
//       const req2 = pool.request();
//       req2.input("ReviewID", sql.Int, reviewId);
//       req2.input("Rating", sql.TinyInt, ratingInt);
//       req2.input("Title", sql.NVarChar(200), title || null);
//       req2.input("Body", sql.NVarChar(sql.MAX), body);
//       req2.input("UserName", sql.NVarChar(150), userName || null);

//       await req2.query(`
//         UPDATE ProductReviews
//         SET Rating = @Rating,
//             Title = @Title,
//             Body = @Body,
//             UserName = @UserName,
//             UpdatedAt = SYSDATETIME()
//         WHERE ReviewID = @ReviewID;
//       `);

//       return res.json({ success: true, action: "updated" });
//     } else {
//       // INSERT
//       const req2 = pool.request();
//       req2.input("ProductID", sql.Int, productId);
//       req2.input("UserId", sql.NVarChar(100), userId);
//       req2.input("UserName", sql.NVarChar(150), userName || null);
//       req2.input("Rating", sql.TinyInt, ratingInt);
//       req2.input("Title", sql.NVarChar(200), title || null);
//       req2.input("Body", sql.NVarChar(sql.MAX), body);

//       await req2.query(`
//         INSERT INTO ProductReviews (ProductID, UserId, UserName, Rating, Title, Body)
//         VALUES (@ProductID, @UserId, @UserName, @Rating, @Title, @Body);
//       `);

//       return res.json({ success: true, action: "inserted" });
//     }
//   } catch (err) {
//     console.error("POST /products/:id/reviews error", err);
//     return res
//       .status(500)
//       .json({ error: "Failed to submit review", details: err.message });
//   }
// });

// module.exports = router;
