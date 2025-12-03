// ignore_for_file: deprecated_member_use, unused_element_parameter

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:one_solution/models/addressModel.dart';
import 'package:one_solution/models/cart_item.dart';
import 'package:one_solution/services/Address_services.dart';
import 'package:one_solution/services/profile_services.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final List<CartItem> cartItems;
  final double subtotal;
  final double discount; // MRP savings + coupon discount
  final double delivery;
  final double total;

  // NEW FIELDS ⭐⭐⭐⭐⭐
  final String? couponCode;
  final double couponDiscount;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.cartItems,
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.total,
    this.couponCode,
    this.couponDiscount = 0,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<String, dynamic>? userProfile;
  bool loading = true;

  List<Address> _addresses = [];
  Address? _selectedAddress;

  late List<CartItem> cartItems;
  late double subtotal;
  late double delivery;

  double mrpSavings = 0.0;
  double couponDiscount = 0.0;
  double total = 0.0;

  String selectedPayment = "UPI";
  String? selectedAddressText;

  @override
  void initState() {
    super.initState();

    cartItems = List.from(widget.cartItems);
    subtotal = widget.subtotal;
    delivery = widget.delivery;

    // Calculate MRP savings
    mrpSavings = 0.0;
    for (var item in cartItems) {
      mrpSavings += (item.price - item.offerPrice)
              .clamp(0, double.infinity) *
          item.quantity;
    }

    // Get coupon discount from CartPage
    couponDiscount = widget.couponDiscount;

    total = subtotal - couponDiscount + delivery;

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => loading = true);

      final profile = await ProfileService.getUserProfile(widget.userId);
      final savedAddresses =
          await AddressService.fetchAddresses(widget.userId);

      setState(() {
        userProfile = profile;
        _addresses = savedAddresses;

        if (_addresses.isNotEmpty) {
          _selectedAddress = _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.first,
          );

          selectedAddressText =
              "${_selectedAddress!.address}, ${_selectedAddress!.city}, ${_selectedAddress!.state}, ${_selectedAddress!.country} - ${_selectedAddress!.pincode}";
        }

        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Checkout", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _etaSection(),
                  const SizedBox(height: 20),
                  _addressSection(),
                  const SizedBox(height: 20),
                  _summaryCard(),
                  const SizedBox(height: 20),
                  _cartItems(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: _bottomBar(themeColor),
    );
  }

  // -------------------------------------------------------
  // ADDRESS SECTION
  // -------------------------------------------------------
  Widget _addressSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Delivery Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (_addresses.isNotEmpty)
              ..._addresses.map((address) {
                final addressString =
                    "${address.address}, ${address.city}, ${address.state}, ${address.country} - ${address.pincode}";

                return RadioListTile<String>(
                  value: addressString,
                  groupValue: selectedAddressText,
                  title: Text(address.name),
                  subtitle: Text(addressString),
                  onChanged: (value) {
                    setState(() {
                      selectedAddressText = value!;
                      _selectedAddress = address;
                    });
                  },
                );
              }),

            if (_addresses.isEmpty)
              const Text("No saved addresses.",
                  style: TextStyle(color: Colors.grey)),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showAddAddressDialog,
                icon:
                    const Icon(Icons.add_location_alt, color: Colors.redAccent),
                label: const Text("Add Address",
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // ETA SECTION
  // -------------------------------------------------------
  Widget _etaSection() {
    final eta = DateTime.now().add(const Duration(days: 4));
    final etaText = "${eta.day}/${eta.month}/${eta.year}";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Estimated Delivery by $etaText",
              style: const TextStyle(
                fontSize: 15,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // CART ITEMS SECTION
  // -------------------------------------------------------
  Widget _cartItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Items in Your Cart",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...cartItems.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(item.productName),
                subtitle: Text(
                  "₹${item.offerPrice} x${item.quantity} = ₹${(item.offerPrice * item.quantity).toStringAsFixed(2)}",
                ),
              ),
            )),
      ],
    );
  }

  // -------------------------------------------------------
  // SUMMARY SECTION
  // -------------------------------------------------------
  Widget _summaryCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _billRow("Subtotal", "₹${subtotal.toStringAsFixed(2)}"),
            _billRow("MRP Savings", "-₹${mrpSavings.toStringAsFixed(2)}",
                color: Colors.green),

            if (couponDiscount > 0)
              _billRow("Coupon Discount", "-₹${couponDiscount.toStringAsFixed(2)}",
                  color: Colors.green),

            _billRow("Delivery", "₹${delivery.toStringAsFixed(2)}"),

            const Divider(),

            _billRow("Total Amount", "₹${total.toStringAsFixed(2)}",
                isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  color: color ?? Colors.black,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // BOTTOM BUTTON
  // -------------------------------------------------------
  Widget _bottomBar(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            minimumSize: const Size(double.infinity, 50)),
        onPressed: _selectedAddress == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentPage(
                      userId: widget.userId,
                      totalAmount: total,
                      cartItems: cartItems,
                      selectedAddressId: _selectedAddress!.id,
                      selectedAddress: selectedAddressText ?? "",
                      couponCode: widget.couponCode,
                      discountAmount: couponDiscount, // <-- PASSED TO BACKEND
                    ),
                  ),
                );
              },
        child: Text(
          "Proceed to Pay ₹${total.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // ADD ADDRESS POPUP
  // -------------------------------------------------------
  void _showAddAddressDialog() {
    final key = GlobalKey<FormState>();

    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Address"),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: "Address")),
              TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: "City")),
              TextFormField(
                  controller: stateCtrl,
                  decoration: const InputDecoration(labelText: "State")),
              TextFormField(
                  controller: countryCtrl,
                  decoration: const InputDecoration(labelText: "Country")),
              TextFormField(
                  controller: pincodeCtrl,
                  decoration: const InputDecoration(labelText: "Pincode")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newAddress = {
                "name": userProfile?['name'] ?? "User",
                "mobile": userProfile?['phone'] ?? "",
                "address": addressCtrl.text,
                "city": cityCtrl.text,
                "state": stateCtrl.text,
                "country": countryCtrl.text,
                "pincode": pincodeCtrl.text,
                "isDefault": true
              };

              await AddressService.addAddress(widget.userId, newAddress);
              await _loadUserData();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
