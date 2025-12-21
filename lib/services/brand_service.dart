import 'dart:convert';
import 'package:Velorex/models/brand_model.dart';
import 'package:http/http.dart' as http;


class BrandService {
 static const String baseUrl = 'https://velorex-admin-backend.onrender.com/api';

  Future<List<Brand>> getBrands() async {
    final url = Uri.parse('$baseUrl/brands');
    print('📡 Fetching brands from: $url');

    final response = await http.get(url);
    print('🌐 Brand response: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Brand.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load brands');
    }
  }

    /// ------------------- 🖼️ POSTERS -------------------
static Future<List<Map<String, dynamic>>> getPosters() async {
  final res = await http.get(Uri.parse('$baseUrl/posters'));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  throw Exception('Failed to load posters');
}

}
