import 'dart:convert';

/// ======================================================
/// PARSER FOR compute()
/// ======================================================
List<Items> parseItems(String responseBody) {
  final decoded = json.decode(responseBody);

  final List<dynamic> list =
      decoded is Map<String, dynamic> && decoded.containsKey('data')
          ? decoded['data']
          : decoded as List<dynamic>;

  return list.map((e) => Items.fromMap(Map<String, dynamic>.from(e))).toList();
}

/// ======================================================
/// MODEL STORE
/// ======================================================
class OnesolutionModel {
  static List<Items> items = [];

  Items? getById(int id) {
    try {
      return items.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Items getByPosition(int pos) => items[pos];
}

/// ======================================================
/// ⭐ FINAL, CLEAN, FULLY FIXED MODEL
/// ======================================================
class Items {
  final int id;
  final String name;
  final String description;

  final double price;
  final double offerPrice;

  final String brand;
  final List<String> images;

  final int? categoryId;
  final String? categoryName;
  final int? subcategoryId;

  final String? userId;
  final int? stock;

  final int? parentProductId;
  final int? groupId;

  final int quantity;
  final DateTime? createdAt;

  String get firstImage =>
      images.isNotEmpty ? images.first : "https://via.placeholder.com/150";

  int get discountPercent =>
      price == 0 ? 0 : ((1 - (offerPrice / price)) * 100).round();

  Items({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.offerPrice,
    required this.brand,
    required this.images,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.userId,
    this.stock,
    this.parentProductId,
    this.groupId,
    this.quantity = 1,
    this.createdAt,
  });

  /// ======================================================
  /// ⭐ COMPLETE FIX FOR ALL PROBLEMS
  /// ======================================================
  factory Items.fromMap(Map<String, dynamic> map) {
    List<String> parsedImages = [];

    final raw = map['images'] ??
        map['Images'] ??
        map['imageUrls'] ??
        map['ImageUrls'] ??
        map['ImageURL'];

    // 🔥 1) FIXED: SUPPORT "images": [ { ImageURL:"..." } ]
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      parsedImages = raw
          .where((e) => e['ImageURL'] != null)
          .map((e) => e['ImageURL'].toString())
          .toList();
    }

    // 🔥 2) ALSO SUPPORT STRING LIST = ["url1","url2"]
    else if (raw is List) {
      parsedImages = raw.map((e) => e.toString()).toList();
    }

    // 🔥 3) SUPPORT BACKEND "url1,url2"
    else if (raw is String && raw.contains(",")) {
      parsedImages = raw.split(",").map((e) => e.trim()).toList();
    }

    // 🔥 4) SUPPORT SINGLE STRING URL
    else if (raw is String && raw.isNotEmpty) {
      parsedImages = [raw];
    }

    // Normalize URLs
    parsedImages = parsedImages.map((img) {
      if (img.startsWith("http")) return img;
      return "https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/product/$img";
    }).toList();

    if (parsedImages.isEmpty) {
      parsedImages = ["https://via.placeholder.com/150"];
    }

    // -------------------------------
    // PRICE FIX
    // -------------------------------
    final price = double.tryParse(
            map['price']?.toString() ?? map['Price']?.toString() ?? "") ??
        0.0;

    double offerPrice = double.tryParse(
            map['offerPrice']?.toString() ??
                map['OfferPrice']?.toString() ??
                "") ??
        price;

    // -------------------------------
    // PARENT PRODUCT ID
    // -------------------------------
    int? parentID;
    final rawParent = map['parentProductId'] ??
        map['ParentProductID'] ??
        map['parent_product_id'];

    if (rawParent != null && rawParent.toString() != "null") {
      parentID = int.tryParse(rawParent.toString());
    }

    // -------------------------------
    // GROUP ID
    // -------------------------------
    int? groupID;
    final rawGroup = map['groupId'] ?? map['GroupID'];

    if (rawGroup != null && rawGroup.toString() != "null") {
      groupID = int.tryParse(rawGroup.toString());
    }

    // -------------------------------
    // CREATED AT FIX
    // -------------------------------
    DateTime? created;
    if (map['createdAt'] != null) {
      created = DateTime.tryParse(map['createdAt'].toString());
    } else if (map['CreatedAt'] != null) {
      created = DateTime.tryParse(map['CreatedAt'].toString());
    }

    return Items(
      id: int.tryParse(map['id']?.toString() ?? map['ProductID']?.toString() ?? "0") ?? 0,
      name: map['name']?.toString() ??
          map['Name']?.toString() ??
          "Unnamed Product",
      description: map['description']?.toString() ??
          map['Description']?.toString() ??
          "",
      price: price,
      offerPrice: offerPrice,
      brand: map['brand']?.toString() ??
          map['brandName']?.toString() ??
          "Unknown",
      images: parsedImages,
      categoryId: int.tryParse(map['categoryId']?.toString() ??
              map['CategoryID']?.toString() ??
              ""),
      categoryName: map['categoryName']?.toString(),
      subcategoryId: int.tryParse(map['subcategoryId']?.toString() ??
              map['SubcategoryID']?.toString() ??
              ""),
      userId: map['userId']?.toString(),
      stock:
          int.tryParse(map['stock']?.toString() ?? map['Stock']?.toString() ?? ""),
      parentProductId: parentID,
      groupId: groupID,
      quantity:
          int.tryParse(map['quantity']?.toString() ?? map['Quantity']?.toString() ?? "1") ??
              1,
      createdAt: created,
    );
  }

  /// ======================================================
  /// EXPORT
  /// ======================================================
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "price": price,
      "offerPrice": offerPrice,
      "brand": brand,
      "images": images,
      "categoryId": categoryId,
      "categoryName": categoryName,
      "subcategoryId": subcategoryId,
      "userId": userId,
      "stock": stock,
      "quantity": quantity,
      "createdAt": createdAt?.toIso8601String(),
      "parentProductId": parentProductId,
      "groupId": groupId,
    };
  }
}
