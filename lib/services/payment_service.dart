import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = "https://velorex-project.onrender.com/api";

  /// ============================================================
  /// 🔵 CREATE PAYMENT ENTRY (Only for online payments)
  /// ============================================================
  static Future<Map<String, dynamic>> createPayment({
    required int orderId,
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    final url = Uri.parse("$baseUrl/payments/create");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "orderId": orderId,
          "userId": userId,
          "amount": amount,
          "paymentMethod": paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "❌ Payment API failed:\n"
          "Status: ${response.statusCode}\n"
          "Body: ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("❌ Payment service error: $e");
    }
  }

  /// ============================================================
  /// 🟣 USER — GET ALL ORDERS
  /// matches backend: res.json({ success: true, data: [...] })
  /// ============================================================
  static Future<List<dynamic>> getOrders(String userId) async {
    final url = Uri.parse("$baseUrl/orders/user/$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// Backend format:
        /// { success: true, data: [...] }
        return data["data"] ?? [];
      } else {
        throw Exception("Failed to fetch user orders: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("❌ Error fetching orders: $e");
    }
  }
}
