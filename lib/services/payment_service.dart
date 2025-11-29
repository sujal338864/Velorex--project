import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = "http://10.248.214.36:3000/api";

  static Future<Map<String, dynamic>> createPayment({
    required int orderId,
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    final url = Uri.parse("$baseUrl/payments/create");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
        "Failed to create payment: ${response.statusCode}\n${response.body}",
      );
    }
  }

static Future<List<dynamic>> getOrders(String userId) async {
  final url = Uri.parse("$baseUrl/user/$userId");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["data"] ?? []; // ✅ fix: match backend key
  } else {
    throw Exception("Failed to fetch user orders");
  }
}

}
