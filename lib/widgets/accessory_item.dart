// import 'package:flutter/material.dart';
// import 'package:one_solution/models/cart.dart';
// import 'package:one_solution/models/onesolution.dart'; // For Items
// import 'package:one_solution/widgets/theme.dart';
// import 'package:velocity_x/velocity_x.dart';

// class AccessoryItem extends StatelessWidget {
//   final Items accessory;
//   final CartModel cart;
//   final VoidCallback onUpdate;

//   const AccessoryItem({
//     Key? key,
//     required this.accessory,
//     required this.cart,
//     required this.onUpdate,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final String imageUrl = (accessory.image.isNotEmpty)
//         ? accessory.image
//         : "https://via.placeholder.com/150"; // Fallback image

//     return Container(
//       width: 200,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
//       margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//       decoration: BoxDecoration(
//         color: MyTheme.ncreamColor,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ✅ Load image with fallback and error handling
//           ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: Image.network(
//               imageUrl,
//               height: 48,
//               width: 48,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) =>
//                   const Icon(Icons.broken_image, size: 48, color: Colors.white54),
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) return child;
//                 return const SizedBox(
//                   height: 48,
//                   width: 48,
//                   child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
//                 );
//               },
//             ),
//           ),
//           8.heightBox,
//           accessory.name.text.xs.white.ellipsis.maxLines(1).make(),
//           "₹${accessory.price}".text.xs.white.make(),
//           6.heightBox,
//           ElevatedButton(
//             onPressed: () {
//               cart.add(accessory);
//               onUpdate();
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text("${accessory.name} added to cart")),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.deepPurple,
//               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
//               textStyle: const TextStyle(fontSize: 10),
//             ),
//             child: "+ Add".text.xs.white.make(),
//           ),
//         ],
//       ),
//     );
//   }
// }
