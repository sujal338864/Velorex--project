import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subcategory_model.dart';

class SubcategoryService {
 static const String baseUrl = 'http://10.147.205.36:3001/api';


  static Future<List<Subcategory>> fetchSubcategories(int categoryId) async {
    try {
      final url = '$baseUrl/subcategories?categoryId=$categoryId';
      print("📡 Fetching: $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List decoded = json.decode(response.body);
        print("✅ Loaded ${decoded.length} subcategories");
        return decoded.map((e) => Subcategory.fromMap(e)).toList();
      } else {
        throw Exception('Failed to load subcategories (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error fetching subcategories: $e');
      return [];
    }
  }
}

