// ignore_for_file: deprecated_member_use


import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Velorex/Pages/home_detai_page.dart';
import 'dart:math';
import 'package:Velorex/models/category_model.dart';
import 'package:Velorex/models/onesolution.dart';
import 'package:Velorex/models/subcategory_model.dart';
import 'package:Velorex/services/cartService.dart';
import 'package:Velorex/services/produc_services.dart';
import 'package:Velorex/services/user_subcategory_service.dart';
import 'package:Velorex/services/wishlistService.dart';

class SubcategoryPage extends StatefulWidget {
  final Category category;
  final String userId;
  const SubcategoryPage({
    super.key,
    required this.category,
    required this.userId,
  });

  @override
  State<SubcategoryPage> createState() => _SubcategoryPageState();
}

class _SubcategoryPageState extends State<SubcategoryPage> {
  List<Subcategory> subcategories = [];
  List<Items> products = [];
  int? selectedSubcategoryId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSubcategories();
  }

  Future<void> loadSubcategories() async {
    setState(() => isLoading = true);
    try {
      subcategories =
          await SubcategoryService.fetchSubcategories(widget.category.id);
      if (subcategories.isNotEmpty) {
        selectedSubcategoryId = subcategories.first.subcategoryId;
        await loadProducts(subcategories.first.subcategoryId);
      }
    } catch (e) {
      debugPrint("❌ Error loading subcategories: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
 Future<void> loadProducts(int subcategoryId) async {
  setState(() {
    isLoading = true;
    selectedSubcategoryId = subcategoryId;
  });

  try {
    // fetch all products (cached in your ProductService)
    final allProducts = await ProductService.getProducts();

    // Filter only products matching subcategory
    final filteredProducts = allProducts.where((p) {
      return p.subcategoryId != null &&
          p.subcategoryId == subcategoryId;
    }).toList();

    setState(() {
      products = filteredProducts;
    });

    debugPrint("🟢 Showing ${filteredProducts.length} products for subcategory $subcategoryId");
  } catch (e) {
    debugPrint("❌ Error loading products: $e");
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.redAccent),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔹 Horizontal Subcategory Tabs
          SizedBox(
            height: 65,
            child: subcategories.isEmpty
                ? const Center(child: Text("No subcategories"))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: subcategories.length,
                    itemBuilder: (context, index) {
                      final sub = subcategories[index];
                      final isSelected =
                          sub.subcategoryId == selectedSubcategoryId;
                      return GestureDetector(
                        onTap: () => loadProducts(sub.subcategoryId),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.redAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              sub.name,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 🔹 Product Grid (Amazon / Flipkart style)
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.redAccent),
                  )
                : products.isEmpty
                    ? const Center(
                        child: Text(
                          "No products available",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final item = products[index];
                          return _buildCard(context, item);
                        },
                      ),
          ),
        ],
      ),
    );
  }
// 🔸 Product Card (Amazon / Flipkart Style)
Widget _buildCard(BuildContext context, Items item) {
  final discountPercent = item.price > 0
      ? ((item.price - item.offerPrice) / item.price * 100).round()
      : 0;
final imageUrl = item.images.isNotEmpty
    ? item.images.first
    : item.firstImage;

  final random = Random();
  final rating = (3 + random.nextDouble() * 2).toStringAsFixed(1);
  final reviews = 50 + random.nextInt(200);
  final deliveryDays = 2 + random.nextInt(4);

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomeDetailPage(
            onesolution: item,
            heroTag: 'product_${item.id}',
          ),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Product Image + Wishlist
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
              ),
              if (discountPercent > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "-$discountPercent%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () async {
                    final added = await WishlistService.addToWishlist(
                      widget.userId,
                      item.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        content: Text(
                          added
                              ? "❤️ Added to wishlist"
                              : "❌ Already in wishlist or failed",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: Colors.redAccent, size: 20),
                  ),
                ),
              ),
            ],
          ),

          // 🔹 Info Section (scrollable if needed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              rating,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            const Icon(Icons.star,
                                color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "($reviews)",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "₹${item.offerPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (discountPercent > 0)
                        Text(
                          "₹${item.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 3),
                  Text(
                    "Free delivery in $deliveryDays days",
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child:ElevatedButton(
  onPressed: () async {
    final success = await CartService.addToCart(
      widget.userId,
      item.id,
      1, // quantity = 1 for now
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        content: Text(
          success
              ? "🛒 ${item.name} added to cart"
              : "❌ Failed to add ${item.name} to cart",
        ),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.redAccent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(vertical: 6),
  ),
  child: const Text(
    "Add to Cart",
    style: TextStyle(fontSize: 12),
  ),
),

                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}