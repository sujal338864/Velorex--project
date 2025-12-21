import 'package:flutter/material.dart';
import 'package:Velorex/services/category_service.dart';

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

  /// ---------- SAFE DOUBLE ----------
  double safeDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
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
          : coupons.isEmpty
              ? const Center(child: Text("No coupons available"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: coupons.length,
                  itemBuilder: (_, i) {
                    final c = coupons[i];

                    /// ---------- FIELD NORMALIZATION ----------
                    final code = (c["Code"] ??
                            c["code"] ??
                            c["couponCode"] ??
                            c["CouponCode"] ??
                            c["Coupon"] ??
                            "UNKNOWN")
                        .toString();

                    final discountType = (c["DiscountType"] ??
                            c["discountType"] ??
                            c["discount_type"] ??
                            c["type"] ??
                            "Discount")
                        .toString();

                    final discountAmount = (c["DiscountAmount"] ??
                            c["discountAmount"] ??
                            c["amount"] ??
                            c["discount_value"] ??
                            "0")
                        .toString();

                    final min = safeDouble(
                      c["MinimumPurchase"] ??
                          c["minimum_purchase"] ??
                          c["MinPurchase"] ??
                          c["minPurchase"] ??
                          c["min_amount"] ??
                          c["MinAmount"],
                    );

                    final startDate = (c["StartDate"] ??
                            c["startDate"] ??
                            c["start_date"] ??
                            c["ValidFrom"] ??
                            c["valid_from"] ??
                            "")
                        .toString();

                    final endDate = (c["EndDate"] ??
                            c["endDate"] ??
                            c["end_date"] ??
                            c["ValidTo"] ??
                            c["valid_to"] ??
                            "")
                        .toString();

                    final isUnlocked = widget.subtotal >= min;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          code,
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
                              "$discountType : $discountAmount",
                              style: const TextStyle(fontSize: 13),
                            ),

                            Text(
                              "Minimum Purchase: ₹${min.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isUnlocked ? Colors.black : Colors.red,
                              ),
                            ),

                            Text(
                              startDate.isEmpty && endDate.isEmpty
                                  ? "Validity: N/A"
                                  : "Valid: $startDate → $endDate",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),

                        trailing: isUnlocked
                            ? ElevatedButton(
                                child: const Text("Apply"),
                                onPressed: () {
                                  Navigator.pop(context, c);
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




// import 'package:flutter/material.dart';
// import 'package:Velorex/services/category_service.dart';

// class CouponListPage extends StatefulWidget {
//   final double subtotal;
//   const CouponListPage({super.key, required this.subtotal});

//   @override
//   State<CouponListPage> createState() => _CouponListPageState();
// }

// class _CouponListPageState extends State<CouponListPage> {
//   List<Map<String, dynamic>> coupons = [];
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadCoupons();
//   }

//   Future<void> loadCoupons() async {
//     try {
//       coupons = await CategoryService.getAllCoupons();
//     } catch (e) {
//       debugPrint("❌ Coupon load failed: $e");
//     }
//     setState(() => loading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Available Coupons")),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: coupons.length,
//               itemBuilder: (_, i) {
//                 final c = coupons[i];
//                 final min = (c["MinimumPurchase"] ?? 0).toDouble();
//                 final isUnlocked = widget.subtotal >= min;

//                 return Card(
//                   elevation: 3,
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   child: ListTile(
//                     title: Text(
//                       c["Code"] ?? "N/A",

//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: isUnlocked ? Colors.green : Colors.grey,
//                       ),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 4),
//                         Text(
//                           "${c["DiscountType"]} : ${c["DiscountAmount"]}",
//                           style: const TextStyle(fontSize: 13),
//                         ),
//                         Text(
//                           "Minimum Purchase: ₹${min.toStringAsFixed(2)}",
//                           style: TextStyle(
//                               color: isUnlocked ? Colors.black : Colors.red),
//                         ),
//                         Text(
//                           "Valid: ${c["StartDate"]} → ${c["EndDate"]}",
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ],
//                     ),

//                     trailing: isUnlocked
//                         ? ElevatedButton(
//                             child: const Text("Apply"),
//                             onPressed: () {
//                               Navigator.pop(context, c); // return selected coupon
//                             },
//                           )
//                         : const Icon(Icons.lock, color: Colors.red),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
