const jwt = require("jsonwebtoken");

module.exports = function (req, res, next) {
  const authHeader = req.headers["authorization"];
  if (!authHeader) {
    return res.status(401).json({ message: "No token provided" });
  }

  const token = authHeader.split(" ")[1]; // "Bearer <token>"
  if (!token) {
    return res.status(401).json({ message: "Token missing" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId; // attach userId for later use
    next();
  } catch (err) {
    return res.status(403).json({ message: "Invalid or expired token" });
  }
};
