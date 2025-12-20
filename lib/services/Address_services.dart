import 'dart:convert';
import 'package:Velorex/models/addressModel.dart';
import 'package:http/http.dart' as http;

class AddressService {
  // ✅ Independent backend for addresses
  static const String baseUrl = 'http://10.147.205.36:3000/api/address';

  // 🔹 Fetch all addresses for a user

  // ✅ Fetch all addresses for a specific user
  static Future<List<Address>> fetchAddresses(String userId) async {
    final url = Uri.parse('$baseUrl/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Address.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      // If user has no addresses, return empty list
      return [];
    } else {
      throw Exception('Failed to load addresses: ${response.statusCode}');
    }
  }

  // ✅ Add new address
  // static Future<void> addAddress(String userId, Map<String, dynamic> address) async {
  //   final url = Uri.parse('$baseUrl/$userId');
  //   final response = await http.post(
  //     url,
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(address),
  //   );

  //   if (response.statusCode != 201 && response.statusCode != 200) {
  //     throw Exception('Failed to add address: ${response.statusCode}');
  //   }
  // }

  // 🔹 Update existing address
  static Future<void> updateAddress(int addressId, Map<String, dynamic> address) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/$addressId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(address),
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to update address: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print("AddressService.updateAddress error: $e");
      rethrow;
    }
  }

  // 🔹 Delete address
  static Future<void> deleteAddress(int addressId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/$addressId'));

      if (res.statusCode != 200) {
        throw Exception('Failed to delete address: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print("AddressService.deleteAddress error: $e");
      rethrow;
    }
  }
  static Future<void> addAddress(String userId, Map<String, dynamic> address) async {
  final url = Uri.parse('$baseUrl/$userId');
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(address),
  );

  if (response.statusCode != 201 && response.statusCode != 200) {
    print('❌ Failed to add address: ${response.statusCode}');
    print('Response body: ${response.body}');
    throw Exception('Failed to add address: ${response.statusCode}');
  } else {
    print('✅ Address added successfully: ${response.body}');
  }
}
}