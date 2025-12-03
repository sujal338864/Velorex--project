import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:one_solution/Pages/OrdersPage.dart';
import 'package:one_solution/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class OrderSuccessPage extends StatefulWidget {
  final List<String> orderIds;
  final String paymentMethod;
  final double totalAmount;
  final List<CartItem> cartItems;   // 🟢 Added

  const OrderSuccessPage({
    super.key,
    required this.orderIds,
    required this.paymentMethod,
    required this.totalAmount,
    required this.cartItems,         // 🟢 Added
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  bool isLoading = true;
  List<dynamic> orderItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (widget.orderIds.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final id = widget.orderIds.first;
      final url = Uri.parse("http://10.248.214.36:3000/api/orders/$id");

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          orderItems = data["items"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String formatDate() {
    return DateFormat('EEE, d MMM yyyy • hh:mm a').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 110),
                    const SizedBox(height: 20),
                    const Text("Order Confirmed!",
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Your order has been placed successfully.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700)),
                    const SizedBox(height: 25),

                    // Summary
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order IDs: ${widget.orderIds.join(", ")}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text("Payment: ${widget.paymentMethod}"),
                          Text(
                              "Total Paid: ₹${widget.totalAmount.toStringAsFixed(2)}"),
                          Text("Date: ${formatDate()}"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Ordered Items
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderItems.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final item = orderItems[i];

                        final String name =
                            (item["name"] ?? item["productName"] ?? "Product")
                                .toString();

                        final int qty =
                            int.tryParse(item["quantity"].toString()) ?? 1;

                        final double finalAmount =
                            double.tryParse(item["finalAmount"].toString()) ??
                                0.0; // 🟢 REAL FINAL AMOUNT

                        final String img = (item["image"] ??
                                (item["imageUrls"] != null &&
                                        item["imageUrls"] is List &&
                                        item["imageUrls"].isNotEmpty
                                    ? item["imageUrls"][0]
                                    : null) ??
                                "https://via.placeholder.com/300")
                            .toString();

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xfff8f9fb),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  img,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16)),
                                    Text("Qty: $qty",
                                        style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text("₹${finalAmount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          minimumSize: const Size(260, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: () {
                        if (userId != null) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => OrdersPage(userId: userId)),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text("View My Orders",
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text("Continue Shopping",
                          style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
