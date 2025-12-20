import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://10.147.205.36:3001/api';

  static Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final url = '$baseUrl/notifications';
      print('📡 Fetching: $url');

      final response = await http.get(Uri.parse(url));

      print('📦 Response Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List decoded = json.decode(response.body);
        print("✅ Loaded ${decoded.length} notifications");
        return decoded;
      } else {
        print("⚠️ Failed to load notifications (${response.statusCode})");
        return [];
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }
}
