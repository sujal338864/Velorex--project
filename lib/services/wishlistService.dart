import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:one_solution/models/onesolution.dart';

class WishlistService {
  // ✅ Base URL (update IP when backend changes)
  static const String baseUrl = "http://10.248.214.36:3000/api/wishlist";

  // ================================================================
  // 🔹 GET Wishlist
  // ================================================================
  static Future<List<Items>> getWishlist(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Items.fromMap(Map<String, dynamic>.from(json)))
            .toList();
      } else {
        print('❌ Failed to load wishlist: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('⚠️ Wishlist fetch error: $e');
      return [];
    }
  }

  // ================================================================
  // 🔹 ADD to Wishlist
  // ================================================================
  static Future<bool> addToWishlist(String userId, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'productId': productId}),
      );

      if (response.statusCode == 200) {
        print('✅ Added to wishlist');
        return true;
      } else {
        print('❌ Add failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Add to wishlist error: $e');
      return false;
    }
  }

  // ================================================================
  // 🔹 REMOVE from Wishlist
  // ================================================================
  static Future<bool> removeFromWishlist(String userId, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/remove'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'productId': productId}),
      );

      if (response.statusCode == 200) {
        print('✅ Removed from wishlist');
        return true;
      } else {
        print('❌ Remove failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Remove wishlist error: $e');
      return false;
    }
  }

  // ================================================================
  // 🔹 CLEAR Wishlist (Optional - for admin/user cleanup)
  // ================================================================
  static Future<bool> clearWishlist(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Clear wishlist error: $e');
      return false;
    }
  }
}
