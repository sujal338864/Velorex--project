import 'package:flutter/material.dart';
import 'package:one_solution/models/cart.dart';
import 'package:one_solution/models/onesolution.dart';

class CartItemWidget extends StatelessWidget {
  final Items item;
  final int quantity;
  final CartModel cart;
  final VoidCallback onUpdate;

  const CartItemWidget({
    Key? key,
    required this.item,
    required this.quantity,
    required this.cart,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.images.isNotEmpty
                ? item.images.first
                : "https://via.placeholder.com/150",
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(item.name),
        subtitle: Text("₹${item.price} x $quantity"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent),
              onPressed: () {
                cart.remove(item);
                onUpdate();
              },
            ),
            Text('$quantity'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              onPressed: () {
                cart.add(item);
                onUpdate();
              },
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:one_solution/models/onesolution.dart';
// import 'package:one_solution/models/cart.dart';
// import 'package:velocity_x/velocity_x.dart';

// class CartItemWidget extends StatelessWidget {
//   final Items item;
//   final CartModel cartModel;

//   const CartItemWidget({Key? key, required this.item, required this.cartModel})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.network(
//             item.imageUrls.isNotEmpty
//                 ? item.imageUrls.first
//                 : "https://via.placeholder.com/150",
//             height: 50,
//             width: 50,
//             fit: BoxFit.cover,
//           ),
//         ),
//         title: Text(item.name),
//         subtitle: "₹${item.price}".text.make(),
// trailing: IconButton(
//   icon: const Icon(Icons.delete_outline),
//   color: Colors.redAccent,
//   onPressed: () {
//     CartModel().remove(item); // Use the singleton instance
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("${item.name} removed from cart"),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   },
// ),

//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:one_solution/models/onesolution.dart';

// class ItemWidget extends StatelessWidget {
//   final Items item;

//   const ItemWidget({Key? key, required this.item}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 4,
//       child: ListTile(
//         onTap: () {
//           // You can navigate to a detail page here
//           print("${item.name} pressed");
//         },
//         leading: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.network(
//             item.firstImage, // ✅ Uses the new getter
//             width: 60,
//             height: 60,
//             fit: BoxFit.cover,
//           ),
//         ),
//         title: Text(
//           item.name,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         subtitle: Text(
//           item.description,
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
//         trailing: Text(
//           "₹${item.price}",
//           style: const TextStyle(
//             color: Colors.deepPurple,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       ),
//     );
//   }
// }

