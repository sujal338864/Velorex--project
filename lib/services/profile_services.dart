import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  // 🌐 Your backend base URL
  static const String baseUrl = "https://velorex-project.onrender.com/api/profile";

  // 🔹 Sync user (login/signup)
  static Future<String?> syncUser(String supabaseId, String email, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": supabaseId,
          "email": email,
          "name": name,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("✅ User synced successfully: ${data['userId']}");
        return data['userId'].toString();
      } else {
        print("❌ Sync failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔥 Sync error: $e");
      return null;
    }
  }

  // 🔹 Fetch user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        print("⚠️ User not found");
        return null;
      } else {
        throw Exception('Failed to load user profile: ${response.body}');
      }
    } catch (e) {
      print("🔥 Error getting user profile: $e");
      return null;
    }
  }


  // 🔹 Create a new user profile (first-time)
  static Future<void> createUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to create user: ${response.body}');
      }

      print("✅ User profile created successfully");
    } catch (e) {
      print("🔥 Create profile error: $e");
      rethrow;
    }
  }

  // 🔹 Update existing user profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }

      print("✅ Profile updated successfully for user $userId");
    } catch (e) {
      print("🔥 Update profile error: $e");
      rethrow;
    }
  }
    /// Add a new address for the user
  /// address should contain:
  /// { name, mobile, address, city, state, country, pincode, isDefault }
static Future<void> addAddress(String userId, Map<String, dynamic> body) async {
  final url = Uri.parse('http://<your_ip>:3000/api/address/$userId'); // ✅ correct
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode != 201) {
    throw Exception('Failed to add address: ${response.statusCode} ${response.body}');
  }
}

}
