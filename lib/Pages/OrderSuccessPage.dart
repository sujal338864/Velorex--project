import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:one_solution/Pages/OrdersPage.dart';
import 'package:one_solution/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final String paymentMethod;
  final double totalAmount;
  final List<CartItem>? cartItems;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.paymentMethod,
    required this.totalAmount,
    this.cartItems,
  });

  String getFormattedDate() {
    return DateFormat('EEE, d MMM yyyy, hh:mm a').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id; // ✅ fetch current logged-in user's ID

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Order Confirmed!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                "Your order has been placed successfully.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
              ),
              const SizedBox(height: 20),

              // ✅ Order Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order ID: $orderId"),
                    Text("Payment: $paymentMethod"),
                    Text("Total: ₹${totalAmount.toStringAsFixed(2)}"),
                    Text("Date: ${getFormattedDate()}"),
                  ],
                ),
              ),

              // ✅ Ordered Items (if available)
              if (cartItems != null && cartItems!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Ordered Items",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = cartItems![i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(item.imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported),
                      ),
                      title: Text(item.productName,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text("Qty: ${item.quantity}"),
                      trailing: Text(
                          "₹${(item.price * item.quantity).toStringAsFixed(2)}"),
                    );
                  },
                ),
              ],

              const SizedBox(height: 30),

              // ✅ "View My Orders" Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (userId != null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
builder: (_) => OrdersPage(userId: userId),

                      ),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please log in to view orders.")),
                    );
                  }
                },
                child: const Text(
                  "View My Orders",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Continue Shopping"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
