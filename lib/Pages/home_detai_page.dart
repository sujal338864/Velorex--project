// ignore_for_file: unused_local_variable


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Velorex/Pages/home_detail_full_page.dart';
import 'package:Velorex/models/brand_model.dart';
import 'package:Velorex/models/onesolution.dart';
import 'package:Velorex/services/api_service.dart';
import 'package:Velorex/services/brand_service.dart';
import 'package:Velorex/services/cartService.dart';
import 'package:Velorex/widgets/home_widgets/onesolution_image.dart';

// 🔹 Global notifier to update cart badge everywhere
ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

const Color _kAccentRed = Color(0xFFC62828);

class HomeDetailPage extends StatefulWidget {
  final Items onesolution;
  final String heroTag;
  final ScrollController? scrollController;

  const HomeDetailPage({
    super.key,
    required this.onesolution,
    required this.heroTag,
    this.scrollController,
  });

  @override
  State<HomeDetailPage> createState() => _HomeDetailPageState();
}

class _HomeDetailPageState extends State<HomeDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
        ..forward();
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

  Brand? _brand;
  bool _isLoadingBrand = true;
  List<dynamic> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadBrand();
     cartCountNotifier.addListener(() {
    _refreshCart();
  });
  }


  // 🔹 Fetch user's cart and update local + global count
  Future<void> _refreshCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final items = await CartService.fetchCart(user.id);
      setState(() {
        cartItems = items;
      });
      cartCountNotifier.value = items.length; // ✅ Update global count
      debugPrint("🔄 Cart refreshed: ${items.length} items");
    } catch (e) {
      debugPrint("❌ Error refreshing cart: $e");
    }
  }

  // 🔹 Load brand
  Future<void> _loadBrand() async {
    try {
      final service = BrandService();
      final brands = await service.getBrands();

      final matchedBrand = brands.firstWhere(
        (b) => b?.name.toLowerCase() == widget.onesolution.brand.toLowerCase(),
        orElse: () =>
            brands.isNotEmpty ? brands.first : Brand(id: 0, name: 'Unknown'),
      );

      setState(() {
        _brand = matchedBrand;
        _isLoadingBrand = false;
      });
    } catch (e) {
      print("❌ Error loading brands: $e");
      setState(() => _isLoadingBrand = false);
    }
  }

  // 🔹 Add to cart + refresh cart instantly
  Future<void> _addToCart() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in first")),
      );
      return;
    }

    try {
      final success = await CartService.addToCart(user.id, widget.onesolution.id, 1);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.onesolution.name} added to cart"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        await _refreshCart(); // ✅ update count immediately
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add to cart"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error adding to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    cartCountNotifier.removeListener(_refreshCart);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.onesolution;

    final imageUrl = item.firstImage.startsWith('http')
        ? item.firstImage
        : ApiService.baseUrl.replaceAll('/api', '') + item.firstImage;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Hero(
                tag: widget.heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 280,
                    child: PageView.builder(
                      itemCount: item.images.isNotEmpty ? item.images.length : 1,
                      controller: PageController(viewportFraction: 1),
                      itemBuilder: (context, index) {
                        final img = item.images.isNotEmpty
                            ? item.images[index]
                            : item.firstImage;

                        final imageUrl = img.startsWith('http')
                            ? img
                            : ApiService.baseUrl.replaceAll('/api', '') + img;

                        return OnesolutionImage(
                          image: imageUrl,
                          height: 280,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeDetailFullPage(
                          onesolution: widget.onesolution,
                          heroTag: widget.heroTag,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'See More Details →',
                    style: TextStyle(
                      color: _kAccentRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '₹${item.offerPrice}',
                    style: const TextStyle(
                      color: _kAccentRed,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (item.offerPrice < item.price)
                    Text(
                      '₹${item.price}',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  const Spacer(),
                  if (item.offerPrice < item.price)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${item.discountPercent}%',
                        style: const TextStyle(
                          color: _kAccentRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccentRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description.isNotEmpty
                    ? item.description
                    : 'No description available',
              ),
              const SizedBox(height: 20),
              if (_isLoadingBrand)
                const Center(child: CircularProgressIndicator())
              else if (_brand != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Brand: ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _brand!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text('Brand: Not available'),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
