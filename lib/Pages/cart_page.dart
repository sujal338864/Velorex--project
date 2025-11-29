// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:one_solution/Pages/home_detai_page.dart';
import 'package:one_solution/Pages/home_detail_full_page.dart';
import 'package:one_solution/Pages/saved_for_later_page.dart';
import 'package:one_solution/models/cart_item.dart';
import 'package:one_solution/models/onesolution.dart';
import 'package:one_solution/services/cartService.dart';
import 'package:one_solution/services/saved_for_later_service.dart';
import 'package:one_solution/Pages/checkout_page.dart';

class CartPage extends StatefulWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<CartItem>> _cartFuture;

  final Color actionColor = const Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    _cartFuture = _loadCart();
    cartCountNotifier.addListener(_refreshCart);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshCart();
  }

  Future<List<CartItem>> _loadCart() async {
    try {
      return await CartService.fetchCart(widget.userId);
    } catch (e) {
      debugPrint("❌ Cart load failed: $e");
      return [];
    }
  }

  Future<void> _saveForLater(CartItem item) async {
    try {
      await SavedForLaterService.moveToSaved(
          widget.userId, item.productId.toString());
      await CartService.removeFromCart(item.id);
      _refreshCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Moved to Saved for Later')),
      );
    } catch (e) {
      debugPrint("❌ Error moving item: $e");
    }
  }

  double _subtotal(List<CartItem> items) =>
      items.fold(0.0, (sum, i) => sum + (i.offerPrice * i.quantity));

  double _calculateSavePerItem(CartItem item) {
    final discount = item.price - item.offerPrice;
    return discount > 0 ? discount : 0;
  }

  String _format(double v) => "₹${v.toStringAsFixed(2)}";

  Future<void> _incrementQty(CartItem item, int stock) async {
    if (item.quantity >= stock) return; // prevent overflow

    try {
      await CartService.updateQuantity(item.id, item.quantity + 1);
      _refreshCart();
    } catch (e) {
      debugPrint("Failed to increase qty: $e");
    }
  }

  Future<void> _decrementQty(CartItem item) async {
    if (item.quantity <= 1) return;

    try {
      await CartService.updateQuantity(item.id, item.quantity - 1);
      _refreshCart();
    } catch (e) {
      debugPrint("Failed to decrease qty: $e");
    }
  }

  Future<void> _removeFromCart(CartItem item) async {
    try {
      await CartService.removeFromCart(item.id);
      _refreshCart();
    } catch (e) {
      debugPrint("Failed to remove: $e");
    }
  }

  void _refreshCart() {
    setState(() {
      _cartFuture = _loadCart();
    });
  }

  // ---------------------------- CART ITEM TILE ----------------------------
  Widget _cartItemTile(CartItem item) {
    final Items? product = OnesolutionModel().getById(item.productId);
    final int stock = product?.stock ?? 0;

    // 🟢 Stock indicator
    String stockText = "In Stock";
    Color stockColor = Colors.green;

    if (stock == 0) {
      stockText = "OUT OF STOCK";
      stockColor = Colors.red;
    } else if (stock <= 10) {
      stockText = "$stock left!";
      stockColor = Colors.orange;
    }

    final saveAmount = item.price - item.offerPrice;
    final discountPercent =
        ((saveAmount / item.price) * 100).clamp(0, 99).toStringAsFixed(0);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl.startsWith("http")
                      ? item.imageUrl
                      : "https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/product/product/${item.imageUrl}",
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),

                    // STOCK STATUS
                    const SizedBox(height: 4),
                    Text(
                      stockText,
                      style: TextStyle(
                          color: stockColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),

                    const SizedBox(height: 6),

                    // PRICE
                    Row(
                      children: [
                        Text(
                          "₹${item.offerPrice.toStringAsFixed(0)}",
                          style: TextStyle(
                              color: actionColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "₹${item.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (saveAmount > 0)
                          Text(
                            "(${discountPercent}% OFF)",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // SAVINGS
                    if (saveAmount > 0)
                      Text(
                        "You save ₹${saveAmount.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.teal, fontSize: 12),
                      ),

                    const SizedBox(height: 8),

                    // QUANTITY ROW
                    Row(
                      children: [
                        IconButton(
                          onPressed: item.quantity > 1
                              ? () => _decrementQty(item)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),

                        Text(
                          "${item.quantity}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),

                        IconButton(
                          onPressed: (stock == 0 || item.quantity >= stock)
                              ? null
                              : () => _incrementQty(item, stock),
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: (stock == 0 || item.quantity >= stock)
                                ? Colors.grey
                                : Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),

                    // SAVE / REMOVE
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _saveForLater(item),
                          child: const Text("Save for later"),
                        ),
                        TextButton(
                          onPressed: () => _removeFromCart(item),
                          child: const Text("Remove",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------- BUILD UI ----------------------------
  @override
  Widget build(BuildContext context) {
    const deliveryCharge = 49.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
    appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 2,
  title: const Text(
    "Your Cart",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),

  actions: [
    IconButton(
      icon: const Icon(Icons.enhanced_encryption_sharp, color: Colors.red),
      tooltip: "Saved for Later",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SavedForLaterPage(userId: widget.userId),
          ),
        );
      },
    ),
  ],
),

      body: FutureBuilder<List<CartItem>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final subtotal = _subtotal(items);
          final savings =
              items.fold(0.0, (s, i) => s + _calculateSavePerItem(i));

          final total = subtotal + deliveryCharge;

          return Column(
            children: [
              // CART LIST
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshCart(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) =>
                        AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 250),
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                          child: _cartItemTile(items[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // SUMMARY FOOTER
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal"),
                          Text(_format(subtotal)),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Savings"),
                          Text("-${_format(savings)}",
                              style: const TextStyle(color: Colors.green)),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Delivery"),
                          Text(_format(deliveryCharge)),
                        ]),
                    const Divider(),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_format(total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          minimumSize: const Size(double.infinity, 48)),
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutPage(
                                    userId: widget.userId,
                                    cartItems: items,
                                    subtotal: subtotal,
                                    discount: savings,
                                    delivery: deliveryCharge,
                                    total: total,
                                  ),
                                ),
                              ).then((value) => _refreshCart());
                            },
                      child: Text(
                          "Proceed to Checkout • ${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}









// // lib/pages/amazon_style_cart_page.dart
// import 'dart:math';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:one_solution/models/cart_item.dart';
// import 'package:one_solution/services/cartService.dart';

// class CartPage extends StatefulWidget {
//   final String userId;
//   const CartPage({super.key, required this.userId});

//   @override
//   State<CartPage> createState() => _CartPageState();
// }

// class _CartPageState extends State<CartPage> {
//   late Future<List<CartItem>> _cartFuture;

//   List<CartItem> savedForLater = [];
//   List<CartItem> recentlyViewed = [];
//   List<CartItem> sponsored = [];

//   // 🟣 Futuristic accent color
//   final Color actionColor = const Color(0xFF8A2BE2); // BlueViolet-like

//   @override
//   void initState() {
//     super.initState();
//     _cartFuture = _loadCart();
//     // _prepareMockSideLists();
//   }

//   Future<List<CartItem>> _loadCart() async {
//     try {
//       final list = await CartService.fetchCart(widget.userId);
//       return list;
//     } catch (e) {
//       debugPrint("Cart load failed: $e");
//       return [];
//     }
//   }

//   // void _prepareMockSideLists() {
//   //   recentlyViewed = List.generate(6, (i) {
//   //     final pid = 900 + i;
//   //     return CartItem(
//   //       id: pid,
//   //       productId: pid,
//   //       productName: "Recently viewed item ${i + 1}",
//   //       price: 999.0 + i * 150,
//   //      imageUrl:
//   //     "https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/product/product/1760845${i % 9}.png",
//   //       quantity: 1,
//   //     );
//   //   });

//   //   sponsored = List.generate(6, (i) {
//   //     final pid = 700 + i;
//   //     return CartItem(
//   //       id: pid,
//   //       productId: pid,
//   //       productName: "Sponsored product ${i + 1}",
//   //       price: 499.0 + i * 120,
//   //       imageUrl:
//   //     "https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/product/product/1760846${i % 9}.png",
//   //       quantity: 1,
//   //     );
//   //   });
//   // }

//   double _subtotal(List<CartItem> items) =>
//       items.fold(0.0, (sum, e) => sum + (e.price * e.quantity));

//   double _calculateSavePerItem(CartItem item) {
//     final offerPrice = item.price;
//     final original = offerPrice *
//         (1 + (Random(item.productId).nextDouble() * 0.4 + 0.15)); // +15–55%
//     return (original - offerPrice).clamp(0, double.infinity);
//   }

//   String _formatPrice(double v) => "₹${v.toStringAsFixed(2)}";

//   Future<void> _incrementQty(CartItem item) async {
//     final newQty = item.quantity + 1;
//     try {
//       await CartService.updateQuantity(item.id, newQty);
//       setState(() => _cartFuture = CartService.fetchCart(widget.userId));
//     } catch (e) {
//       debugPrint("Failed to increase qty: $e");
//     }
//   }

//   Future<void> _decrementQty(CartItem item) async {
//     if (item.quantity <= 1) return;
//     final newQty = item.quantity - 1;
//     try {
//       await CartService.updateQuantity(item.id, newQty);
//       setState(() => _cartFuture = CartService.fetchCart(widget.userId));
//     } catch (e) {
//       debugPrint("Failed to decrease qty: $e");
//     }
//   }

//   Future<void> _removeFromCart(CartItem item) async {
//     try {
//       await CartService.removeFromCart(item.id);
//       setState(() => _cartFuture = CartService.fetchCart(widget.userId));
//     } catch (e) {
//       debugPrint("Remove failed: $e");
//     }
//   }

//   void _saveForLater(CartItem item) {
//     setState(() {
//       savedForLater.add(item);
//       _cartFuture = _cartFuture.then(
//         (list) => list.where((x) => x.id != item.id).toList(),
//       );
//     });
//   }

//   Widget _cartItemTile(CartItem item) {
//     final saveAmount = _calculateSavePerItem(item);
//     final percent =
//         ((saveAmount / (item.price + saveAmount)) * 100).round().clamp(0, 99);

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       shadowColor: actionColor.withOpacity(0.25),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: CachedNetworkImage(
//   imageUrl: item.imageUrl,
//   width: 110,
//   height: 110,
//   fit: BoxFit.cover,
//   placeholder: (_, __) => Container(
//     width: 110,
//     height: 110,
//     color: Colors.grey[200],
//     child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
//   ),
//   errorWidget: (_, __, ___) => Container(
//     width: 110,
//     height: 110,
//     decoration: BoxDecoration(
//       color: Colors.grey[300],
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: const Icon(Icons.image_not_supported_outlined,
//         size: 40, color: Colors.grey),
//   ),
// )

//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(item.productName,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                           fontSize: 16, fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 3),
//                   const Text("In Stock",
//                       style: TextStyle(color: Colors.green, fontSize: 13)),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Text(_formatPrice(item.price),
//                           style: TextStyle(
//                               color: actionColor,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16)),
//                       const SizedBox(width: 8),
//                       Text(_formatPrice(item.price + saveAmount),
//                           style: const TextStyle(
//                               color: Colors.grey,
//                               decoration: TextDecoration.lineThrough)),
//                       const SizedBox(width: 8),
//                       Text("-$percent%",
//                           style: const TextStyle(color: Colors.redAccent)),
//                     ],
//                   ),
//                   Text("You save ${_formatPrice(saveAmount)}",
//                       style: const TextStyle(
//                           color: Colors.teal, fontSize: 12, height: 1.5)),
//                   const SizedBox(height: 10),
//                 Row(
//   crossAxisAlignment: CrossAxisAlignment.start,
//   children: [
//     IconButton(
//       onPressed: item.quantity > 1 ? () => _decrementQty(item) : null,
//       icon: const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
//     ),
//     Text("${item.quantity}",
//         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//     IconButton(
//       onPressed: () => _incrementQty(item),
//       icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
//     ),
//     const Spacer(),
//   ],
// ),

// const SizedBox(height: 8),

// Wrap(
//   spacing: 10,
//   runSpacing: 5,
//   children: [
//     TextButton(
//         onPressed: () => _saveForLater(item),
//         child: const Text("Save for later")),
//     TextButton(
//         onPressed: () => _removeFromCart(item),
//         child: const Text("Remove",
//             style: TextStyle(color: Colors.red))),
//   ],
// ),

//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _horizontalCard(String title, List<CartItem> items) {
//     if (items.isEmpty) return const SizedBox();
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 8),
//         Text(title,
//             style: const TextStyle(
//                 fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
//         const SizedBox(height: 6),
//         SizedBox(
//           height: 200,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             itemCount: items.length,
//             separatorBuilder: (_, __) => const SizedBox(width: 10),
//             itemBuilder: (_, i) {
//               final item = items[i];
//               return Container(
//                 width: 140,
//                 decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                           color: actionColor.withOpacity(0.1),
//                           blurRadius: 6,
//                           offset: const Offset(0, 3))
//                     ]),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ClipRRect(
//                       borderRadius:
//                           const BorderRadius.vertical(top: Radius.circular(12)),
//                       child: CachedNetworkImage(
//                         imageUrl: item.imageUrl,
//                         height: 120,
//                         width: double.infinity,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     Padding(
//                       padding:
//                           const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                       child: Text(item.productName,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(fontSize: 13)),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8),
//                       child: Text(_formatPrice(item.price),
//                           style: TextStyle(
//                               color: actionColor, fontWeight: FontWeight.bold)),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const deliveryCharge = 49.0;

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text("Your Cart"),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 2,
//       ),
//       body: FutureBuilder<List<CartItem>>(
//         future: _cartFuture,
//         builder: (context, snapshot) {
//           final cartItems = snapshot.data ?? [];
//           final subtotal = _subtotal(cartItems);
//           final totalSavings = cartItems.fold<double>(
//               0.0, (sum, item) => sum + _calculateSavePerItem(item));
//           final total = subtotal + deliveryCharge - totalSavings;

//           return Column(
//             children: [
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     setState(() => _cartFuture = CartService.fetchCart(widget.userId));
//                   },
//                   child: SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: const EdgeInsets.all(12),
//                     child: AnimationLimiter(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if (cartItems.isEmpty)
//                             const Padding(
//                               padding: EdgeInsets.all(40),
//                               child: Center(
//                                   child: Text("Your cart is empty 🛒",
//                                       style: TextStyle(fontSize: 16))),
//                             )
//                           else
//                             ...List.generate(cartItems.length, (i) {
//                               return AnimationConfiguration.staggeredList(
//                                 position: i,
//                                 duration: const Duration(milliseconds: 300),
//                                 child: SlideAnimation(
//                                   verticalOffset: 20,
//                                   child:
//                                       FadeInAnimation(child: _cartItemTile(cartItems[i])),
//                                 ),
//                               );
//                             }),
//                           const SizedBox(height: 10),
//                           _horizontalCard("Recently Viewed", recentlyViewed),
//                           const SizedBox(height: 12),
//                           _horizontalCard("Sponsored Products", sponsored),
//                           const SizedBox(height: 80),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               // 🧾 Bill Summary Footer
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: const BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text("Subtotal",
//                             style: TextStyle(fontWeight: FontWeight.w600)),
//                         Text(_formatPrice(subtotal),
//                             style: const TextStyle(fontWeight: FontWeight.w600)),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text("Discounts"),
//                         Text("-${_formatPrice(totalSavings)}",
//                             style: const TextStyle(color: Colors.teal)),
//                       ],
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text("Delivery Charges"),
//                         Text(_formatPrice(deliveryCharge)),
//                       ],
//                     ),
//                     const Divider(),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text("Total",
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold, fontSize: 16)),
//                         Text(_formatPrice(total),
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold, fontSize: 16)),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Text("You saved ${_formatPrice(totalSavings)} on this order 🎉",
//                         style: const TextStyle(color: Colors.green)),
//                     const SizedBox(height: 10),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: actionColor,
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                       ),
//                       onPressed: cartItems.isEmpty
//                           ? null
//                           : () => ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                     content:
//                                         Text("Proceeding to Checkout...")),
//                               ),
//                       child: Text("Proceed to Checkout • ${_formatPrice(total)}",
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600)),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:one_solution/models/cart_item.dart';
// import 'package:one_solution/services/cartService.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:cached_network_image/cached_network_image.dart';


// class CartPage extends StatefulWidget {
//   final String userId;

//   const CartPage({super.key, required this.userId});

//   @override
//   State<CartPage> createState() => _CartPageState();
// }

// class _CartPageState extends State<CartPage> {
//   late Future<List<CartItem>> _cartItems;
//   String? userId;

//   @override
//   void initState() {
//     super.initState();
//     _getUserIdAndLoadCart();
//   }

//   Future<void> _getUserIdAndLoadCart() async {
//     final user = Supabase.instance.client.auth.currentUser;
//     if (user != null) {
//       setState(() {
//         userId = user.id;
//         _cartItems = CartService.fetchCart(user.id);
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please login to view your cart')),
//       );
//     }
//   }

//   // 🧮 Helper: calculate total price
//   double _calculateSubtotal(List<CartItem> items) {
//     return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (userId == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.teal,
//         title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold)),
//       ),
//       body: FutureBuilder<List<CartItem>>(
//         future: _cartItems,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }

//           final items = snapshot.data ?? [];
//           if (items.isEmpty) {
//             return const Center(
//               child: Text("🛒 Your cart is empty", style: TextStyle(fontSize: 18)),
//             );
//           }

//           final subtotal = _calculateSubtotal(items);
//           const deliveryCharge = 49.0;
//           const discount = 0.0; // optional dynamic logic later
//           final total = subtotal + deliveryCharge - discount;

//           return Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.all(10),
//                   itemCount: items.length,
//                   itemBuilder: (context, index) {
//                     final item = items[index];

//                     return Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 2,
//                       margin: const EdgeInsets.symmetric(vertical: 6),
//                       child: Padding(
//                         padding: const EdgeInsets.all(10),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // 🖼️ Product Image
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(8),
//                               child: CachedNetworkImage(
//   imageUrl: item.imageUrl,
//   width: 90,
//   height: 90,
//   fit: BoxFit.cover,
//   placeholder: (context, url) => const Center(
//     child: SizedBox(
//       width: 25,
//       height: 25,
//       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
//     ),
//   ),
//   errorWidget: (context, url, error) =>
//       const Icon(Icons.broken_image, size: 70, color: Colors.grey),
//   fadeInDuration: const Duration(milliseconds: 300),
//   fadeOutDuration: const Duration(milliseconds: 100),
//   memCacheHeight: 200, // ✅ improves performance for scrolling
// ),

//                             ),
//                             const SizedBox(width: 12),
//                             // 📦 Product Info
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(item.productName,
//                                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     "₹${item.price.toStringAsFixed(2)}",
//                                     style: const TextStyle(fontSize: 15, color: Colors.teal),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     children: [
//                                       // ➖ Decrease Qty
//                                       IconButton(
//                                         icon: const Icon(Icons.remove_circle_outline),
//                                         onPressed: item.quantity > 1
//                                             ? () async {
//                                                 await CartService.updateQuantity(item.id, item.quantity - 1);
//                                                 setState(() {
//                                                   _cartItems = CartService.fetchCart(userId!);
//                                                 });
//                                               }
//                                             : null,
//                                       ),
//                                       Text("${item.quantity}",
//                                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                                       // ➕ Increase Qty
//                                       IconButton(
//                                         icon: const Icon(Icons.add_circle_outline),
//                                         onPressed: () async {
//                                           await CartService.updateQuantity(item.id, item.quantity + 1);
//                                           setState(() {
//                                             _cartItems = CartService.fetchCart(userId!);
//                                           });
//                                         },
//                                       ),
//                                       const Spacer(),
//                                       // 🗑️ Delete
//                                     IconButton(
//   icon: const Icon(Icons.delete_outline, color: Colors.red),
//   onPressed: () async {
//     await CartService.removeFromCart(item.id); // ✅ only cartId
//     setState(() {
//       _cartItems = CartService.fetchCart(userId!);
//     });
//   },
// ),

//                                     ],
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
//               ),

//               // 💰 Price Summary & Checkout
//               Container(
//                 padding: const EdgeInsets.all(15),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(color: Colors.black12, offset: Offset(0, -1), blurRadius: 6),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _priceRow("Subtotal", subtotal),
//                     _priceRow("Delivery Charges", deliveryCharge),
//                     _priceRow("Discount", -discount, color: Colors.green),
//                     const Divider(),
//                     _priceRow("Total", total, bold: true, fontSize: 18),
//                     const SizedBox(height: 10),
//                     ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.teal,
//                         minimumSize: const Size.fromHeight(50),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                       ),
//                       icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
//                       label: const Text(
//                         "Proceed to Checkout",
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                       onPressed: () {
//                         // 🧾 Go to order summary or payment page
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text('Proceeding to Checkout...')),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // 🔹 Helper Widget for Price Rows
//   Widget _priceRow(String label, double value,
//       {bool bold = false, double fontSize = 16, Color? color}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
//           Text(
//             "₹${value.toStringAsFixed(2)}",
//             style: TextStyle(
//               fontSize: fontSize,
//               fontWeight: bold ? FontWeight.bold : FontWeight.normal,
//               color: color ?? Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
