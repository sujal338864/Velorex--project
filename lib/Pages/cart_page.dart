// ignore_for_file: deprecated_member_use, unused_element

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:one_solution/Pages/coupon_list_page.dart';
import 'package:one_solution/Pages/home_detai_page.dart';
// import 'package:one_solution/Pages/home_detail_full_page.dart';
// import 'package:one_solution/Pages/saved_for_later_page.dart';
import 'package:one_solution/Pages/checkout_page.dart';
import 'package:one_solution/Pages/home_detail_full_page.dart';
import 'package:one_solution/Pages/saved_for_later_page.dart';

import 'package:one_solution/models/cart_item.dart';
import 'package:one_solution/models/onesolution.dart';

import 'package:one_solution/services/cartService.dart';
import 'package:one_solution/services/coupen_services.dart';
import 'package:one_solution/services/saved_for_later_service.dart';

class CartPage extends StatefulWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<CartItem>> _cartFuture;

  final Color actionColor = const Color(0xFFC62828);

  final TextEditingController couponController = TextEditingController();
  Map<String, dynamic>? appliedCoupon;
  double couponDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    _cartFuture = _loadCart();
    cartCountNotifier.addListener(_refreshCart);
  }

  @override
  void dispose() {
    cartCountNotifier.removeListener(_refreshCart);
    couponController.dispose();
    super.dispose();
  }

  void _refreshCart() {
    setState(() {
      _cartFuture = _loadCart();
    });
  }
Widget _etaCard() {
  final eta = DateTime.now().add(const Duration(days: 4));
  final etaText = "${eta.day}/${eta.month}/${eta.year}";

  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.deepPurple.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.local_shipping, color: Colors.deepPurple),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Estimated Delivery by $etaText",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ],
    ),
  );
}

  Future<List<CartItem>> _loadCart() async {
    try {
      return await CartService.fetchCart(widget.userId);
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------
  // COUPON SYSTEM
  // ---------------------------------------------

  double _subtotal(List<CartItem> items) =>
      items.fold(0.0, (sum, i) => sum + i.offerPrice * i.quantity);

  String _format(double v) => "₹${v.toStringAsFixed(2)}";

  Future<void> _applyCoupon(List<CartItem> items) async {
    final String code = couponController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter coupon code")),
      );
      return;
    }

    final coupon = await CouponService.applyCoupon(code);

    if (coupon == null) {
      setState(() {
        appliedCoupon = null;
        couponDiscount = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid or expired coupon")),
      );
      return;
    }

    double subtotal = _subtotal(items);
    double minPurchase = (coupon["MinimumPurchase"] ?? 0).toDouble();
    if (subtotal < minPurchase) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Minimum purchase ₹$minPurchase required"),
            duration: const Duration(seconds: 2)),
      );
      return;
    }

    double discount = 0.0;
    String type = coupon["DiscountType"].toString().toLowerCase();

    if (type == "fixed") {
      discount = (coupon["DiscountAmount"] ?? 0).toDouble();
    } else {
      discount = subtotal * ((coupon["DiscountAmount"] ?? 0) / 100);
    }

    if (discount > subtotal) discount = subtotal;

    setState(() {
      appliedCoupon = coupon;
      couponDiscount = discount;
    });
  }

  void _removeCoupon() {
    setState(() {
      appliedCoupon = null;
      couponDiscount = 0.0;
      couponController.clear();
    });
  }

  Future<void> _openCouponList(List<CartItem> items, double subtotal) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CouponListPage(subtotal: subtotal)),
    );

    if (selected != null) {
      couponController.text = selected["Code"];
      await _applyCoupon(items);
    }
  }

  // ---------------------------------------------
  // SAVE FOR LATER
  // ---------------------------------------------

  double _calculateSavePerItem(CartItem item) =>
      item.price - item.offerPrice > 0
          ? item.price - item.offerPrice
          : 0;

  Future<void> _saveForLater(CartItem item) async {
    await SavedForLaterService.moveToSaved(
        widget.userId, item.productId.toString());
    await CartService.removeFromCart(item.id);
    _refreshCart();
  }

  // ---------------------------------------------
  // QTY UPDATE
  // ---------------------------------------------

  Future<void> _incrementQty(CartItem item, int stock) async {
    if (item.quantity >= stock) return;
    await CartService.updateQuantity(item.id, item.quantity + 1);
    _refreshCart();
  }

  Future<void> _decrementQty(CartItem item) async {
    if (item.quantity <= 1) return;
    await CartService.updateQuantity(item.id, item.quantity - 1);
    _refreshCart();
  }

  Future<void> _removeFromCart(CartItem item) async {
    await CartService.removeFromCart(item.id);
    _refreshCart();
  }
