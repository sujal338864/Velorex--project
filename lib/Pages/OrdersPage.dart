import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:one_solution/Pages/order_details_page.dart';
import 'package:one_solution/services/order_service.dart';

class OrdersPage extends StatefulWidget {
  final String userId;
  const OrdersPage({super.key, required this.userId});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool loading = true;
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final data = await OrderService.getOrders(widget.userId);

      // 🧩 Flatten orders: show each item as an independent entry
      final List<Map<String, dynamic>> flattened = [];

      for (var order in data) {
        final items = order['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          flattened.add({
            'orderId': order['orderId'],
            'orderStatus': order['orderStatus'],
            'createdAt': order['createdAt'],
            'item': item, // store each item separately
          });
        }
      }

      setState(() {
        orders = flattened;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading orders: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      final success = await OrderService.cancelOrder(orderId.toString());
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order cancelled successfully ✅")),
        );
        _loadOrders();
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
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      appBar: AppBar(
        title: const Text(
          "My Orders 📦",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text(
                    "No orders found 🛒",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final item = order['item'];

                      // 🖼️ Image
                      final imageUrl = (item['imageUrls'] != null &&
                              (item['imageUrls'] as List).isNotEmpty)
                          ? item['imageUrls'][0]
                          : "https://via.placeholder.com/150";

                      // 🏷️ Product name
                      final productName =
                          item['name'] ?? "Unknown Product";

                      // 📝 Description
                      final productDesc =
                          item['description'] ?? "No description available";

                      // 🕒 Arriving date
                      final arrivingDate =
                          DateTime.tryParse(order['createdAt'] ?? '') != null
                              ? DateTime.parse(order['createdAt'])
                                  .add(const Duration(days: 5))
                                  .toString()
                                  .substring(0, 10)
                              : "N/A";

                      final orderId = (order['orderId'] is String)
                          ? int.tryParse(order['orderId']) ?? 0
                          : order['orderId'] ?? 0;

                      final orderStatus =
                          order['orderStatus']?.toString() ?? "Unknown";

                      return GestureDetector(
                        onTap: () {
                       Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => OrderDetailsPage(
      orderId: orderId,
      userId: widget.userId, // pass it
    ),
  ),
);

                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.deepPurple.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 🖼️ Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                              // 📄 Info
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        productDesc,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Arriving by: $arrivingDate",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            "Status: $orderStatus",
                                            style: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (orderStatus == "Pending")
                                            TextButton(
                                              onPressed: () =>
                                                  _cancelOrder(orderId),
                                              child: const Text(
                                                "Cancel Order",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
