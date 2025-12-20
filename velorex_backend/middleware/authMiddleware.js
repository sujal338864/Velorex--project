const jwt = require("jsonwebtoken");

module.exports = function (req, res, next) {
  try {
    const authHeader =
      req.headers.authorization || req.headers.Authorization;

    if (!authHeader)
      return res.status(401).json({ message: "No token provided" });

    const parts = authHeader.split(" ");

    if (parts.length !== 2 || parts[0] !== "Bearer")
      return res.status(401).json({ message: "Invalid auth format" });

    const token = parts[1];

    if (!process.env.JWT_SECRET) {
      console.error("❌ Missing JWT_SECRET environment variable");
      return res.status(500).json({ message: "Server config error" });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;

    next();
  } catch (err) {
    console.error("JWT Verify Error:", err.message);
    return res.status(403).json({ message: "Invalid or expired token" });
  }
};


// const jwt = require("jsonwebtoken");

// module.exports = function (req, res, next) {
//   const authHeader = req.headers["authorization"];
//   if (!authHeader) {
//     return res.status(401).json({ message: "No token provided" });
//   }

//   const token = authHeader.split(" ")[1]; // "Bearer <token>"
//   if (!token) {
//     return res.status(401).json({ message: "Token missing" });
//   }

//   try {
//     const decoded = jwt.verify(token, process.env.JWT_SECRET);
//     req.userId = decoded.userId; // attach userId for later use
//     next();
//   } catch (err) {
//     return res.status(403).json({ message: "Invalid or expired token" });
//   }
// };
