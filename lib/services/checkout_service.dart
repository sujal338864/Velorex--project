// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class CheckoutService {
//   final String baseUrl = "http://10.147.77.36:<PORT>/api"; // 👈 Replace with your backend URL

//   /// ✅ Create a new order with order items
//   Future<bool> placeOrder({
//     required String userId,
//     required List<Map<String, dynamic>> items,
//     required double totalAmount,
//     required String paymentMethod,
//     required Map<String, dynamic> shippingDetails,
//     String? couponCode,
//   }) async {
//     try {
//       final url = Uri.parse("$baseUrl/orders");

//       // Prepare order payload
//       final Map<String, dynamic> body = {
//         "userId": userId,
//         "paymentMethod": paymentMethod,
//         "totalAmount": totalAmount,
//         "couponCode": couponCode ?? "",
//         "shippingAddress": shippingDetails["address"],
//         "city": shippingDetails["city"],
//         "state": shippingDetails["state"],
//         "country": shippingDetails["country"],
//         "pincode": shippingDetails["pincode"],
//         "phone": shippingDetails["phone"],
//         "items": items, // [{productId, quantity, price}]
//       };

//       print("🧾 Sending order: ${jsonEncode(body)}");

//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );

//       print("📦 Response: ${response.statusCode} - ${response.body}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return true;
//       } else {
//         throw Exception("Failed to place order: ${response.body}");
//       }
//     } catch (e) {
//       print("❌ Checkout error: $e");
//       return false;
//     }
//   }

  
// }
