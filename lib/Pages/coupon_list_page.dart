import 'package:flutter/material.dart';
import 'package:one_solution/services/category_service.dart';

class CouponListPage extends StatefulWidget {
  final double subtotal;
  const CouponListPage({super.key, required this.subtotal});

  @override
  State<CouponListPage> createState() => _CouponListPageState();
}

class _CouponListPageState extends State<CouponListPage> {
  List<Map<String, dynamic>> coupons = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCoupons();
  }

  Future<void> loadCoupons() async {
    try {
      coupons = await CategoryService.getAllCoupons();
    } catch (e) {
      debugPrint("❌ Coupon load failed: $e");
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Coupons")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: coupons.length,
              itemBuilder: (_, i) {
                final c = coupons[i];
                final min = (c["MinimumPurchase"] ?? 0).toDouble();
                final isUnlocked = widget.subtotal >= min;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      c["Code"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.green : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          "${c["DiscountType"]} : ${c["DiscountAmount"]}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Minimum Purchase: ₹${min.toStringAsFixed(2)}",
                          style: TextStyle(
                              color: isUnlocked ? Colors.black : Colors.red),
                        ),
                        Text(
                          "Valid: ${c["StartDate"]} → ${c["EndDate"]}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    trailing: isUnlocked
                        ? ElevatedButton(
                            child: const Text("Apply"),
                            onPressed: () {
                              Navigator.pop(context, c); // return selected coupon
                            },
                          )
                        : const Icon(Icons.lock, color: Colors.red),
                  ),
                );
              },
            ),
    );
  }
}
