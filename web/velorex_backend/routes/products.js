// routes/products.js
const express = require("express");
const router = express.Router();
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() });
const supabase = require("../models/supabaseClient");
const { sql, poolPromise } = require("../models/db");

/* ===========================
   Helpers
   =========================== */

async function uploadToSupabase(file, folder = "product") {
  const fileName = `${Date.now()}_${Math.random()
    .toString(36)
    .slice(2, 8)}_${file.originalname.replace(/\s+/g, "_")}`;
  const key = `${folder}/${fileName}`;

  const { error } = await supabase.storage
    .from("product")
    .upload(key, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
    });

  if (error) throw error;

  return supabase.storage.from("product").getPublicUrl(key).data.publicUrl;
}

function sanitizeComboKey(k = "") {
  return k
    .toString()
    .replace(/[^a-zA-Z0-9\-_.]/g, "_")
    .replace(/_+/g, "_");
}

function generateVariantProductName(parentName = "", variantSelections = []) {
  const vals = (variantSelections || [])
    .map((v) =>
      typeof v === "string"
        ? v
        : v.value || v.Variant || v.VariantName || ""
    )
    .filter(Boolean);

  return vals.length ? `${parentName} (${vals.join(", ")})` : parentName;
}

function generateSKU(parentName = "", variantSelections = []) {
  const parentCode =
    (parentName || "")
      .replace(/[^A-Za-z0-9]/g, "")
      .slice(0, 6)
      .toUpperCase() || "PRD";

  const variantPart = (variantSelections || [])
    .map((v) => {
      const val =
        typeof v === "string"
          ? v
          : v.value || v.Variant || v.VariantName || "";
      return val
        .toString()
        .split(/\s+/)
        .map((s) => s[0] || "")
        .join("")
        .toUpperCase()
        .slice(0, 3);
    })
    .filter(Boolean)
    .join("-");

  const suffix = Math.floor(1000 + Math.random() * 9000);
  return `${parentCode}${variantPart ? "-" + variantPart : ""}-${suffix}`;
}

/* ===========================
   GET ALL PRODUCTS
   =========================== */
