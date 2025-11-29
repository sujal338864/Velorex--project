// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:one_solution/models/onesolution.dart';
import 'package:one_solution/services/cartService.dart';
import 'package:one_solution/services/wishlistService.dart';
import 'package:one_solution/Pages/home_detail_full_page.dart'; // ✅ Import your detail page

class WishlistPage extends StatefulWidget {
  final String userId;
  const WishlistPage({super.key, required this.userId});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Items> wishlist = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final data = await WishlistService.getWishlist(widget.userId);
      setState(() {
        wishlist = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading wishlist: $e");
    }
  }

  Future<void> moveToCart(Items item) async {
    try {
      final added = await CartService.addToCart(widget.userId, item.id, 1);
      if (added) {
        await WishlistService.removeFromWishlist(widget.userId, item.id);
        if (mounted) {
          setState(() {
            wishlist.remove(item);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Moved to cart successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Failed to add to cart')),
        );
      }
    } catch (e) {
      debugPrint("❌ Error moving to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeItem(Items item) async {
    try {
      final ok =
          await WishlistService.removeFromWishlist(widget.userId, item.id);
      if (ok) {
        if (mounted) {
          setState(() => wishlist.remove(item));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Removed from wishlist')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to remove from wishlist')),
        );
      }
    } catch (e) {
      debugPrint("❌ _removeItem error: $e");
    }
  }

  String _formatPrice(num price) =>
      "₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Your Wishlist ❤️",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : wishlist.isEmpty
              ? const Center(
                  child: Text("Your wishlist is empty 🛒",
                      style: TextStyle(fontSize: 18)),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    itemCount: wishlist.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = wishlist[index];
                    final imageUrl = item.images.isNotEmpty
    ? item.images.first
    : "https://via.placeholder.com/150";


                      final save = item.price - item.offerPrice;
                      final discount =
                          ((save / item.price) * 100).clamp(0, 99).round();

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeDetailFullPage(
                                onesolution: item,
                                heroTag: 'wishlist_${item.id}',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Image with Hero animation
                              Hero(
                                tag: 'wishlist_${item.id}',
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14)),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.broken_image, size: 60),
                                  ),
                                ),
                              ),

                              // 🔹 Info
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _formatPrice(item.offerPrice),
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatPrice(item.price),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "-$discount%",
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 🔹 Buttons
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () => moveToCart(item),
                                      icon: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.deepPurple),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeItem(item),
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                    ),
                                  ],
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
