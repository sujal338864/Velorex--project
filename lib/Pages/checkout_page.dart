// ignore_for_file: deprecated_member_use, unused_element_parameter

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:one_solution/models/addressModel.dart';
import 'package:one_solution/models/cart_item.dart';
import 'package:one_solution/services/Address_services.dart';
import 'package:one_solution/services/cartService.dart';
import 'package:one_solution/services/profile_services.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final List<CartItem> cartItems;
  final double subtotal;
  final double discount;
  final double delivery;
  final double total;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.cartItems,
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.total,
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
  late double discount;
  late double delivery;
  late double total;

  String selectedPayment = "UPI";
  String? selectedAddress;

  // final List<Map<String, dynamic>> paymentMethods = [
  //   {"name": "UPI", "icon": Icons.qr_code_2},
  //   {"name": "Credit Card", "icon": Icons.credit_card},
  //   {"name": "Debit Card", "icon": Icons.credit_card_outlined},
  //   {"name": "Net Banking", "icon": Icons.account_balance},
  //   {"name": "EMI", "icon": Icons.payments},
  //   {"name": "Cash on Delivery", "icon": Icons.local_shipping},
  // ];

  @override
  void initState() {
    super.initState();
    cartItems = List.from(widget.cartItems);
    subtotal = widget.subtotal;
    discount = widget.discount;
    delivery = widget.delivery;
    total = subtotal + delivery;
    _loadUserData();
  }

// Future<void> _addNewAddress(Map<String, dynamic> newAddress) async {
//   try {
//     await AddressService.addAddress(widget.userId, newAddress);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("✅ Address added successfully")),
//     );

