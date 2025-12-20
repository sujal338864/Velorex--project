import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/onesolution.dart'; // ✅ your product/item model

class SavedForLaterService {
  static const String baseUrl = "http://10.147.205.36:3000/api/savedforlater";

  // 🔹 Get saved items
  static Future<List<Items>> getSavedItems(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId'));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => Items.fromMap(item)).toList();
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to load saved items: $e");
    }
  }

  // 🔹 Move item from cart → saved
  static Future<void> moveToSaved(String userId, String productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/move-to-saved'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "productId": productId}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to move item to saved");
    }
  }

  // 🔹 Move item from saved → cart
  static Future<void> moveToCart(String userId, String productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/move-to-cart'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "productId": productId}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to move item to cart");
    }
  }

  // 🔹 Delete item from saved
  static Future<void> deleteSavedItem(String userId, String productId) async {
    final response = await http.delete(Uri.parse('$baseUrl/$userId/$productId'));

    if (response.statusCode != 200) {
      throw Exception("Failed to delete saved item");
    }
  }
}
