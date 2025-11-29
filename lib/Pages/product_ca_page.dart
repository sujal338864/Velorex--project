// import 'package:flutter/material.dart';
// import 'package:one_solution/models/subcategory_model.dart';
// import 'package:one_solution/services/produc_caegor_services.dart';
// import '../models/onesolution.dart';

// // ======================================================
// // 🔹 PRODUCT PAGE (FILTERED BY CATEGORY & SUBCATEGORY)
// // ======================================================
// class ProductPage extends StatefulWidget {
//   final int categoryId;
//   final Subcategory? subcategory;

//   const ProductPage({
//     super.key,
//     required this.categoryId,
//     this.subcategory,
//   });

//   @override
//   State<ProductPage> createState() => _ProductPageState();
// }

// class _ProductPageState extends State<ProductPage> {
//   List<Items> products = [];
//   bool isLoading = false;
//   bool hasFetched = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (!hasFetched) {
//       loadProducts();
//       hasFetched = true;
//     }
//   }

//   Future<void> loadProducts() async {
//     setState(() => isLoading = true);

//     final subcatId = widget.subcategory?.subcategoryId;
//     print("🟢 Loading products for category=${widget.categoryId}, subcategory=$subcatId");

//     try {
//       final all = await ProcatService.getcatProducts(
//         categoryId: widget.categoryId,
//         subcategoryId: subcatId,
//       );

//       setState(() {
//         products = all;
//         isLoading = false;
//       });

//       print("🟣 Loaded ${products.length} products");
//     } catch (e) {
//       print("❌ Error loading products: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final subName = widget.subcategory?.name ?? "Products";

//     return Scaffold(
//       appBar: AppBar(title: Text(subName)),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : products.isEmpty
//               ? const Center(child: Text("No products available"))
//               : GridView.builder(
//                   padding: const EdgeInsets.all(8),
//                   itemCount: products.length,
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 8,
//                     crossAxisSpacing: 8,
//                     childAspectRatio: 0.7,
//                   ),
//                   itemBuilder: (context, index) {
//                     final item = products[index];
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => ProductDetailPage(item: item),
//                           ),
//                         );
//                       },
//                       child: Card(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 3,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(
//                               child: Image.network(
//                                 item.firstImage,
//                                 fit: BoxFit.cover,
//                                 width: double.infinity,
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     item.name,
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     "₹${item.offerPrice}",
//                                     style: const TextStyle(
//                                         color: Colors.green,
//                                         fontWeight: FontWeight.w600),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }

// // ======================================================
// // 🔹 PRODUCT DETAIL PAGE
// // ======================================================
// class ProductDetailPage extends StatelessWidget {
//   final Items item;

//   const ProductDetailPage({super.key, required this.item});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(item.name)),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.network(
//               item.firstImage,
//               width: double.infinity,
//               height: 250,
//               fit: BoxFit.cover,
//             ),
//             const SizedBox(height: 12),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(item.name,
//                       style: const TextStyle(
//                           fontSize: 22, fontWeight: FontWeight.bold)),
//                   Text(
//                     "₹${item.offerPrice}",
//                     style: const TextStyle(
//                         fontSize: 20,
//                         color: Colors.green,
//                         fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(item.description),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