//     // 🔁 Refresh address list immediately
//     await _loadUserData();
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("❌ Failed to add address: $e")),
//     );
//   }
// }

 Future<void> _loadUserData({bool refresh = false}) async {
  try {
    setState(() => loading = true);

    final profile = await ProfileService.getUserProfile(widget.userId);
List<Address> savedAddresses = [];
try {
  savedAddresses = await AddressService.fetchAddresses(widget.userId);
} catch (e) {
  // if 500 or no address, just continue with empty list
  debugPrint("⚠️ No saved addresses found or error fetching: $e");
  savedAddresses = [];
}

    setState(() {
      userProfile = profile;
      _addresses = savedAddresses;

      if (_addresses.isNotEmpty) {
        _selectedAddress = _addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _addresses.first,
        );

        selectedAddress =
            "${_selectedAddress!.address}, ${_selectedAddress!.city}, ${_selectedAddress!.state}, ${_selectedAddress!.country} - ${_selectedAddress!.pincode}";
      }

      loading = false;
    });
  } catch (e) {
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading user info: $e')),
    );
  }
}


  void _removeItem(CartItem item) async {
    try {
      await CartService.removeFromCart(item.id);
      setState(() {
        cartItems.removeWhere((c) => c.id == item.id);
        _recalculateTotals();
      });
      Navigator.pop(context, cartItems);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to remove item: $e')));
    }
  }

  void _recalculateTotals() {
    double subtotalSum = 0;
    double discountSum = 0;

    for (var item in cartItems) {
      subtotalSum += item.offerPrice * item.quantity;
      discountSum += (item.price - item.offerPrice)
          .clamp(0, double.infinity) *
          item.quantity;
    }

    double newTotal = subtotalSum + delivery;

    setState(() {
      subtotal = subtotalSum;
      discount = discountSum;
      total = newTotal;
    });
  }

  String getEtaDate() {
    final now = DateTime.now();
    final eta = now.add(const Duration(days: 4));
    return "${eta.day}/${eta.month}/${eta.year}";
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 156, 140, 140),
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
                  _buildEtaSection(),
                  const SizedBox(height: 20),
                  _buildAddressSection(),
                  const SizedBox(height: 20),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildCartItemsSection(),
                  const SizedBox(height: 20),
                  // _buildPaymentSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(themeColor),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delivery Address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_addresses.isNotEmpty)
              ..._addresses.map((address) {
                final addressString =
                    "${address.address}, ${address.city}, ${address.state}, ${address.country} - ${address.pincode}";
                return RadioListTile<String>(
                  value: addressString,
                  groupValue: selectedAddress,
                  title: Text(address.name),
                  subtitle: Text(addressString),
                  onChanged: (value) {
                    setState(() {
                      selectedAddress = value!;
                      _selectedAddress = address;
                    });
                  },
                );
              }).toList(),

            if (_addresses.isEmpty && selectedAddress != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(selectedAddress!)),
                  ],
                ),
              ),

            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAddAddressDialog(),
                icon:
                    const Icon(Icons.add_location_alt, color:Colors.redAccent),
                label: const Text(
                  "Add / Change Address",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController addressCtrl = TextEditingController();
    final TextEditingController cityCtrl = TextEditingController();
    final TextEditingController stateCtrl = TextEditingController();
    final TextEditingController countryCtrl = TextEditingController();
    final TextEditingController pincodeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add / Update Address"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: "Address"),
                    validator: (v) => v!.isEmpty ? "Enter address" : null,
                  ),
                  TextFormField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: "City"),
                    validator: (v) => v!.isEmpty ? "Enter city" : null,
                  ),
                  TextFormField(
                    controller: stateCtrl,
                    decoration: const InputDecoration(labelText: "State"),
                    validator: (v) => v!.isEmpty ? "Enter state" : null,
                  ),
                  TextFormField(
                    controller: countryCtrl,
                    decoration: const InputDecoration(labelText: "Country"),
                    validator: (v) => v!.isEmpty ? "Enter country" : null,
                  ),
                  TextFormField(
                    controller: pincodeCtrl,
                    decoration: const InputDecoration(labelText: "Pincode"),
                    validator: (v) => v!.isEmpty ? "Enter pincode" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
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

                  try {
                    await AddressService.addAddress(widget.userId, newAddress);
                    await _loadUserData(); // ✅ reload addresses
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("✅ Address added successfully")),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add address: $e")),
                    );
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEtaSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color:Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Estimated Delivery: Arriving by ${getEtaDate()}",
              style: const TextStyle(
                fontSize: 15,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsSection() {
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          height: 70,
                          width: 70,
                          child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "₹${item.offerPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "₹${item.price.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.green.shade200),
                                ),
                                child: Text(
                                  "-${((item.price - item.offerPrice) / item.price * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 22),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      cartItems.remove(item);
                                    }
                                    _recalculateTotals();
                                  });
                                },
                              ),
                              Text("${item.quantity}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 22),
                                onPressed: () {
                                  setState(() {
                                    item.quantity++;
                                    _recalculateTotals();
                                  });
                                },
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _removeItem(item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // Widget _buildPaymentSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text("Select Payment Method",
  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //       const SizedBox(height: 10),
  //       Column(
  //         children: paymentMethods.map((method) {
  //           return RadioListTile<String>(
  //             value: method["name"],
  //             groupValue: selectedPayment,
  //             activeColor: Colors.deepPurple,
  //             onChanged: (val) => setState(() => selectedPayment = val!),
  //             title: Row(
  //               children: [
  //                 Icon(method["icon"], color: Colors.deepPurple),
  //                 const SizedBox(width: 10),
  //                 Text(method["name"]),
  //               ],
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSummaryCard() {
    final subtotalValue = subtotal;
    final totalSavings = discount;
    final totalAmount = total;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _billRow("Subtotal (Offer Price)", "₹${subtotalValue.toStringAsFixed(2)}"),
            _billRow("You Saved", "- ₹${totalSavings.toStringAsFixed(2)}",
                color: Colors.green),
            _billRow("Delivery Charges", "₹${delivery.toStringAsFixed(2)}"),
            const Divider(thickness: 1),
            _billRow("Total Amount", "₹${totalAmount.toStringAsFixed(2)}",
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
                  color: Colors.grey[700],
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                  color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
onPressed: _selectedAddress == null
    ? null
    : () {
        if (selectedPayment == "Cash on Delivery") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order placed successfully (COD)")),
          );
          Navigator.pop(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                userId: widget.userId,
                totalAmount: total,
                cartItems: cartItems,
                selectedAddressId: _selectedAddress!.id, // ✅ use Address.id
                selectedAddress:
                    "${_selectedAddress!.address}, ${_selectedAddress!.city}, "
                    "${_selectedAddress!.state}, ${_selectedAddress!.country} - "
                    "${_selectedAddress!.pincode}", // ✅ full address text
              ),
            ),
          );
        }
      },

        child: Text(
          selectedPayment == "Cash on Delivery"
              ? "Place Order (COD)"
              : "Proceed to Pay ₹${total.toStringAsFixed(2)}",
          style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
