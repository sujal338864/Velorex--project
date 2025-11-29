import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  static const String baseUrl = "http://10.248.214.36:3000/api/orders";

  /// ✅ Create a new order
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required double totalAmount,
    required String paymentMethod,
    required String shippingAddress,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final url = Uri.parse("$baseUrl/create");

    final bodyData = {
      "userId": userId,
      "totalAmount": totalAmount,
      "paymentMethod": paymentMethod,
      "shippingAddress": shippingAddress,
      "cartItems": cartItems,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(bodyData),
    );

    print("📤 POST: ${url.toString()}");
    print("📦 Body: ${jsonEncode(bodyData)}");
    print("🔍 Response: ${response.statusCode} => ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to create order: ${response.statusCode}\n${response.body}");
    }
  }

  /// ✅ Get all orders for a specific user
  static Future<List<dynamic>> getOrders(String userId) async {
    final url = Uri.parse("$baseUrl/user/$userId");
    final response = await http.get(url);

    print("📥 GET Orders for User: $userId => ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data["success"] == true && data["data"] != null) {
        return data["data"];
      } else {
        throw Exception("Invalid response format");
      }
    } else {
      throw Exception("Failed to fetch user orders: ${response.statusCode}");
    }
  }

  /// ✅ Get details for a specific order (with items)
  static Future<Map<String, dynamic>> getOrderDetails(
      int orderId, String userId) async {
    final url = Uri.parse("$baseUrl/$orderId/$userId");
    final response = await http.get(url);

    print("📥 GET Order Details: ${url.toString()} => ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        throw Exception("Invalid response data for order details");
      }
    } else {
      throw Exception("Failed to fetch order details: ${response.statusCode}");
    }
  }

  /// ✅ Cancel an order
  static Future<bool> cancelOrder(String orderId) async {
    final url = Uri.parse("$baseUrl/$orderId/cancel");
    final response = await http.put(url);

    print("🛑 Cancel Order $orderId => ${response.statusCode}");

    if (response.statusCode == 200) {
      return true;
    } else {
      print("❌ Cancel failed: ${response.body}");
      return false;
    }
  }
  
}
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class OrderService {
//   static const String baseUrl = "http://10.147.77.36:3000/api/orders";
  
//   static Future<Map<String, dynamic>> createOrder({
//     required String userId,
//     required double totalAmount,
//     required String paymentMethod,
//      required String shippingAddress,
//     required List<Map<String, dynamic>> cartItems, // ✅ correct param name
//   }) async {
//     final url = Uri.parse("$baseUrl/create"); // ✅ correct endpoint

//     final bodyData = {
//       "userId": userId,
//       "totalAmount": totalAmount,
//       "paymentMethod": paymentMethod,
//        "shippingAddress": shippingAddress,
//       "cartItems": cartItems, // ✅ correct key matches backend
//     };

//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(bodyData),
//     );

//     print("📤 POST: ${url.toString()}");
//     print("📦 Body: ${jsonEncode(bodyData)}");
//     print("🔍 Response: ${response.statusCode} => ${response.body}");

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception(
      
//         "Failed to create order: ${response.statusCode}\n${response.body}",
//       );
//     }
//   }

// static Future<List<dynamic>> getOrders(String userId) async {
//   final url = Uri.parse("$baseUrl/user/$userId");
//   final response = await http.get(url);

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     if (data["success"] == true) {
//       return data["data"] ?? [];
//     } else {
//       throw Exception("API returned error: ${data["message"]}");
//     }
//   } else {
//     throw Exception("Failed to fetch user orders: ${response.statusCode}");
//   }
// }

//   static Future<bool> cancelOrder(String orderId) async {
//     final url = Uri.parse("$baseUrl/$orderId/cancel");
//     final response = await http.put(url);

//     if (response.statusCode == 200) {
//       return true;
//     } else {
//       print("❌ Cancel failed: ${response.body}");
//       return false;
//     }
//   }

// }
