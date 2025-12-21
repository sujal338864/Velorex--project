import 'dart:convert';
import 'package:http/http.dart' as http;

class CouponService {
  // Correct base URL
  static const String baseUrl = "https://velorex-project.onrender.com/api";

  static Future<Map<String, dynamic>?> applyCoupon(String code) async {
    final url = Uri.parse("$baseUrl/coupons/apply/$code");

    print("📡 Calling: $url");

    final res = await http.get(url);

    print("Status: ${res.statusCode}");
    print("Body: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }
}
