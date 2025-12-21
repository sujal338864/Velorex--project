// home_page.dart
// ignore_for_file: unused_field, unused_local_variable, deprecated_member_use, unnecessary_null_comparison


import 'package:Velorex/services/brand_service.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Velorex/Pages/WishlistPage.dart';
import 'package:Velorex/Pages/home_detai_page.dart';
import 'package:Velorex/Pages/search_page.dart';
import 'package:Velorex/models/category_model.dart';
import 'package:Velorex/models/onesolution.dart';
import 'package:Velorex/services/api_service.dart';
import 'package:Velorex/services/cartService.dart';
import 'package:Velorex/services/category_service.dart';
import 'package:Velorex/services/produc_services.dart';
import 'package:Velorex/services/wishlistService.dart';
import 'package:Velorex/widgets/home_widgets/onesolution_image.dart';

const Color _kAccentRed = Color(0xFFC62828);
const Color _kSoftGray = Color(0xFFF5F5F5);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  List<Items> _items = [];
  List<Category> _categories = [];
  List<Map<String, dynamic>> _posters = [];

  int? _selectedCategoryId;
  List<Items> _filteredItems = [];

  final TextEditingController _searchController = TextEditingController();

  // Poster auto-scrolling
  PageController? _posterController;
  int _posterIndex = 0;
  bool _posterAutoScrollOn = true;

  // SORT
  String _sortType = 'none';

  // FILTERS (generic – works for all categories)
  double _minPrice = 0;
  double _maxPrice = 0;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 0;

  bool _onlyDiscounted = false;
  bool _inStockOnly = false;
  bool _onlySponsored = false;

  final Set<String> _selectedBrands = {};

  @override
  void initState() {
    super.initState();
    _posterController = PageController(viewportFraction: 0.9);
    _loadAllData();
    _startPosterAutoScroll();
  }

  void _startPosterAutoScroll() {
    Future.delayed(const Duration(seconds: 4)).then((_) {
      if (!mounted) return;
      if (!_posterAutoScrollOn) return;
      if (_posters.isEmpty) {
        _startPosterAutoScroll();
        return;
      }
      _posterIndex = (_posterIndex + 1) % (_posters.isEmpty ? 1 : _posters.length);
      _posterController?.animateToPage(
        _posterIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _startPosterAutoScroll();
    });
  }

  @override
  void dispose() {
    _posterController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // Load Products (cache if available)
      if (OnesolutionModel.items.isNotEmpty) {
        _items = OnesolutionModel.items;
      } else {
        final products = await ProductService.getProducts();
        OnesolutionModel.items = products;
        _items = products;
      }

      // Initialize price range based on all items
      _initPriceRange();

      // Load Categories
      final categoryService = CategoryService();
      final cats = await categoryService.getCategories();
      _categories = cats;

      // Load Posters
      final posters = await BrandService.getPosters();
      _posters = posters;

      // Reset selection if current category removed
      if (_selectedCategoryId != null &&
          !_categories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = null;
        _filteredItems.clear();
      }
    } catch (e) {
      debugPrint('❌ Error loading home data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initPriceRange() {
    if (_items.isEmpty) {
      _minPrice = 0;
      _maxPrice = 0;
      _selectedMinPrice = 0;
      _selectedMaxPrice = 0;
      return;
    }
    final prices = _items.map((e) => e.offerPrice.toDouble()).toList()
      ..sort();
    _minPrice = prices.first;
    _maxPrice = prices.last;
    _selectedMinPrice = _minPrice;
    _selectedMaxPrice = _maxPrice;
  }

  void _openQuickView(Items item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return HomeDetailPage(
            onesolution: item,
            scrollController: controller,
            heroTag: 'product-${item.id}',
          );
        },
      ),
    );
  }

  void _selectCategory(Category? c) {
    setState(() {
      if (c == null) {
        _selectedCategoryId = null;
        _filteredItems.clear();
      } else {
        _selectedCategoryId = c.id;
        _filteredItems =
            _items.where((item) => item.categoryId == c.id).toList();
      }
    });
  }

  // -------- SORTING --------
  void _applySort(List<Items> list) {
    switch (_sortType) {
      case 'low_to_high':
        list.sort((a, b) => a.offerPrice.compareTo(b.offerPrice));
        break;
      case 'high_to_low':
        list.sort((a, b) => b.offerPrice.compareTo(a.offerPrice));
        break;
      case 'name_az':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_za':
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
  }

  // -------- FILTERING --------
  List<Items> _applyFilters(List<Items> list) {
    return list.where((item) {
      final priceOk = item.offerPrice.toDouble() >= _selectedMinPrice &&
          item.offerPrice.toDouble() <= _selectedMaxPrice;

      final discountOk = !_onlyDiscounted || item.offerPrice < item.price;
      final stockOk = !_inStockOnly || item.stock! > 0;
      // final sponsoredOk = !_onlySponsored || item.isSponsored;
      final brandOk =
          _selectedBrands.isEmpty || _selectedBrands.contains(item.brand);

      return priceOk && discountOk && stockOk  && brandOk;
    }).toList();
  }

  List<String> _getAvailableBrandsForCurrentCategory() {
    final baseList =
        _selectedCategoryId == null ? _items : _filteredItems;
    final set = <String>{};
    for (final it in baseList) {
      final b = it.brand.trim();
      if (b.isNotEmpty) set.add(b);
    }
    final result = set.toList()..sort();
    return result;
  }

  // -------- SORT BOTTOM SHEET --------
  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sort By",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text("Price: Low → High"),
                onTap: () {
                  setState(() => _sortType = 'low_to_high');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Price: High → Low"),
                onTap: () {
                  setState(() => _sortType = 'high_to_low');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Name: A → Z"),
                onTap: () {
                  setState(() => _sortType = 'name_az');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Name: Z → A"),
                onTap: () {
                  setState(() => _sortType = 'name_za');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Reset Sort"),
                onTap: () {
                  setState(() => _sortType = 'none');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // -------- FILTER BOTTOM SHEET (DYNAMIC) --------
  void _openFilterSheet() {
    final availableBrands = _getAvailableBrandsForCurrentCategory();

    // Ensure price range is valid for current list
    final baseList =
        _selectedCategoryId == null ? _items : _filteredItems;
    if (baseList.isNotEmpty) {
      final prices = baseList.map((e) => e.offerPrice.toDouble()).toList()
        ..sort();
      final minLocal = prices.first;
      final maxLocal = prices.last;

      // If current global bounds are 0 or out of range, reset to local
      if (_minPrice == 0 && _maxPrice == 0) {
        _minPrice = minLocal;
        _maxPrice = maxLocal;
        _selectedMinPrice = minLocal;
        _selectedMaxPrice = maxLocal;
      } else {
        // Clamp selected range within local
        if (_selectedMinPrice < minLocal) _selectedMinPrice = minLocal;
        if (_selectedMaxPrice > maxLocal) _selectedMaxPrice = maxLocal;
        _minPrice = minLocal;
        _maxPrice = maxLocal;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return StatefulBuilder(
              builder: (context, update) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text(
                        "Filters",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // PRICE RANGE
                            const Text(
                              "Price Range",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            if (_minPrice == _maxPrice)
                              Text(
                                "Price filter not available for this selection.",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600),
                              )
                            else ...[
                              Text(
                                "₹${_selectedMinPrice.toInt()} - ₹${_selectedMaxPrice.toInt()}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              RangeSlider(
                                values: RangeValues(
                                    _selectedMinPrice, _selectedMaxPrice),
                                min: _minPrice,
                                max: _maxPrice,
                                divisions:
                                    ((_maxPrice - _minPrice) ~/ 500).clamp(1, 200),
                                labels: RangeLabels(
                                  "₹${_selectedMinPrice.toInt()}",
                                  "₹${_selectedMaxPrice.toInt()}",
                                ),
                                onChanged: (v) {
                                  update(() {
                                    _selectedMinPrice = v.start;
                                    _selectedMaxPrice = v.end;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 12),

                            // BRAND FILTER (dynamic per category)
                            if (availableBrands.isNotEmpty) ...[
                              const Text(
                                "Brand",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              ...availableBrands.map(
                                (b) => CheckboxListTile(
                                  value: _selectedBrands.contains(b),
                                  onChanged: (v) {
                                    update(() {
                                      if (v == true) {
                                        _selectedBrands.add(b);
                                      } else {
                                        _selectedBrands.remove(b);
                                      }
                                    });
                                  },
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    b,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // OTHER TOGGLES
                            SwitchListTile(
                              value: _onlyDiscounted,
                              onChanged: (v) =>
                                  update(() => _onlyDiscounted = v),
                              title: const Text("Only Discounted (Offer Price)"),
                              dense: true,
                            ),
                            SwitchListTile(
                              value: _inStockOnly,
                              onChanged: (v) =>
                                  update(() => _inStockOnly = v),
                              title: const Text("In Stock Only"),
                              dense: true,
                            ),
                            SwitchListTile(
                              value: _onlySponsored,
                              onChanged: (v) =>
                                  update(() => _onlySponsored = v),
                              title: const Text("Sponsored Products Only"),
                              dense: true,
                            ),
                          ],
                        ),
                      ),

                      // ACTION BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                update(() {
                                  _selectedMinPrice = _minPrice;
                                  _selectedMaxPrice = _maxPrice;
                                  _onlyDiscounted = false;
                                  _inStockOnly = false;
                                  _onlySponsored = false;
                                  _selectedBrands.clear();
                                });
                              },
                              child: const Text("Reset All"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kAccentRed,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: const Text("Apply"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // base list from category selection
    List<Items> showItems =
        _selectedCategoryId == null ? _items : _filteredItems;

    // apply filters
    showItems = _applyFilters(showItems);

    // apply sorting
    _applySort(showItems);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 49, 47, 47),
        elevation: 0,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: const [
              TextSpan(
                  text: 'V',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              TextSpan(
                  text: 'e',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              TextSpan(
                  text: 'L',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              TextSpan(
                  text: 'o',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              TextSpan(
                  text: 'R',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              TextSpan(
                  text: 'e',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              TextSpan(
                  text: 'X',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 1.2,
              fontFamily: 'Poppins',
              shadows: [
                Shadow(
                    color: Colors.redAccent,
                    blurRadius: 6,
                    offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAccentRed))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: _kAccentRed,
              child: CustomScrollView(
                slivers: [
                  // 🔍 Search + Wishlist Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Fake Search Bar
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SearchPage()),
                                );
                              },
                              child: Container(
                                height: 45,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _kSoftGray,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          Colors.redAccent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.search,
                                        color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text(
                                      'Search products...',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Wishlist Button
                          GestureDetector(
                            onTap: () {
                              final user =
                                  Supabase.instance.client.auth.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Please log in to view your wishlist")),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WishlistPage(userId: user.id),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SORT + FILTER row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _openSortSheet,
                              icon: const Icon(Icons.sort),
                              label: const Text("Sort"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _openFilterSheet,
                              icon: const Icon(Icons.filter_list),
                              label: const Text("Filter"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Posters carousel
                  if (_posters.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PageView.builder(
                              controller: _posterController,
                              itemCount: _posters.length,
                              onPageChanged: (idx) => _posterIndex = idx,
                              itemBuilder: (context, i) {
                                final poster = _posters[i];
                                final imageUrl = (poster['image_url'] ?? '').toString();


                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (context, child,
                                          loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                            child: CircularProgressIndicator(
                                                color: _kAccentRed));
                                      },
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(
                                        child: Center(
                                          child: Icon(Icons.broken_image,
                                              size: 48, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                  // Categories horizontal
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => _selectCategory(null),
                                child: Container(
                                  width: 84,
                                  decoration: BoxDecoration(
                                    color: _selectedCategoryId == null
                                        ? Colors.redAccent
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'All',
                                      style: TextStyle(
                                        color: _selectedCategoryId == null
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final c = _categories[i - 1];
                          final bool selected =
                              _selectedCategoryId == c.id;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _selectCategory(c),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.redAccent
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 16, top: 24, bottom: 8),
                      child: Text(
                        "🔥 Trending Now",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Product grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= showItems.length) {
                            return const SizedBox.shrink();
                          }
                          final item = showItems[index];
                          return _ProductCard(
                            item: item,
                            onTap: () => _openQuickView(item),
                          );
                        },
                        childCount: showItems.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }
}
class _ProductCard extends StatefulWidget {
  final Items item;
  final VoidCallback onTap;

  const _ProductCard({required this.item, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _currentImage = 0;
  late PageController _pageController;
  bool _isWishlisted = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please log in to use wishlist")),
      );
      return;
    }
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (_isWishlisted) {
        final removed = await WishlistService.removeFromWishlist(
            user.id, widget.item.id);
        if (removed) {
          setState(() => _isWishlisted = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("💔 Removed")));
        }
      } else {
        final added =
            await WishlistService.addToWishlist(user.id, widget.item.id);
        if (added) {
          setState(() => _isWishlisted = true);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("❤️ Added")));
        }
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _addToCart() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please log in to add items to cart")),
      );
      return;
    }

    // ❗ DO NOT ADD if stock is 0
    if ((widget.item.stock ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Item Out of Stock")),
      );
      return;
    }

    final added =
        await CartService.addToCart(user.id, widget.item.id, 1);
    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🛒 ${widget.item.name} added to cart!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final images = item.images.isNotEmpty ? item.images : [item.firstImage];
    final int stock = item.stock ?? 0;

    // --------------------------
    //  STOCK LABEL CONDITIONS
    // --------------------------
    String stockLabel = "";
    Color stockColor = Colors.green;

    if (stock == 0) {
      stockLabel = "Out of Stock";
      stockColor = Colors.red;
    } else if (stock <= 10) {
      stockLabel = "Only $stock left";
      stockColor = Colors.orange;
    } else {
      stockLabel = "In Stock";
      stockColor = Colors.green;
    }

    final bool disableCart = stock == 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------
            // IMAGE + BADGE
            // --------------------------
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (context, i) {
                        final img = images[i];
                        final url = img.startsWith('http')
                            ? img
                            : ApiService.baseUrl.replaceAll('/api', '') + img;
                        return OnesolutionImage(
                          image: url,
                          height: 150,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                ),

                // ---- STOCK LABEL BADGE ----
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stockLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --------------------------
            // TEXT + PRICE + BUTTONS
            // --------------------------
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 4),

                  // PRICE
                  Row(
                    children: [
                      Text(
                        '₹${item.offerPrice}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      if (item.offerPrice < item.price)
                        Text(
                          '₹${item.price}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Wishlist + Cart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ❤️ Wishlist
                      GestureDetector(
                        onTap: _toggleWishlist,
                        child: Icon(
                          _isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              _isWishlisted ? Colors.red : Colors.grey.shade600,
                        ),
                      ),

                      // 🛒 Add to Cart
                      GestureDetector(
                        onTap: disableCart ? null : _addToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                disableCart ? Colors.grey : Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white, size: 20),
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
    );
  }
}
