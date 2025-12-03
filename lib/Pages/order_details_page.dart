// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:one_solution/Pages/home_detail_full_page.dart';
import 'package:one_solution/Pages/tracking_webview_page.dart';
import 'package:one_solution/models/onesolution.dart';
import 'package:one_solution/services/order_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  final String userId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool loading = true;
  Map<String, dynamic>? orderDetails;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final allOrders = await OrderService.getOrders(widget.userId);

      final matchingOrder = allOrders.firstWhere(
        (order) => order['orderId'] == widget.orderId,
        orElse: () => {},
      );

      setState(() {
        orderDetails = matchingOrder.isNotEmpty ? matchingOrder : null;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Failed to load order details: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _cancelOrder() async {
    try {
      final success = await OrderService.cancelOrder(widget.orderId.toString());
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order cancelled successfully ✅")),
        );
        _loadOrderDetails();
      }
    } catch (e) {
      debugPrint("❌ Error cancelling order: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = orderDetails;

    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text(
    "Order Details 📦",
    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
  ),
  backgroundColor: Colors.white,
  elevation: 1,
  centerTitle: true,
),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(child: Text("Order not found ❌"))
              : RefreshIndicator(
                  onRefresh: _loadOrderDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -----------------------
                          // ORDER HEADER
                          // -----------------------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Order #${order['orderId']}",
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                (order['createdAt'] ?? "")
                                    .toString()
                                    .substring(0, 10),
                                style: const TextStyle(color: Colors.grey),
                              )
                            ],
                          ),

                          const SizedBox(height: 12),
                          _buildOrderTracker(order['orderStatus'] ?? "Pending"),
                          const SizedBox(height: 22),

                          // -----------------------
                          // ITEMS – EACH IS A MINI ORDER
                          // -----------------------
                          const Text(
                            "Ordered Items",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          ..._buildItemCards(order['items'] ?? []),

                          const Divider(height: 32),

                          // -----------------------
                          // PAYMENT SUMMARY
                          // -----------------------
                          const Text("Payment & Summary",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),

                          _buildSummaryRow("Payment Method",
                              order['paymentMethod'] ?? "N/A"),
                          _buildSummaryRow(
                              "Order Status", order['orderStatus'] ?? "N/A"),

                          if (order['couponCode'] != null)
                            _buildSummaryRow(
                                "Coupon Used", order['couponCode']),

                          if (order['couponDiscount'] != null)
                            _buildSummaryRow(
                                "Coupon Discount",
                                "-₹${order['couponDiscount']}"),

                          _buildSummaryRow(
                            "Total Amount Paid",
                            "₹${order['totalAmount'].toStringAsFixed(2)}",
                          ),

                          const Divider(height: 32),

                          // -----------------------
                          // SHIPPING ADDRESS
                          // -----------------------
                          const Text("Shipping Address",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(order['shippingAddress'] ?? "N/A"),

                          const SizedBox(height: 30),

                          // CANCEL BUTTON
                          if (order['orderStatus'] == "Pending")
                            Center(
                              child: ElevatedButton(
                                onPressed: _cancelOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  "Cancel Order",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // ===================================================================
  // MULTIPLE INDEPENDENT ITEM CARDS
  // ===================================================================
  List<Widget> _buildItemCards(List<dynamic> items) {
    return items.map((item) {
      final qty = item['quantity'] ?? 1;
      final finalAmount = (item['finalAmount'] ?? 0).toDouble();
      final delivery = (item['deliveryCharge'] ?? 0).toDouble();
      final couponShare = (item['couponShare'] ?? 0).toDouble();

      final product =
          OnesolutionModel().getById(int.tryParse(item["productId"].toString()) ?? 0);

      final eta = DateTime.now().add(const Duration(days: 4));
      final etaText = "${eta.day}/${eta.month}/${eta.year}";

      final imageUrl = (item['imageUrls'] != null &&
              (item['imageUrls'] as List).isNotEmpty)
          ? item['imageUrls'][0]
          : "https://i.imgur.com/5ZQpZKK.jpeg";

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (product != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeDetailFullPage(
                          onesolution: product,
                          heroTag: product.id.toString(),
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imageUrl,
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? "Product",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Qty: $qty", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text("Delivery: ₹${delivery.toStringAsFixed(2)}"),
                          if (couponShare > 0)
                            Text(
                              "Coupon Savings: -₹${couponShare.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.local_shipping,
                                  size: 18, color: Colors.deepPurple),
                              const SizedBox(width: 5),
                              Text("ETA: $etaText",
                                  style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("Paid: ₹${finalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.deepPurple)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ---------------- TRACKING ----------------
              if (item['itemTrackingUrl'] != null &&
                  item['itemTrackingUrl'].toString().trim().isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.location_pin, color: Colors.white),
                  label: const Text("Track Order",
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackingWebViewPage(
                          url: item['itemTrackingUrl'],
                          title: item['name'] ?? "Tracking",
                        ),
                      ),
                    );
                  },
                )
              else
                const Text("Tracking not available",
                    style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ===================================================================
  // SUMMARY ROW
  // ===================================================================
  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.black54, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  // ===================================================================
  // ORDER STATUS TRACKER
  // ===================================================================
  Widget _buildOrderTracker(String status) {
    final steps = ["Pending", "Processing", "Shipped", "Delivered", "Cancelled"];
    final activeIndex = steps.indexOf(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: steps.map((step) {
        final index = steps.indexOf(step);
        final isActive = index <= activeIndex;
        final isCancelled = status == "Cancelled";

        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isCancelled
                    ? Colors.redAccent
                    : isActive
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 4),
              Text(
                step,
                style: TextStyle(
                  fontSize: 11,
                  color: isCancelled
                      ? Colors.redAccent
                      : isActive
                          ? Colors.deepPurple
                          : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
