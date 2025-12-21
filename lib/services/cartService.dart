import 'dart:convert';
import 'package:Velorex/models/cart_item.dart';
import 'package:Velorex/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class CartService {
  static const String baseUrl = "https://velorex-project.onrender.com/api/cart"; // ✅ your backend base URL

static Future<List<CartItem>> fetchCart(String userId) async {
  final url = '$baseUrl/$userId';
  debugPrint("📡 Fetching cart from: $url");
  
  final response = await http.get(Uri.parse(url));

  debugPrint("📦 Response (${response.statusCode}): ${response.body}");

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => CartItem.fromJson(e)).toList();
  } else {
    throw Exception("Failed to fetch cart");
  }
}
static Future<List<dynamic>> getCartItems(String userId) async {
  final url = Uri.parse('${ApiService.baseUrl}/cart?userId=$userId');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    print("❌ Failed to refresh cart: ${response.statusCode}");
    return [];
  }
}


  static Future<bool> addToCart(String userId, int productId, int quantity) async {
    final url = Uri.parse(baseUrl); // ✅ NO extra /cart
    debugPrint("📤 Adding to cart: $url | $userId | $productId x $quantity");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        }),
      );

      debugPrint("🧾 Add to cart response: ${response.statusCode} | ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error adding to cart: $e");
      return false;
    }
  }

  static Future<void> updateQuantity(int cartId, int quantity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cartId': cartId, 'quantity': quantity}),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update cart quantity: ${response.body}");
    }
  }

  static Future<void> removeFromCart(int cartId) async {
    final response = await http.delete(Uri.parse('$baseUrl/remove/$cartId'));
    if (response.statusCode != 200) {
      throw Exception("Failed to remove item from cart: ${response.body}");
    }
  }
  static Future<bool> clearCart(String userId) async {
  final url = Uri.parse("${ApiService.baseUrl}/cart/clear/$userId");
  final res = await http.post(url);
  return res.statusCode == 200;
}

}


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/cart_item.dart';

// class CartService {
//   static const String baseUrl = "http://10.147.77.36:3000/api/cart";

//   static Future<List<CartItem>> fetchCart(String userId) async {
//     final response = await http.get(Uri.parse('$baseUrl/$userId'));

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body) as List;
//       return data.map((e) => CartItem.fromJson(e)).toList();
//     } else {
//       throw Exception("Failed to fetch cart: ${response.body}");
//     }
//   }

// static Future<void> addToCart(String userId, int productId, int quantity) async {
//   final response = await http.post(
//     Uri.parse(baseUrl), // should be 'http://10.x.x.x:3000/api/cart'
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode({
//       'userId': userId,
//       'productId': productId,
//       'quantity': quantity,
//     }),
//   );

//   if (response.statusCode != 200) {
//     throw Exception('Failed to add to cart: ${response.body}');
//   }
// }

//   // ✅ Fetch cart by userId
// // static Future<List<CartItem>> fetchCart(String userId) async {
// //   final response = await http.get(Uri.parse('$baseUrl/$userId'));
// //   print("🧾 API URL: $baseUrl/$userId");
// //   print("🔍 Response code: ${response.statusCode}");
// //   print("📦 Body: ${response.body}");

// //   if (response.statusCode == 200) {
// //     final data = jsonDecode(response.body) as List;
// //     return data.map((e) => CartItem.fromJson(e)).toList();
// //   } else {
// //     throw Exception("Failed to fetch cart: ${response.body}");
// //   }
// // }


// //   // ✅ Add product to cart
// //   static Future<void> addToCart(String userId, int productId) async {
// //     final response = await http.post(
// //       Uri.parse('$baseUrl/add'),
// //       headers: {'Content-Type': 'application/json'},
// //       body: jsonEncode({'userId': userId, 'productId': productId}),
// //     );
// //     if (response.statusCode != 200) {
// //       throw Exception('Failed to add item to cart');
// //     }
// //   }

//   // ✅ Remove product from cart
//   static Future<void> removeFromCart(int productId, String userId) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/remove'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'userId': userId, 'productId': productId}),
//     );
//     if (response.statusCode != 200) {
//       throw Exception('Failed to remove item');
//     }
//   }
// }

