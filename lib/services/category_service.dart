import 'dart:convert';
import 'package:Velorex/models/category_model.dart';
import 'package:http/http.dart' as http;


class CategoryService {
 static const String baseUrl = 'http://10.147.205.36:3001/api';


  Future<List<Category>> getCategories() async {
    final url = Uri.parse('$baseUrl/categories');
    print('📡 Fetching categories from: $url');

    final response = await http.get(url);
    print('✅ Status: ${response.statusCode}');
    print('🌐 Body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
    static Future<List<String>> getCategoryImages() async {
    final response = await http.get(Uri.parse('$baseUrl/user/categories'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((cat) => cat['imageUrl'] as String).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
    static Future<List<Map<String, dynamic>>> getAllCoupons() async {
    final res = await http.get(Uri.parse("$baseUrl/coupons"));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    throw Exception("Failed to load coupons");
  }
//   static Future<Map<String, dynamic>?> applyCoupon(String code) async {
//   final res = await http.get(Uri.parse("$baseUrl/coupons/apply/$code"));

//   if (res.statusCode == 200) {
//     return json.decode(res.body);
//   }

//   return null;
// }

 }
