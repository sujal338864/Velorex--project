import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  static const String baseUrl = "http://10.248.214.36:3000/api/orders";

  /// =============================================
  /// 🟢 CREATE ORDER (METHOD-2  → Works with 43363)
  /// =============================================
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String paymentMethod,
    required double totalAmount,
    required List<Map<String, dynamic>> cartItems,
    required String shippingAddress,
    required int shippingId,         // 🔥 REQUIRED
    String? couponCode,
    double discountAmount = 0,
  }) async {
    final url = Uri.parse("$baseUrl/create");

    final body = {
      "userId": userId,
      "paymentMethod": paymentMethod,
      "totalAmount": totalAmount,
      "cartItems": cartItems,
      "shippingAddress": shippingAddress,
      "shippingId": shippingId,                // 🔥 SEND shippingId
      "couponCode": couponCode,
      "discountAmount": discountAmount,        // 🔥 MUST SEND FOR METHOD-2
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("📤 ORDER CREATE RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Order failed → ${response.body}");
  }

  /// =============================================
  /// 🟢 GET ALL ORDERS FOR USER
  /// =============================================
  static Future<List<dynamic>> getOrders(String userId) async {
    final url = Uri.parse("$baseUrl/user/$userId");
    final response = await http.get(url);

    print("📥 GET Orders for User: $userId => ${response.statusCode}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json is Map<String, dynamic> && json["success"] == true) {
        return json["data"];
      }

      if (json is List) return json;

      throw Exception("Invalid response format");
    }

    throw Exception("Failed: ${response.statusCode}");
  }

  /// =============================================
  /// 🟢 GET ORDER DETAILS (USER SIDE)
  /// New backend route:
  /// GET /api/orders/user/order/:orderId
  /// =============================================
  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final url = Uri.parse("$baseUrl/user/order/$orderId");
    final response = await http.get(url);

    print("📥 GET Order Details: ${url.toString()} => ${response.statusCode}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json["success"] == true) return json["data"];
      throw Exception("Invalid response format");
    }

    throw Exception("Failed to fetch order details: ${response.statusCode}");
  }

  /// =============================================
  /// 🔴 CANCEL ORDER
  /// =============================================
  static Future<bool> cancelOrder(String orderId) async {
    final url = Uri.parse("$baseUrl/$orderId/cancel");
    final response = await http.put(url);

    print("🛑 Cancel Order $orderId → ${response.statusCode}");

    if (response.statusCode == 200) return true;

    print("❌ Cancel failed: ${response.body}");
    return false;
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
