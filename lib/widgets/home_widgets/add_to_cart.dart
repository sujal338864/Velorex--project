// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:one_solution/models/cart.dart';
// import 'package:one_solution/models/onesolution.dart';

// class AddToCart extends StatefulWidget {
//   final Items product; // ✅ renamed from onesolution

//   const AddToCart({
//     Key? key,
//     required this.product,
//   }) : super(key: key);

//   @override
//   _AddToCartState createState() => _AddToCartState();
// }

// class _AddToCartState extends State<AddToCart> {
//   final cart = CartModel(); // singleton
//   bool isInCart = false;

//   @override
//   void initState() {
//     super.initState();
//     isInCart = cart.contains(widget.product);
//   }

//   void _toggleCart() {
//     setState(() {
//       if (isInCart) {
//         cart.remove(widget.product);
//       } else {
//         cart.add(widget.product);
//       }
//       isInCart = !isInCart;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: _toggleCart,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         shape: const StadiumBorder(),
//       ),
//       child: isInCart
//           ? const Icon(Icons.done)
//           : const Icon(CupertinoIcons.cart_badge_plus),
//     );
//   }
// }
