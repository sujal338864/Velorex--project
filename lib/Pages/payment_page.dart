import 'package:flutter/material.dart';
import 'package:one_solution/models/cart_item.dart';
import 'package:one_solution/services/cartService.dart';
import 'package:one_solution/services/order_service.dart';
import 'package:one_solution/services/payment_service.dart';
import 'package:one_solution/Pages/OrderSuccessPage.dart';

class PaymentPage extends StatefulWidget {
  final String userId;
  final double totalAmount;
  final List<CartItem> cartItems;

  final String? selectedAddress;
  final int selectedAddressId;

  final String? couponCode;
  final double discountAmount;

  const PaymentPage({
    super.key,
    required this.userId,
    required this.totalAmount,
    required this.cartItems,
    this.selectedAddress,
    required this.selectedAddressId,
    this.couponCode,
    this.discountAmount = 0,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPayment = "UPI";
  bool isProcessing = false;
  String shippingAddress = "";

  final List<Map<String, dynamic>> paymentMethods = [
    {"name": "UPI", "icon": Icons.qr_code_2},
    {"name": "Credit Card", "icon": Icons.credit_card},
    {"name": "Debit Card", "icon": Icons.credit_card_outlined},
    {"name": "Net Banking", "icon": Icons.account_balance},
    {"name": "EMI", "icon": Icons.payments_outlined},
    {"name": "Cash on Delivery", "icon": Icons.delivery_dining},
  ];

  @override
  void initState() {
    super.initState();
    shippingAddress = widget.selectedAddress ?? "No address selected";
  }

  Future<void> _processPayment() async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 200));

      // -------------------------
      // 🟣 Prepare payload
      // -------------------------
      final cartItemsPayload = widget.cartItems.map((item) {
        return {
          "productId": item.productId,
          "quantity": item.quantity,
          "price": item.price,
          "offerPrice": item.offerPrice,
        };
      }).toList();

      print("🟢 Sending coupon discount: ${widget.discountAmount}");

      // -------------------------
      // 🟣 Create Order(s)
      // -------------------------
      final orderRes = await OrderService.createOrder(
        userId: widget.userId,
        totalAmount: widget.totalAmount,
        paymentMethod: selectedPayment,
        shippingAddress: shippingAddress,
        shippingId: widget.selectedAddressId,
        cartItems: cartItemsPayload,
        couponCode: widget.couponCode,
        discountAmount: widget.discountAmount,
      );

      print("📦 ORDER RESPONSE: $orderRes");

      // Extract multiple orderIds
      final List<dynamic> ids = orderRes["orderIds"] ?? [];
      final List<String> orderIds =
          ids.map((e) => e.toString()).toList();

      if (orderIds.isEmpty) {
        throw "Order creation failed (no IDs returned)";
      }

      // -------------------------
      // 🟣 Payment Record (non-COD)
      // -------------------------
      if (selectedPayment != "Cash on Delivery") {
        for (var id in orderIds) {
          await PaymentService.createPayment(
            orderId: int.parse(id),
            userId: widget.userId,
            amount: widget.totalAmount, 
            paymentMethod: selectedPayment,
          );
        }
      }

      // -------------------------
      // 🟣 Clear Cart
      // -------------------------
      await CartService.clearCart(widget.userId);

      if (!mounted) return;

      // -------------------------
      // 🟣 Navigate → Success
      // -------------------------
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            orderIds: orderIds, // 🔥 Multiple order IDs
            paymentMethod: selectedPayment,
            totalAmount: widget.totalAmount,
            cartItems: widget.cartItems,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Order failed: $e")));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fb),
      appBar: AppBar(
        title: const Text("Payment", style: TextStyle(color: Colors.black)),
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ------------------------------
            // 🟣 Payable Amount
            // ------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.deepPurple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Payable Amount",
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "₹${widget.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------
            // 🟣 Shipping Address
            // ------------------------------
            const Text("Shipping Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.deepPurple.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(shippingAddress),
            ),

            const SizedBox(height: 20),

            // ------------------------------
            // 🟣 Payment Method
            // ------------------------------
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ...paymentMethods.map(
              (method) => RadioListTile<String>(
                value: method["name"],
                groupValue: selectedPayment,
                activeColor: Colors.deepPurple,
                onChanged: (value) => setState(() => selectedPayment = value!),
                title: Row(
                  children: [
                    Icon(method["icon"], color: Colors.deepPurple),
                    const SizedBox(width: 10),
                    Text(method["name"]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ------------------------------
      // 🟣 Bottom Pay Button
      // ------------------------------
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            minimumSize: const Size(double.infinity, 55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: isProcessing ? null : _processPayment,
          child: isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  selectedPayment == "Cash on Delivery"
                      ? "Place Order (COD)"
                      : "Pay ₹${widget.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
