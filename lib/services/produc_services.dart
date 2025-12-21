import 'dart:convert';

import 'package:Velorex/models/onesolution.dart';
import 'package:Velorex/models/spec_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProductService {
  static const String baseUrl = 'https://velorex-admin-backend.onrender.com/api';

  // ✅ Fetch products (with optional filters)
  static Future<List<Items>> getProducts({int? categoryId, int? subcategoryId}) async {
    try {
      String url = '$baseUrl/products';
      if (categoryId != null || subcategoryId != null) {
        url += '?';
        if (categoryId != null) url += 'categoryId=$categoryId';
        if (subcategoryId != null) {
          if (categoryId != null) url += '&';
          url += 'subcategoryId=$subcategoryId';
        }
      }

      print("🌐 Requesting: $url");

      final response = await http.get(Uri.parse(url));
      print("🌐 Raw response: ${response.body}");
      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<Items> items = await compute(parseItems, response.body);
        print('✅ Parsed items count: ${items.length}');
        return items;
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ProductService error: $e');
      return [];
    }
  }

  // 🔥 NEW: Fetch products by GroupID (full variant group)
  static Future<Map<String, dynamic>?> getProductsByGroup(int groupId) async {
    final url = Uri.parse('$baseUrl/products/by-group/$groupId');
    try {
      print("🌐 Fetching group products: $url");
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print("❌ Failed group fetch: ${response.statusCode}");
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }

      print("❌ Unexpected group response format");
      return null;
    } catch (e) {
      print("❌ getProductsByGroup error: $e");
      return null;
    }
  }

  // 🔥 Fetch product with variants (parent + child variants) – legacy fallback
  static Future<Map<String, dynamic>?> getProductWithVariants(int productId) async {
    final url = Uri.parse('$baseUrl/products/$productId/with-variants');

    try {
      print("🌐 ProductService: GET $url");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print("❌ getProductWithVariants failed (with-variants) ${response.statusCode}");
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      print("❌ Unexpected response format (not a Map)");
      return null;
    } catch (e) {
      print("❌ Error fetching variants: $e");
      return null;
    }
  }

  /// Returns raw JSON string of products
  static Future<String> getProductsRaw() async {
    final url = Uri.parse('$baseUrl/products');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  /// ============================================================
  /// SPECIFICATIONS API
  /// ============================================================

  // 1) Get all spec sections + fields
  static Future<List<SpecSection>> getSpecSectionsWithFields() async {
    final uri = Uri.parse("$baseUrl/products/spec/sections-with-fields");
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load spec sections');
    }

    final decoded = jsonDecode(res.body);

    // backend sends { sections: [...] }
    final List list = decoded['sections'] ?? [];

    return list
        .map((e) => SpecSection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 2) Get existing specs for a product
  static Future<Map<int, String>> getProductSpecs(int productId) async {
    final uri = Uri.parse("$baseUrl/products/spec/product/$productId");
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load product specs');
    }

    final List<dynamic> decoded = jsonDecode(res.body);
    final result = <int, String>{};

    for (final row in decoded) {
      final map = row as Map<String, dynamic>;

      final fid = map['FieldID'] ?? map['fieldId'];
      if (fid == null) continue;

      final fieldId = int.tryParse(fid.toString());
      if (fieldId == null) continue;

      result[fieldId] = (map['Value'] ?? '').toString();
    }

    return result;
  }

  // 3) Save product specs
  static Future<bool> saveProductSpecs({
    required int productId,
    required List<Map<String, dynamic>> specs,
  }) async {
    final uri = Uri.parse("$baseUrl/products/spec/product/save");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "productId": productId,
        "specs": specs,
      }),
    );

    if (res.statusCode != 200) return false;

    final decoded = jsonDecode(res.body);
    return decoded['success'] == true;
  }


}