router.get("/", async (req, res) => {
  try {
    const pool = await poolPromise;

    const result = await pool.request().query(`
      SELECT 
        p.ProductID, p.Name, p.Description, p.Price, p.OfferPrice, p.Quantity, p.Stock,
        p.CategoryID, p.SubcategoryID, p.BrandID, p.IsSponsored, 
        p.ParentProductID, p.GroupID, p.SKU, p.VideoUrl,
        (SELECT STRING_AGG(ImageURL, ',') FROM ProductImages WHERE ProductID = p.ProductID) AS ImageUrls
      FROM Products p
      ORDER BY p.ProductID DESC
    `);

    const products = result.recordset.map((r) => ({
      id: r.ProductID,
      name: r.Name,
      description: r.Description,
      price: r.Price,
      offerPrice: r.OfferPrice,
      quantity: r.Quantity,
      stock: r.Stock,
      categoryId: r.CategoryID,
      subcategoryId: r.SubcategoryID,
      brandId: r.BrandID,
      isSponsored: r.IsSponsored,
      parentProductId: r.ParentProductID,
      groupId: r.GroupID,
      sku: r.SKU,
      videoUrl: r.VideoUrl,
      images: r.ImageUrls ? r.ImageUrls.split(",") : [],
    }));

    res.json(products);
  } catch (err) {
    console.error("❌ Fetch products error:", err);
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   CREATE PRODUCT (NON-VARIANT)
   =========================== */
router.post("/", upload.array("images", 20), async (req, res) => {
  try {
    const {
      name,
      description,
      price,
      offerPrice,
      quantity,
      categoryId,
      subcategoryId,
      brandId,
      stock,
      isSponsored,
      sku,
      videoUrl, // NEW
    } = req.body;

    if (!name)
      return res.status(400).json({ error: "Name is required" });

    const pool = await poolPromise;

    /* NEW GROUP ID */
    const newGroupId = Date.now();

    const imageUrls = [];
    if (req.files && req.files.length) {
      for (const f of req.files) {
        const url = await uploadToSupabase(f, "products");
        imageUrls.push(url);
      }
    }

    const insertReq = await pool
      .request()
      .input("Name", sql.NVarChar, name)
      .input("Description", sql.NVarChar, description || null)
      .input("Price", sql.Decimal(10, 2), price || null)
      .input("OfferPrice", sql.Decimal(10, 2), offerPrice || null)
      .input("Quantity", sql.Int, quantity || 0)
      .input("Stock", sql.Int, stock || 0)
      .input("CategoryID", sql.Int, categoryId || null)
      .input("SubcategoryID", sql.Int, subcategoryId || null)
      .input("BrandID", sql.Int, brandId || null)
      .input("IsSponsored", sql.Bit, isSponsored ? 1 : 0)
      .input("SKU", sql.NVarChar, sku || null)
      .input("GroupID", sql.BigInt, newGroupId)
      .input("VideoUrl", sql.NVarChar, videoUrl || null)
      .query(`
        INSERT INTO Products
        (Name, Description, Price, OfferPrice, Quantity, Stock, CategoryID,
         SubcategoryID, BrandID, IsSponsored, SKU, GroupID, VideoUrl,
         CreatedAt, UpdatedAt)
        VALUES
        (@Name, @Description, @Price, @OfferPrice, @Quantity, @Stock,
         @CategoryID, @SubcategoryID, @BrandID, @IsSponsored, @SKU, @GroupID,
         @VideoUrl, GETDATE(), GETDATE());

        SELECT SCOPE_IDENTITY() AS ProductID;
      `);

    const productId = insertReq.recordset[0].ProductID;

    for (const url of imageUrls) {
      await pool
        .request()
        .input("ProductID", sql.Int, productId)
        .input("ImageURL", sql.NVarChar, url)
        .query(
          "INSERT INTO ProductImages (ProductID, ImageURL) VALUES (@ProductID, @ImageURL)"
        );
    }

    res.status(201).json({ success: true, productId });
  } catch (err) {
    console.error("❌ Create product error:", err);
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   UPDATE PRODUCT
   =========================== */
router.put("/:id", upload.array("images", 20), async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!id) return res.status(400).json({ error: "Invalid ID" });

    const pool = await poolPromise;
    const body = req.body;

    const newImageUrls = [];
    if (req.files && req.files.length) {
      for (const f of req.files) {
        const url = await uploadToSupabase(f, "products");
        newImageUrls.push(url);
      }
    }

    const params = pool.request().input("ProductID", sql.Int, id);
    const fields = [];

    if (body.name) {
      fields.push("Name = @Name");
      params.input("Name", sql.NVarChar, body.name);
    }
    if (body.description) {
      fields.push("Description = @Description");
      params.input("Description", sql.NVarChar, body.description);
    }
    if (body.price !== undefined) {
      fields.push("Price = @Price");
      params.input("Price", sql.Decimal(10, 2), body.price);
    }
    if (body.offerPrice !== undefined) {
      fields.push("OfferPrice = @OfferPrice");
      params.input("OfferPrice", sql.Decimal(10, 2), body.offerPrice);
    }
    if (body.quantity !== undefined) {
      fields.push("Quantity = @Quantity");
      params.input("Quantity", sql.Int, body.quantity);
    }
    if (body.stock !== undefined) {
      fields.push("Stock = @Stock");
      params.input("Stock", sql.Int, body.stock);
    }
    if (body.categoryId !== undefined) {
      fields.push("CategoryID = @CategoryID");
      params.input("CategoryID", sql.Int, body.categoryId);
    }
    if (body.subcategoryId !== undefined) {
      fields.push("SubcategoryID = @SubcategoryID");
      params.input("SubcategoryID", sql.Int, body.subcategoryId);
    }
    if (body.brandId !== undefined) {
      fields.push("BrandID = @BrandID");
      params.input("BrandID", sql.Int, body.brandId);
    }
    if (body.isSponsored !== undefined) {
      fields.push("IsSponsored = @IsSponsored");
      params.input("IsSponsored", sql.Bit, body.isSponsored ? 1 : 0);
    }
    if (body.sku !== undefined) {
      fields.push("SKU = @SKU");
      params.input("SKU", sql.NVarChar, body.sku);
    }
    if (body.videoUrl !== undefined) {
      fields.push("VideoUrl = @VideoUrl");
      params.input("VideoUrl", sql.NVarChar, body.videoUrl || null);
    }

    fields.push("UpdatedAt = GETDATE()");

    if (fields.length) {
      await params.query(
        `UPDATE Products SET ${fields.join(", ")} WHERE ProductID = @ProductID`
      );
    }

    for (const url of newImageUrls) {
      await pool
        .request()
        .input("ProductID", sql.Int, id)
        .input("ImageURL", sql.NVarChar, url)
        .query(
          "INSERT INTO ProductImages (ProductID, ImageURL) VALUES (@ProductID, @ImageURL)"
        );
    }

    /* Replace variant selections */
    if (body.variantSelections) {
      const selections =
        typeof body.variantSelections === "string"
          ? JSON.parse(body.variantSelections)
          : body.variantSelections;

      await pool
        .request()
        .input("ProductID", sql.Int, id)
        .query(
          "DELETE FROM ProductVariantSelections WHERE ProductID = @ProductID"
        );

      for (const sel of selections) {
        const vt =
          sel.variantTypeId ??
          sel.VariantTypeID ??
          sel.VariantTypeId;
        const vv =
          sel.variantId ??
          sel.VariantID ??
          sel.VariantValueID;

        if (!vt || !vv) continue;

        await pool
          .request()
          .input("ProductID", sql.Int, id)
          .input("VariantTypeID", sql.Int, vt)
          .input("VariantID", sql.Int, vv)
          .query(
            "INSERT INTO ProductVariantSelections (ProductID, VariantTypeID, VariantID, AddedDate) VALUES (@ProductID, @VariantTypeID, @VariantID, GETDATE())"
          );
      }
    }

    res.json({ success: true, message: "Product updated" });
  } catch (err) {
    console.error("❌ Update error:", err);
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   DELETE PRODUCT
   =========================== */
router.delete("/:id", async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!id) return res.status(400).json({ error: "Invalid ID" });

    const pool = await poolPromise;

    await pool
      .request()
      .input("ProductID", sql.Int, id)
      .query(
        "DELETE FROM ProductVariantSelections WHERE ProductID = @ProductID"
      );

    await pool
      .request()
      .input("ProductID", sql.Int, id)
      .query("DELETE FROM ProductImages WHERE ProductID = @ProductID");

    await pool
      .request()
      .input("ProductID", sql.Int, id)
      .query("DELETE FROM Products WHERE ProductID = @ProductID");

    res.json({ success: true, message: "Product deleted" });
  } catch (err) {
    console.error("❌ Delete error:", err);
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   POST /with-variants
   =========================== */
router.post("/with-variants", upload.any(), async (req, res) => {
  const pool = await poolPromise;
  const files = req.files || [];

  const filesByField = {};
  for (const f of files) {
    if (!filesByField[f.fieldname]) filesByField[f.fieldname] = [];
    filesByField[f.fieldname].push(f);
  }

  let parentJson = null;
  let variantsPayload = [];

  try {
    parentJson = req.body.parent ? JSON.parse(req.body.parent) : null;
    variantsPayload = req.body.variantsPayload
      ? JSON.parse(req.body.variantsPayload)
      : [];
  } catch (err) {
    console.error("❌ Invalid JSON:", err);
    return res
      .status(400)
      .json({ error: "Invalid JSON in parent or variantsPayload" });
  }

  if (!parentJson || !parentJson.name) {
    return res
      .status(400)
      .json({ error: "Parent JSON with name required" });
  }

  const tx = new sql.Transaction(pool);
  const createdChildIds = [];

  /* NEW: GROUP ID */
  const groupId = Date.now();

  try {
    await tx.begin();

    /* ===========================
       INSERT PARENT PRODUCT
       =========================== */
    const treq = tx.request();
    treq.input("Name", sql.NVarChar, parentJson.name);
    treq.input("Description", sql.NVarChar, parentJson.description || null);
    treq.input("Price", sql.Decimal(10, 2), parentJson.price || null);
    treq.input("OfferPrice", sql.Decimal(10, 2), parentJson.offerPrice || null);
    treq.input("Quantity", sql.Int, parentJson.quantity ?? 0);
    treq.input("Stock", sql.Int, parentJson.stock ?? 0);
    treq.input("CategoryID", sql.Int, parentJson.categoryId || null);
    treq.input("SubcategoryID", sql.Int, parentJson.subcategoryId || null);
    treq.input("BrandID", sql.Int, parentJson.brandId || null);
    treq.input("IsSponsored", sql.Bit, parentJson.isSponsored ? 1 : 0);
    treq.input("SKU", sql.NVarChar, parentJson.sku || null);
    treq.input("GroupID", sql.BigInt, groupId);
    treq.input("VideoUrl", sql.NVarChar, parentJson.videoUrl || null);

    const parentInsertSQL = `
      INSERT INTO Products
      (Name, Description, Price, OfferPrice, Quantity, Stock, CategoryID,
       SubcategoryID, BrandID, IsSponsored, SKU, GroupID, VideoUrl,
       CreatedAt, UpdatedAt)
      VALUES
      (@Name, @Description, @Price, @OfferPrice, @Quantity, @Stock,
       @CategoryID, @SubcategoryID, @BrandID, @IsSponsored, @SKU, @GroupID,
       @VideoUrl, GETDATE(), GETDATE());

      SELECT SCOPE_IDENTITY() AS ProductID;
    `;

    const parentRes = await treq.query(parentInsertSQL);
    const parentProductId = parentRes.recordset[0].ProductID;

    /* ===========================
       SAVE PARENT IMAGES
       =========================== */
    if (filesByField["parentImages"]) {
      for (const f of filesByField["parentImages"]) {
        const url = await uploadToSupabase(f, "products/parent");

        await tx
          .request()
          .input("ProductID", sql.Int, parentProductId)
          .input("ImageURL", sql.NVarChar, url)
          .query(
            "INSERT INTO ProductImages (ProductID, ImageURL) VALUES (@ProductID, @ImageURL)"
          );
      }
    }

    /* ===========================
       INSERT CHILD VARIANTS
       =========================== */
    for (const combo of variantsPayload) {
      const selections = Array.isArray(combo.selections)
        ? combo.selections
        : combo.selections || [];

      const comboLabel = combo.label || combo.combinationKey || "";

      const childName = generateVariantProductName(
        parentJson.name,
        selections.map(
          (s) => s.value || s.Variant || s.VariantName || ""
        )
      );

      const price = combo.price ?? parentJson.price;
      const offerPrice = combo.offerPrice ?? parentJson.offerPrice;
      const stock = combo.stock ?? 0;
      const quantity = combo.quantity ?? 0;
      const videoUrl = combo.videoUrl || null;

      const skuToUse =
        combo.sku ||
        generateSKU(
          parentJson.name,
          selections.map((s) => s.value)
        );

      const childReq = tx
        .request()
        .input("Name", sql.NVarChar, childName)
        .input("Description", sql.NVarChar, combo.description || null)
        .input("Price", sql.Decimal(10, 2), price)
        .input("OfferPrice", sql.Decimal(10, 2), offerPrice)
        .input("Quantity", sql.Int, quantity)
        .input("Stock", sql.Int, stock)
        .input("CategoryID", sql.Int, parentJson.categoryId || null)
        .input("SubcategoryID", sql.Int, parentJson.subcategoryId || null)
        .input("BrandID", sql.Int, parentJson.brandId || null)
        .input("IsSponsored", sql.Bit, parentJson.isSponsored ? 1 : 0)
        .input("SKU", sql.NVarChar, skuToUse)
        .input("ParentProductID", sql.Int, parentProductId)
        .input("GroupID", sql.BigInt, groupId)
        .input("VideoUrl", sql.NVarChar, videoUrl);

      const childInsertSQL = `
        INSERT INTO Products
        (Name, Description, Price, OfferPrice, Quantity, Stock, CategoryID,
         SubcategoryID, BrandID, IsSponsored, SKU, ParentProductID, GroupID, VideoUrl,
         CreatedAt, UpdatedAt)
        VALUES
        (@Name, @Description, @Price, @OfferPrice, @Quantity, @Stock,
         @CategoryID, @SubcategoryID, @BrandID, @IsSponsored, @SKU,
         @ParentProductID, @GroupID, @VideoUrl, GETDATE(), GETDATE());

        SELECT SCOPE_IDENTITY() AS ProductID;
      `;

      const childRes = await childReq.query(childInsertSQL);
      const childProductId = childRes.recordset[0].ProductID;
      createdChildIds.push(childProductId);

      /* ===========================
         INSERT VARIANT SELECTIONS
         =========================== */
      for (const sel of selections) {
        const vt =
          sel.VariantTypeID ??
          sel.variantTypeId ??
          sel.typeId;
        const vv =
          sel.VariantID ??
          sel.variantValueId ??
          sel.variantId;

        if (!vt || !vv) continue;

        await tx
          .request()
          .input("ProductID", sql.Int, childProductId)
          .input("VariantTypeID", sql.Int, vt)
          .input("VariantID", sql.Int, vv)
          .query(
            "INSERT INTO ProductVariantSelections (ProductID, VariantTypeID, VariantID, AddedDate) VALUES (@ProductID, @VariantTypeID, @VariantID, GETDATE())"
          );
      }

      /* ===========================
         SAVE CHILD IMAGES
         =========================== */
      const sanitizedKey = sanitizeComboKey(
        combo.combinationKey || comboLabel
      );
      const fieldName = `images_${sanitizedKey}`;

      const comboFiles = filesByField[fieldName] || [];

      for (const f of comboFiles) {
        const url = await uploadToSupabase(f, "products/variants");

        await tx
          .request()
          .input("ProductID", sql.Int, childProductId)
          .input("ImageURL", sql.NVarChar, url)
          .query(
            "INSERT INTO ProductImages (ProductID, ImageURL) VALUES (@ProductID, @ImageURL)"
          );
      }
    }

    await tx.commit();

    res.json({
      success: true,
      parentProductId,
      groupId,
      childProductIds: createdChildIds,
    });
  } catch (err) {
    console.error("❌ /with-variants error:", err);
    try {
      await tx.rollback();
    } catch {}
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   GET /:id/with-variants
   =========================== */
router.get("/:id/with-variants", async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!id) return res.status(400).json({ error: "Invalid id" });

    const pool = await poolPromise;

    const parentQ = await pool
      .request()
      .input("id", sql.Int, id)
      .query("SELECT * FROM Products WHERE ProductID = @id");

    const parent = parentQ.recordset[0];
    if (!parent)
      return res.status(404).json({ error: "Parent not found" });

    const parentImgs = await pool
      .request()
      .input("id", sql.Int, id)
      .query(
        "SELECT ProductImageID, ImageURL FROM ProductImages WHERE ProductID = @id"
      );

    parent.images = parentImgs.recordset;

    /* Get all children by SAME ParentProductID */
    const childrenQ = await pool
      .request()
      .input("id", sql.Int, id)
      .query(
        "SELECT * FROM Products WHERE ParentProductID = @id ORDER BY ProductID ASC"
      );

    const children = childrenQ.recordset;

    for (const c of children) {
      const imgs = await pool
        .request()
        .input("id", sql.Int, c.ProductID)
        .query(
          "SELECT ProductImageID, ImageURL FROM ProductImages WHERE ProductID = @id"
        );

      c.images = imgs.recordset;

      const sels = await pool
        .request()
        .input("id", sql.Int, c.ProductID)
        .query(
          "SELECT VariantTypeID, VariantID FROM ProductVariantSelections WHERE ProductID = @id"
        );

      c.variantSelections = sels.recordset;
    }

    res.json({ parent, children });
  } catch (err) {
    console.error("❌ fetch with-variants error:", err);
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   NEW: GET /by-group/:groupId
   =========================== */
router.get("/by-group/:groupId", async (req, res) => {
  try {
    const groupId = Number(req.params.groupId);
    if (!groupId)
      return res.status(400).json({ error: "Invalid GroupID" });

    const pool = await poolPromise;

    const productsQ = await pool
      .request()
      .input("gid", sql.BigInt, groupId)
      .query(
        "SELECT * FROM Products WHERE GroupID = @gid ORDER BY ProductID"
      );

    const products = productsQ.recordset;

    for (const p of products) {
      const imgs = await pool
        .request()
        .input("id", sql.Int, p.ProductID)
        .query(
          "SELECT ProductImageID, ImageURL FROM ProductImages WHERE ProductID = @id"
        );

      p.images = imgs.recordset;

      const sels = await pool
        .request()
        .input("id", sql.Int, p.ProductID)
        .query(
          "SELECT VariantTypeID, VariantID FROM ProductVariantSelections WHERE ProductID = @id"
        );

      p.variantSelections = sels.recordset;
    }

    res.json({ groupId, products });
  } catch (err) {
    console.error("❌ group fetch error:", err);
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   DELETE /:id/cascade
   =========================== */
router.delete("/:id/cascade", async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: "Invalid id" });

  const pool = await poolPromise;
  const tx = new sql.Transaction(pool);

  try {
    await tx.begin();

    const childrenQ = await tx
      .request()
      .input("id", sql.Int, id)
      .query("SELECT ProductID FROM Products WHERE ParentProductID = @id");

    const childIds = childrenQ.recordset.map((x) => x.ProductID);

    for (const cid of childIds) {
      await tx
        .request()
        .input("pid", sql.Int, cid)
        .query(
          "DELETE FROM ProductVariantSelections WHERE ProductID = @pid"
        );

      await tx
        .request()
        .input("pid", sql.Int, cid)
        .query("DELETE FROM ProductImages WHERE ProductID = @pid");

      await tx
        .request()
        .input("pid", sql.Int, cid)
        .query("DELETE FROM Products WHERE ProductID = @pid");
    }

    await tx
      .request()
      .input("pid", sql.Int, id)
      .query(
        "DELETE FROM ProductVariantSelections WHERE ProductID = @pid"
      );

    await tx
      .request()
      .input("pid", sql.Int, id)
      .query("DELETE FROM ProductImages WHERE ProductID = @pid");

    await tx
      .request()
      .input("pid", sql.Int, id)
      .query("DELETE FROM Products WHERE ProductID = @pid");

    await tx.commit();

    res.json({ success: true, message: "Parent + children deleted" });
  } catch (err) {
    console.error("❌ cascade delete error:", err);
    try {
      await tx.rollback();
    } catch {}
    res.status(500).json({ error: err.message });
  }
});

/* ===========================
   UPDATE CHILD PRODUCT
   =========================== */
router.put("/child/:id", upload.array("images", 20), async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ error: "Invalid id" });

  try {
    const pool = await poolPromise;
    const body = req.body;

    const imageUrls = [];
    if (req.files && req.files.length) {
      for (const f of req.files) {
        const url = await uploadToSupabase(f, "products/variants");
        imageUrls.push(url);
      }
    }

    const params = pool.request().input("ProductID", sql.Int, id);
    const fields = [];

    if (body.name) {
      fields.push("Name = @Name");
      params.input("Name", sql.NVarChar, body.name);
    }

    if (body.price !== undefined) {
      fields.push("Price = @Price");
      params.input("Price", sql.Decimal(10, 2), body.price);
    }

    if (body.offerPrice !== undefined) {
      fields.push("OfferPrice = @OfferPrice");
      params.input("OfferPrice", sql.Decimal(10, 2), body.offerPrice);
    }

    if (body.quantity !== undefined) {
      fields.push("Quantity = @Quantity");
      params.input("Quantity", sql.Int, body.quantity);
    }

    if (body.stock !== undefined) {
      fields.push("Stock = @Stock");
      params.input("Stock", sql.Int, body.stock);
    }

    if (body.sku !== undefined) {
      fields.push("SKU = @SKU");
      params.input("SKU", sql.NVarChar, body.sku);
    }

    if (body.videoUrl !== undefined) {
      fields.push("VideoUrl = @VideoUrl");
      params.input("VideoUrl", sql.NVarChar, body.videoUrl || null);
    }

    fields.push("UpdatedAt = GETDATE()");

    if (fields.length) {
      await params.query(
        `UPDATE Products SET ${fields.join(", ")} WHERE ProductID = @ProductID`
      );
    }

    for (const u of imageUrls) {
      await pool
        .request()
        .input("ProductID", sql.Int, id)
        .input("ImageURL", sql.NVarChar, u)
        .query(
          "INSERT INTO ProductImages (ProductID, ImageURL) VALUES (@ProductID, @ImageURL)"
        );
    }

    /* Replace variant selections */
    if (body.variantSelections) {
      const selections =
        typeof body.variantSelections === "string"
          ? JSON.parse(body.variantSelections)
          : body.variantSelections;

      await pool
        .request()
        .input("ProductID", sql.Int, id)
        .query(
          "DELETE FROM ProductVariantSelections WHERE ProductID = @ProductID"
        );

      for (const sel of selections) {
        const vt =
          sel.variantTypeId ??
          sel.VariantTypeID ??
          sel.VariantTypeId;
        const vv =
          sel.variantId ??
          sel.VariantID ??
          sel.VariantValueID;

        if (!vt || !vv) continue;

        await pool
          .request()
          .input("ProductID", sql.Int, id)
          .input("VariantTypeID", sql.Int, vt)
          .input("VariantID", sql.Int, vv)
          .query(
            "INSERT INTO ProductVariantSelections (ProductID, VariantTypeID, VariantID, AddedDate) VALUES (@ProductID, @VariantTypeID, @VariantID, GETDATE())"
          );
      }
    }

    res.json({ success: true, message: "Child updated" });
  } catch (err) {
    console.error("❌ child update error:", err);
    res.status(500).json({ error: err.message });
  }
});


/* ===========================
   EXPORT ROUTER
   =========================== */
module.exports = router;
