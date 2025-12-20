import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = 'http://10.147.205.36:3000/api';

  /// ------------------- 🖼️ POSTERS -------------------
static Future<List<Map<String, dynamic>>> getPosters() async {
  final res = await http.get(Uri.parse('$baseUrl/posters'));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load posters');
}

static String getFullImageUrl(String path, {String folder = 'products'}) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) {
    // Add resizing only if it's from Supabase
    if (path.contains('supabase.co/storage')) {
      return "$path?width=600&quality=80";
    }
    return path;
  }
  // Fallback for relative paths
  return "https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/$folder/$path?width=600&quality=80";
}


static Future<Map<String, dynamic>> sendOtp(String email) async {
  final url = Uri.parse("$baseUrl/auth/send-otp");
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    print("🔹 Response (${response.statusCode}): ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"message": "Server error: ${response.statusCode}"};
    }
  } catch (e) {
    print("❌ Error in sendOtp: $e");
    return {"message": "Failed to connect to server"};
  }
}

static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
  final url = Uri.parse("$baseUrl/auth/verify-otp");
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    print("🔹 Response (${response.statusCode}): ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"message": "Server error: ${response.statusCode}"};
    }
  } catch (e) {
    print("❌ Error in verifyOtp: $e");
    return {"message": "Failed to connect to server"};
  }
}

   static Future<String?> syncUser(String supabaseId, String email, String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sync'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'supabaseId': supabaseId,
        'email': email,
        'name': name,
      }),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['userId'] as String; // ✅ now a string UUID
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/$userId'));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    return null;
  }

  /// ✅ Update user profile
  static Future<bool> updateUserProfile(int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("✅ Profile updated for ID $userId");
        return true;
      } else {
        print("❌ Error updating profile: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception updating profile: $e");
      return false;
    }
  }

 /// ------------------- 💥 DEALS OF THE DAY -------------------
static Future<List<Map<String, dynamic>>> getOfferProducts() async {
  final res = await http.get(Uri.parse('$baseUrl/products/offer'));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load offer products');
}

/// ------------------- 🆕 NEW ARRIVALS -------------------
static Future<List<Map<String, dynamic>>> getNewArrivals() async {
  final res = await http.get(Uri.parse('$baseUrl/products/new'));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load new arrivals');
}

/// ------------------- ⭐ TRENDING -------------------
static Future<List<Map<String, dynamic>>> getTrendingProducts() async {
  final res = await http.get(Uri.parse('$baseUrl/products/trending'));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load trending products');
}

/// ------------------- 💌 RECOMMENDED -------------------
static Future<List<Map<String, dynamic>>> getRecommendedProducts(int userId) async {
  final res = await http.get(Uri.parse('$baseUrl/products/recommended?userId=$userId'));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load recommended products');
}

}

  /// Optional: Return parsed product list directly (not needed if using parseItems)
  // static Future<List<Map<String, dynamic>>> getProducts() async {
  //   final jsonString = await getProductsRaw();
  //   return List<Map<String, dynamic>>.from(json.decode(jsonString));
  // }

//   /// ------------------- 🛍️ PRODUCTS -------------------

//   static Future<List<Map<String, dynamic>>> getProducts() async {
//     final res = await http.get(Uri.parse('$baseUrl/products'));
//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       return data.map((e) => Map<String, dynamic>.from(e)).toList();
//     }
//     throw Exception('Failed to load products');
//   }

//   /// ------------------- 📂 CATEGORIES -------------------

//   static Future<List<Map<String, dynamic>>> getCategories() async {
//     final res = await http.get(Uri.parse('$baseUrl/categories'));
//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       return data.map((e) => Map<String, dynamic>.from(e)).toList();
//     }
//     throw Exception('Failed to load categories');
//   }

//   /// ------------------- 📂 SUBCATEGORIES -------------------

//   static Future<List<Map<String, dynamic>>> getSubcategories() async {
//     final res = await http.get(Uri.parse('$baseUrl/subcategories'));
//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       return data.map((e) => Map<String, dynamic>.from(e)).toList();
//     }
//     throw Exception('Failed to load subcategories');
//   }

//   /// ------------------- 🏷️ BRANDS -------------------

//   static Future<List<Map<String, dynamic>>> getBrands() async {
//     final res = await http.get(Uri.parse('$baseUrl/brands'));
//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       return data.map((e) => Map<String, dynamic>.from(e)).toList();
//     }
//     throw Exception('Failed to load brands');
//   }

//   /// ------------------- 📰 NOTIFICATIONS -------------------

//   static Future<List<Map<String, dynamic>>> getNotifications() async {
//     final res = await http.get(Uri.parse('$baseUrl/notifications'));
//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       return data.map((e) => Map<String, dynamic>.from(e)).toList();
//     }
//     throw Exception('Failed to load notifications');
//   }

//   /// ------------------- 🎫 COUPONS -------------------

//   static Future<List<Map<String, dynamic>>> getCoupons() async {
//     final res = await http.get(Uri.parse('$baseUrl/coupons'));
//     if (res.statusCode == 200) {
//       final List data = json.decode(res.body);
//       return data.map((e) => Map<String, dynamic>.from(e)).toList();
//     }
//     throw Exception('Failed to load coupons');
//   }

//   /// ------------------- 📦 ORDERS -------------------

//   static Future<int> createOrder({
//     required int userID,
//     int? couponID,
//     required double totalAmount,
//     required String shippingAddress,
//     required List<Map<String, dynamic>> items,
//   }) async {
//     final res = await http.post(
//       Uri.parse('$baseUrl/orders'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'userID': userID,
//         'couponID': couponID,
//         'totalAmount': totalAmount,
//         'shippingAddress': shippingAddress,
//         'items': items,
//       }),
//     );

//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);
//       return data['orderID'];
//     } else {
//       throw Exception('Failed to create order: ${res.body}');
//     }
//   }

//   static Future<List<dynamic>> getOrders() async {
//     final res = await http.get(Uri.parse('$baseUrl/orders'));
//     if (res.statusCode == 200) {
//       return jsonDecode(res.body);
//     }
//     throw Exception('Failed to load orders: ${res.body}');
//   }
// }
