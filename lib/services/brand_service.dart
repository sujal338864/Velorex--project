import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:one_solution/models/brand_model.dart';

class BrandService {
  static const String baseUrl = 'http://10.248.214.36:3001/api'; // your backend

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
}
