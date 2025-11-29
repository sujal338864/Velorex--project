// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:one_solution/services/cartService.dart';
import '../models/onesolution.dart';
import '../services/saved_for_later_service.dart';

class SavedForLaterPage extends StatefulWidget {
  final String userId;
  const SavedForLaterPage({super.key, required this.userId});

  @override
  State<SavedForLaterPage> createState() => _SavedForLaterPageState();
}

class _SavedForLaterPageState extends State<SavedForLaterPage> {
  late Future<List<Items>> _savedItemsFuture;
  List<Items> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
  }

  void _loadSavedItems() {
    _savedItemsFuture = SavedForLaterService.getSavedItems(widget.userId);
  }

  Future<void> _refreshItems() async {
    final items = await SavedForLaterService.getSavedItems(widget.userId);
    setState(() => _savedItems = items);
  }

  Future<void> _moveToCart(Items item) async {
    await CartService.addToCart(widget.userId, item.id, 1);
    await SavedForLaterService.deleteSavedItem(widget.userId, item.id.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Moved to cart successfully ✅"),
        backgroundColor: Colors.green,
      ),
    );
    _refreshItems();
  }

  Future<void> _removeItem(Items item) async {
    await SavedForLaterService.deleteSavedItem(widget.userId, item.id.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Item removed ❌"),
        backgroundColor:const Color(0xFFC62828),
      ),
    );
    _refreshItems();
  }

  String _formatPrice(num price) =>
      "₹${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      )}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffefefe),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "Saved for Later ",
          style: TextStyle(
            color:const Color(0xFFC62828),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<List<Items>>(
        future: _savedItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: const Color(0xFFC62828)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color:const Color(0xFFC62828)),
              ),
            );
          }

          _savedItems = snapshot.data ?? [];
          if (_savedItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, size: 80, color: Colors.redAccent),
                  SizedBox(height: 10),
                  Text(
                    "No saved items yet 💾",
                    style: TextStyle(
                        fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.redAccent,
            onRefresh: _refreshItems,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // 🧾 Summary Bar
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: const Color(0xFFC62828)),
                      const SizedBox(width: 8),
                      Text(
                        "${_savedItems.length} items saved for later",
                        style: const TextStyle(
                          color:const Color(0xFFC62828),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🧩 Product Cards
                ..._savedItems.map((item) {
               final imageUrl = (item.images.isNotEmpty)
    ? item.images.first
    : "https://via.placeholder.com/150";



                  final save = item.price - item.offerPrice;
                  final discount =
                      ((save / item.price) * 100).clamp(0, 99).round();

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC62828).withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC62828).withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🖼️ Product Image
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              height: 190,
                              child: const Center(
                                  child: CircularProgressIndicator(
                                color:const Color(0xFFC62828),
                              )),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        // 📄 Product Info
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    _formatPrice(item.offerPrice),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFC62828),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatPrice(item.price),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "-$discount%",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 🧭 Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFC62828),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _moveToCart(item),
                                      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                                      label: const Text("Move to Cart"),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color:const Color(0xFFC62828)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _removeItem(item),
                                      icon: const Icon(Icons.delete_outline, color: const Color(0xFFC62828)),
                                      label: const Text(
                                        "Remove",
                                        style: TextStyle(color: const Color(0xFFC62828)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
