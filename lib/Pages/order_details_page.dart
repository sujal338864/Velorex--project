// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:one_solution/Pages/home_detail_full_page.dart';
import 'package:one_solution/Pages/tracking_webview_page.dart';
import 'package:one_solution/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  final String userId; // ✅ Add this line

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.userId, // ✅ Add this line
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
    final allOrders = await OrderService.getOrders(widget.userId); // fetch all user orders

    // Filter to get the one you need
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
Future<void> _openReviewDialog(int productId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login to write review")),
    );
    return;
  }

  int tempRating = 0;
  String tempComment = '';
  String displayName = user.userMetadata?["full_name"] ?? user.email ?? "User";

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        title: const Text("Write Review"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int star = index + 1;
                return IconButton(
                  icon: Icon(
                    star <= tempRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setStateDialog(() => tempRating = star);
                  },
                );
              }),
            ),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Write your review",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => tempComment = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tempRating == 0) return;

              await RatingService.submitReview(
                productId: productId,
                userId: user.id,
                userName: displayName,
                rating: tempRating,
                comment: tempComment.trim(),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Review submitted successfully!")),
              );

              Navigator.pop(ctx);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _cancelOrder() async {
    try {
      final success =
          await OrderService.cancelOrder(widget.orderId.toString());
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order cancelled successfully ✅")),
        );
        _loadOrderDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel order ❌")),
        );
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
        title: const Text(
          "Order Details 📦",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(child: Text("Order details not found ❌"))
              : RefreshIndicator(
                  onRefresh: _loadOrderDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🆔 Order ID & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Order #${order['orderId']}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple),
                              ),
                              Text(
                                (order['createdAt'] ?? '')
                                    .toString()
                                    .substring(0, 10),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 📦 Order Status
                          _buildOrderTracker(order['orderStatus'] ?? "Pending"),
                          const SizedBox(height: 20),

                          // 🛍️ Items List
                          const Text(
                            "Ordered Items",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ..._buildItems(order['items'] ?? []),

                          const Divider(height: 30, thickness: 1),

                          // 💳 Payment Summary
                          const Text(
                            "Payment & Summary",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow("Payment Method",
                              order['paymentMethod'] ?? "N/A"),
                          _buildSummaryRow(
                              "Order Status", order['orderStatus'] ?? "N/A"),
                              _buildSummaryRow("Delivery Charge", "₹49"),
                         _buildSummaryRow("Total Amount", "₹${(order['totalAmount'] ?? 0) + 49}"),
                          if (order['couponCode'] != null)
                            _buildSummaryRow(
                                "Coupon", order['couponCode'].toString()),

                          const Divider(height: 30, thickness: 1),

                          // 🏠 Shipping Address
                          const Text(
                            "Shipping Address",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(order['shippingAddress'] ?? "N/A",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 25),
// 🧭 Item Tracking Links Section
if ((order['items'] ?? []).isNotEmpty) ...[
  const Divider(height: 30, thickness: 1),
  const Text(
    "Tracking Links",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 8),
  ...List.generate(order['items'].length, (index) {
    final item = order['items'][index];
    final trackingUrl = item['itemTrackingUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['name'] ?? 'Item ${index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
           onTap: () {
  if (trackingUrl.isNotEmpty && trackingUrl != "Not Available") {
    final fixedUrl = trackingUrl.startsWith("http")
        ? trackingUrl
        : "https://$trackingUrl"; // auto-fix missing scheme

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingWebViewPage(
          url: fixedUrl,
          title: item['name'] ?? 'Tracking Link',
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tracking link not available")),
    );
  }
},

            child: Text(
              trackingUrl.isNotEmpty && trackingUrl != "Not Available"
                  ? trackingUrl
                  : "Not Available",
              style: TextStyle(
                color: trackingUrl.isNotEmpty &&
                        trackingUrl != "Not Available"
                    ? Colors.blue
                    : Colors.grey,
                decoration: trackingUrl.isNotEmpty &&
                        trackingUrl != "Not Available"
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }),
],

// 🟦 Tracking URL Section (always shown)
Container(
  margin: const EdgeInsets.only(top: 16),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.grey.shade300),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Tracking URL",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        order['trackingUrl'] != null && order['trackingUrl'].isNotEmpty
            ? order['trackingUrl']
            : "Not Available",
        style: TextStyle(
          color: order['trackingUrl'] != null && order['trackingUrl'].isNotEmpty
              ? Colors.blue
              : Colors.grey,
          decoration: order['trackingUrl'] != null && order['trackingUrl'].isNotEmpty
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
    ],
  ),
),

                          const SizedBox(height: 25),

                          // 🔘 Action Buttons
                          if (order['orderStatus'] == "Pending")
                            Center(
                              child: ElevatedButton(
                                onPressed: _cancelOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 12),
                                ),
                                child: const Text(
                                  "Cancel Order",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
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

  // 🛍️ Build items list
List<Widget> _buildItems(List<dynamic> items) {
  if (items.isEmpty) {
    return [
      const Text("No items found", style: TextStyle(color: Colors.grey))
    ];
  }

  return items.map((item) {
    final imageUrl = (item['imageUrls'] != null &&
            (item['imageUrls'] as List).isNotEmpty)
        ? item['imageUrls'][0]
        : "https://via.placeholder.com/150";

    final productId = item['productId']; // VERY IMPORTANT
    final orderStatus = orderDetails?['orderStatus'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? "Product",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Qty: ${item['quantity'] ?? 1}"),
                    const SizedBox(height: 2),
                    Text("₹${item['price'] ?? 0.0}",
                        style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          // ⭐ Write Review (only if Delivered)
          if (orderStatus == "Delivered")
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openReviewDialog(productId),
                icon: const Icon(Icons.rate_review, color: Colors.deepPurple),
                label: const Text(
                  "Write a Review",
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
            ),
        ],
      ),
    );
  }).toList();
}


  // 📊 Payment summary row
  Widget _buildSummaryRow(String title, String value) {
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  // 🚚 Order tracker widget
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
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(step,
                  style: TextStyle(
                      fontSize: 11,
                      color: isCancelled
                          ? Colors.redAccent
                          : isActive
                              ? Colors.deepPurple
                              : Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