// ---------------------------------------------
//  FUTURISTIC CART ITEM TILE (FINAL UPDATED)
// ---------------------------------------------
Widget _cartItemTile(CartItem item) {
  final Items? product = OnesolutionModel().getById(item.productId);
  final int stock = product?.stock ?? 0;

  String stockText = "In Stock";
  Color stockColor = Colors.green;

  if (stock == 0) {
    stockText = "OUT OF STOCK";
    stockColor = Colors.red;
  } else if (stock <= 10) {
    stockText = "$stock left!";
    stockColor = Colors.orange;
  }

  // ETA
  final eta = DateTime.now().add(const Duration(days: 4));
  final etaText = "${eta.day}/${eta.month}/${eta.year}";

  return GestureDetector(
    onTap: () {
      if (product != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeDetailFullPage(
              onesolution: product,
              heroTag: item.productId.toString(),
            ),
          ),
        );
      }
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(2, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRODUCT IMAGE
            Hero(
              tag: "cart_${item.productId}",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl.startsWith("http")
                      ? item.imageUrl
                      : "https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/product/product/${item.imageUrl}",
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // PRODUCT DETAILS
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // STOCK LABEL
                  Text(
                    stockText,
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ETA ROW
                  Row(
                    children: [
                      const Icon(Icons.local_shipping,
                          color: Colors.deepPurple, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Delivery by $etaText",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // PRICE
                  Row(
                    children: [
                      Text(
                        "₹${item.offerPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "₹${item.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.price > item.offerPrice)
                        Text(
                          "Save ₹${(item.price - item.offerPrice).toStringAsFixed(0)}",
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // QTY BUTTONS
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            item.quantity > 1 ? () => _decrementQty(item) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        "${item.quantity}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: (stock == 0 || item.quantity >= stock)
                            ? null
                            : () => _incrementQty(item, stock),
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: stock == 0 || item.quantity >= stock
                              ? Colors.grey
                              : Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),

                  // SAVE & REMOVE
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _saveForLater(item),
                        child: const Text("Save for later"),
                      ),
                      TextButton(
                        onPressed: () => _removeFromCart(item),
                        child: const Text(
                          "Remove",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  // ---------------------------------------------
  // MAIN UI
  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Your Cart",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SavedForLaterPage(userId: widget.userId),
                ),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<List<CartItem>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          final double subtotal = _subtotal(items);

          /// DELIVERY RULE → FREE ABOVE ₹2500
          final double deliveryCharge =
              subtotal > 2500 ? 0.0 : 49.0;

          final double effectiveCouponDiscount =
              couponDiscount > subtotal ? subtotal : couponDiscount;

          final double total =
              subtotal - effectiveCouponDiscount + deliveryCharge;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshCart(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 250),
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                            child: _cartItemTile(items[i])),
                      ),
                    ),
                  ),
                ),
              ),

              // BOTTOM SUMMARY CARD
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.local_offer_outlined,
                            color: Colors.deepPurple),
                        label: const Text("View Coupons"),
                        onPressed: items.isEmpty
                            ? null
                            : () => _openCouponList(items, subtotal),
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponController,
                            decoration: const InputDecoration(
                                labelText: "Enter coupon",
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                            onPressed: items.isEmpty
                                ? null
                                : () => _applyCoupon(items),
                            child: const Text("Apply")),
                        if (appliedCoupon != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _removeCoupon,
                          )
                      ],
                    ),

                    if (appliedCoupon != null)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Coupon (${appliedCoupon!['Code']})"),
                            Text("-₹${effectiveCouponDiscount.toStringAsFixed(2)}",
                                style:
                                    const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Subtotal"),
                        Text(_format(subtotal)),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Delivery"),
                        Text(_format(deliveryCharge)),
                      ],
                    ),

                    const Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(_format(total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          minimumSize:
                              const Size(double.infinity, 48)),
                      onPressed: items.isEmpty
                          ? null
                          : () {
                            final savings = items.fold(
  0.0,
  (s, i) => s + _calculateSavePerItem(i),
);

                           Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CheckoutPage(
      userId: widget.userId,
      cartItems: items,
      subtotal: subtotal,
      discount: savings + effectiveCouponDiscount,  // FIXED
      delivery: deliveryCharge,
      total: total,
      couponCode: appliedCoupon?["Code"],
      couponDiscount: effectiveCouponDiscount,
    ),
  ),
).then((_) => _refreshCart());


                            },
                      child: Text(
                        "Checkout • ₹${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
