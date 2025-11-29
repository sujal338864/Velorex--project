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


  const PaymentPage({
    super.key,
    required this.userId,
    required this.totalAmount,
    required this.cartItems,
    this.selectedAddress,
      required this.selectedAddressId,
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
    _loadUserAddress();
  }
Future<void> _loadUserAddress() async {
  try {
    if (widget.selectedAddress != null && widget.selectedAddress!.isNotEmpty) {
      // Use the selected address from checkout
      setState(() => shippingAddress = widget.selectedAddress!);
    } else {
      // Fallback message
      setState(() => shippingAddress = "No shipping address selected");
    }
  } catch (e) {
    setState(() => shippingAddress = "Error loading address");
  }
}


Future<void> _processPayment() async {
  setState(() => isProcessing = true);

  try {
    await Future.delayed(const Duration(seconds: 2));

    // ✅ Prepare cart items correctly
    final cartItemsPayload = widget.cartItems.map((item) => {
         "productId": item.productId, // ✅ use real product ID from database
          "quantity": item.quantity,
          "price": item.offerPrice > 0 ? item.offerPrice : item.price, // use offerPrice if exists
        }).toList();

    // ✅ Send order to backend
    final orderResult = await OrderService.createOrder(
      userId: widget.userId,
      totalAmount: widget.totalAmount,
      paymentMethod: selectedPayment,
      shippingAddress: shippingAddress,
      cartItems: cartItemsPayload,
    );

    if (orderResult["success"] == true) {
      final orderId = orderResult["orderId"] ?? 0;

      // ✅ Record payment (only for non-COD)
      if (selectedPayment != "Cash on Delivery") {
        await PaymentService.createPayment(
          orderId: orderId,
          userId: widget.userId,
          amount: widget.totalAmount,
          paymentMethod: selectedPayment,
        );
      }

      // ✅ Clear user cart after successful order
      await CartService.clearCart(widget.userId);

      // ✅ Go to success page
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            orderId: orderId.toString(),
            paymentMethod: selectedPayment,
            totalAmount: widget.totalAmount,
            cartItems: widget.cartItems,
          ),
        ),
      );
    } else {
      throw Exception(orderResult["message"] ?? "Order creation failed");
    }
  } catch (e, s) {
    debugPrint("❌ Order failed: $e\n$s");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order failed: $e")),
      
    );
    print("🛒 Cart items being sent: ${widget.cartItems.map((i) => i.id).toList()}");

  } finally {
    setState(() => isProcessing = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fb),
      appBar: AppBar(
        title: const Text("Payment",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 💰 Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.deepPurple, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Payable Amount",
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    "₹${widget.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🏠 Address
            Text("Shipping Address",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.deepPurple.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                shippingAddress.isNotEmpty
                    ? shippingAddress
                    : "Loading address...",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            // 💳 Payment Methods
            const Text("Select Payment Method",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            ...paymentMethods.map((method) => RadioListTile<String>(
                  value: method["name"],
                  groupValue: selectedPayment,
                  activeColor: Colors.deepPurple,
                  onChanged: (val) => setState(() => selectedPayment = val!),
                  title: Row(
                    children: [
                      Icon(method["icon"], color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      Text(method["name"]),
                    ],
                  ),
                )),
          ],
        ),
      ),

      // ✅ Bottom button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
