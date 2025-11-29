import 'dart:convert';
import 'package:http/http.dart' as http;

class RecentlyViewedService {
  static const String baseUrl = "http://10.248.214.36:3000/api/recentlyviewed";

  static Future<void> addViewed(String userId, int productId) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "productId": productId}),
    );
  }

  static Future<List<dynamic>> getViewed(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/$userId"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to fetch viewed items");
  }
}
