import 'package:flutter/material.dart';
import 'package:one_solution/Pages/home_detai_page.dart';
import 'package:one_solution/models/onesolution.dart';
import 'package:one_solution/models/cart.dart';
import 'package:one_solution/services/api_service.dart';
import 'package:one_solution/services/cartService.dart';
import 'package:one_solution/services/wishlistService.dart';
import 'package:one_solution/widgets/home_widgets/onesolution_image.dart';
import 'package:velocity_x/velocity_x.dart';

class OnesolutionList extends StatefulWidget {
  final List<Items> items;
  final String userId; // ✅ from user session/login

  const OnesolutionList({
    super.key,
    required this.items,
    required this.userId,
  });

  @override
  State<OnesolutionList> createState() => _OnesolutionListState();
}

class _OnesolutionListState extends State<OnesolutionList> {
  final CartModel cart = CartModel();
  final Set<int> wishedItems = {};

  // ✅ Toggle wishlist (add/remove)
  Future<void> toggleWishlist(int productId, String productName) async {
    bool isWished = wishedItems.contains(productId);

    if (isWished) {
      final success = await WishlistService.removeFromWishlist(widget.userId, productId);
      if (success) {
        setState(() => wishedItems.remove(productId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$productName removed from wishlist")),
        );
      }
    } else {
      final success = await WishlistService.addToWishlist(widget.userId, productId);
      if (success) {
        setState(() => wishedItems.add(productId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$productName added to wishlist")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add to wishlist")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final limitedItems = widget.items.take(20).toList();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: limitedItems.length,
      itemBuilder: (context, index) {
        final item = limitedItems[index];
        final isInCart = cart.contains(item);
        final isWished = wishedItems.contains(item.id);
        final heroTag = 'product-${item.id}-$index'; // ✅ unique tag

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeDetailPage(
                  onesolution: item,
                  heroTag: heroTag, // ✅ pass hero tag to detail page
                ),
              ),
            );
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Hero animation + Safe image handling
                    Expanded(
                      child: Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: OnesolutionImage(
                            image: item.firstImage.startsWith('http')
                                ? item.firstImage
                                : "${ApiService.baseUrl.replaceAll('/api', '')}${item.firstImage}",
                            height: 150,
                          ),
                        ),
                      ),
                    ),

                    // ✅ Product info
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "₹${item.offerPrice}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (item.offerPrice < item.price)
                                Text(
                                  "₹${item.price}",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(width: 5),
                              if (item.offerPrice < item.price)
                                Text(
                                  "-${(((item.price - item.offerPrice) / item.price) * 100).round()}%",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ✅ Add to Cart button
                         ElevatedButton.icon(
  onPressed: () async {
    if (widget.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in first")),
      );
      return;
    }

    try {
      await CartService.addToCart(widget.userId, item.id, 1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${item.name} added to cart"),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        cart.add(item);
      });
    } catch (e) {
      debugPrint("❌ Error adding to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add to cart")),
      );
    }
  },
  icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
  label: Text(isInCart ? "In Cart" : "Add to Cart"),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1F1B29),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    textStyle: const TextStyle(fontSize: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
)

                        ],
                      ),
                    ),
                  ],
                ),

                // ✅ Wishlist icon (toggle)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: Icon(
                      isWished ? Icons.favorite : Icons.favorite_border,
                      color: Colors.pinkAccent,
                    ),
                    onPressed: () async {
                      await toggleWishlist(item.id, item.name);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



class OnesolutionItem extends StatefulWidget {
  final Items onesolution;
  final String userId;

  const OnesolutionItem({
    Key? key,
    required this.onesolution,
    required this.userId,
  }) : super(key: key);

  @override
  State<OnesolutionItem> createState() => _OnesolutionItemState();
}

class _OnesolutionItemState extends State<OnesolutionItem> {
  bool isWished = false;

  Future<void> toggleWishlist() async {
    if (isWished) {
      final success = await WishlistService.removeFromWishlist(
        widget.userId,
        widget.onesolution.id,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed from wishlist")),
        );
        setState(() => isWished = false);
      }
    } else {
      final success = await WishlistService.addToWishlist(
        widget.userId,
        widget.onesolution.id,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to wishlist")),
        );
        setState(() => isWished = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add to wishlist")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    final heroTag = 'wishlist-${widget.onesolution.id}'; // ✅ unique hero tag

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeDetailPage(
              onesolution: widget.onesolution,
              heroTag: heroTag, // ✅ pass same hero tag
            ),
          ),
        );
      },
      child: Card(
        elevation: isDark ? 2 : 6,
        color: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Hero Image
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: OnesolutionImage(
                    image: widget.onesolution.firstImage,
                    height: 120,
                    width: double.infinity,
                  ),
                ),
              ),

              10.heightBox,
              widget.onesolution.name.text.lg.color(primaryTextColor).bold.make(),
              widget.onesolution.description.text.sm.color(secondaryTextColor).make(),
              10.heightBox,
              "₹${widget.onesolution.price}".text.bold.xl.make(),

              8.heightBox,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final cart = CartModel();
                      final isInCart = cart.contains(widget.onesolution);

                      if (isInCart) {
                        cart.remove(widget.onesolution);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Item removed from cart")),
                        );
                      } else {
                        cart.add(widget.onesolution);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Item added to cart")),
                        );
                      }
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      "Add to cart",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: const Color(0xFF1F1B29),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isWished ? Icons.favorite : Icons.favorite_border,
                      color: Colors.pinkAccent,
                    ),
                    onPressed: toggleWishlist,
                  ),
                ],
              ),
            ],
          ),
        ),
      ).py16(),
    );
  }
}
