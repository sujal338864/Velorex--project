// ignore_for_file: deprecated_member_use

import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:one_solution/models/brand_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Velorex/models/onesolution.dart';
import 'package:Velorex/models/spec_models.dart';
import 'package:Velorex/services/api_service.dart';
import 'package:Velorex/services/cartService.dart';
import 'package:Velorex/services/produc_services.dart';
import 'package:Velorex/widgets/home_widgets/onesolution_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const Color _kAccentRed = Color(0xFFC62828);

class HomeDetailFullPage extends StatefulWidget {
  final Items onesolution;
  final String heroTag;

  const HomeDetailFullPage({
    super.key,
    required this.onesolution,
    required this.heroTag,
  });

  @override
  State<HomeDetailFullPage> createState() => _HomeDetailFullPageState();
}

class _HomeDetailFullPageState extends State<HomeDetailFullPage> {
  int _currentImage = 0;

  /// BRAND (reserved if you want to show brand later)
  // Brand? _brand;
  // bool _isLoadingBrand = true;

  /// VARIANTS
  List<Map<String, dynamic>> variantChildren = [];
  Map<String, dynamic>? selectedChild;
  Map<String, dynamic>? _parentVariant;
  bool _isLoadingVariants = false;

  /// 🔙 VARIANT HISTORY (for back button)
  /// null = parent/original product, map = a selected child variant
  final List<Map<String, dynamic>?> _variantHistory = [];

  /// YOUTUBE VIDEO
  YoutubePlayerController? _ytController;
  bool _isVideoVisible = false;
  bool _isMiniPlayer = false;

  /// SPECS
  bool _isLoadingSpecs = false;
  List<SpecSection> _specSections = [];
  Map<int, String> _specValues = {}; // FieldID -> Value

  /// ⭐ RATINGS
  bool _isLoadingRating = false;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  List<_ProductReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadVariantData();
    _loadSpecsFor(widget.onesolution.id); // initial product (can be parent or child)
    _loadRatingsFor(widget.onesolution.id); // ⭐ load rating for initial product
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // SMALL HELPERS
  // ---------------------------------------------------------
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _extractVariantLabel(String fullName) {
    final start = fullName.indexOf('(');
    final end = fullName.lastIndexOf(')');
    if (start != -1 && end != -1 && end > start) {
      final inside = fullName.substring(start + 1, end).trim();
      if (inside.isNotEmpty) return inside;
    }
    return fullName;
  }

 Future<String> _getUserDisplayName() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "User";

    final response = await http.get(
      Uri.parse("http://10.81.70.36:3000/api/profile/${user.id}"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["name"] != null && data["name"].toString().trim().isNotEmpty) {
        return data["name"].toString();
      }
    }
  } catch (e) {
    print("❌ Profile name load error: $e");
  }

  return "User";
}

  // ---------------------------------------------------------
  // VARIANT FETCH
  // ---------------------------------------------------------
  Future<void> _loadVariantData() async {
    setState(() => _isLoadingVariants = true);

    try {
      final int parentId =
          (widget.onesolution.parentProductId != null && widget.onesolution.parentProductId != 0)
              ? widget.onesolution.parentProductId!
              : widget.onesolution.id;

      final resp = await ProductService.getProductWithVariants(parentId);

      if (resp == null) {
        setState(() {
          variantChildren = [];
          selectedChild = null;
          _parentVariant = null;
          _variantHistory.clear();
        });
        return;
      }

      final parsedAll = <Map<String, dynamic>>[];

      void addProduct(dynamic src, {bool isParent = false}) {
        if (src is! Map) return;
        final m = Map<String, dynamic>.from(src);

        final imagesField = m['images'];
        List<String> urls = [];

        if (imagesField is List) {
          for (final item in imagesField) {
            if (item is Map && item['ImageURL'] != null) {
              urls.add(item['ImageURL'].toString());
            } else if (item is String) {
              urls.add(item);
            }
          }
        } else if (m['ImageUrls'] is String &&
            (m['ImageUrls'] as String).isNotEmpty) {
          urls = (m['ImageUrls'] as String)
              .split(',')
              .map((e) => e.trim())
              .toList();
        }

        m['__images'] = urls;
        m['__id'] = _toInt(m['id'] ?? m['ProductID'] ?? m['productId']);
        m['__price'] = _toDouble(m['price'] ?? m['Price']);
        m['__offerPrice'] = _toDouble(m['offerPrice'] ?? m['OfferPrice']);
        m['__name'] = m['name'] ?? m['Name'] ?? '';

        m['__videoUrl'] = (m['VideoUrl'] ??
                m['videoUrl'] ??
                m['video'] ??
                m['youtubeUrl'] ??
                m['YoutubeUrl'])
            ?.toString();

        m['__isParent'] = isParent;
        parsedAll.add(m);
      }

      if (resp['parent'] != null) {
        addProduct(resp['parent'], isParent: true);
      }

      final List rawChildren = (resp['children'] ?? []) as List;
      for (final c in rawChildren) {
        addProduct(c, isParent: false);
      }

      if (parsedAll.isEmpty) {
        setState(() {
          variantChildren = [];
          selectedChild = null;
          _parentVariant = null;
          _variantHistory.clear();
        });
        return;
      }

      final currentId = widget.onesolution.id;
      Map<String, dynamic>? currentVariant;

      try {
        currentVariant =
            parsedAll.firstWhere((m) => m['__id'] == currentId, orElse: () => {});
        if (currentVariant.isEmpty) currentVariant = null;
      } catch (_) {
        currentVariant = null;
      }

      final others =
          parsedAll.where((m) => m['__id'] != currentId).toList();

      Map<String, dynamic>? parentNorm;
      try {
        parentNorm = parsedAll.firstWhere((m) => m['__isParent'] == true,
            orElse: () => {});
        if (parentNorm.isEmpty) parentNorm = null;
      } catch (_) {
        parentNorm = null;
      }

      setState(() {
        selectedChild = currentVariant;
        variantChildren = others;
        _parentVariant = parentNorm;
        _variantHistory.clear(); // 🔄 reset history on fresh load
      });

      // after loading variants, reload specs + ratings for the current active product
      _loadSpecsFor(activeId);
      _loadRatingsFor(activeId);
    } catch (e) {
      print("❌ Variant load error: $e");
      setState(() {
        variantChildren = [];
        selectedChild = null;
        _parentVariant = null;
        _variantHistory.clear();
      });
    } finally {
      setState(() => _isLoadingVariants = false);
    }
  }

  // ---------------------------------------------------------
  // ACTIVE PRODUCT
  // ---------------------------------------------------------
  int get activeId =>
      selectedChild != null ? selectedChild!['__id'] as int : widget.onesolution.id;

  String get activeName => selectedChild != null
      ? (selectedChild!['__name'] ?? selectedChild!['name'] ?? '')
      : widget.onesolution.name;

  String get activeDescription => selectedChild != null
      ? (selectedChild!['description'] ?? selectedChild!['Description'] ?? '')
      : widget.onesolution.description;

  double get activePrice => selectedChild != null
      ? (selectedChild!['__price'] ?? 0.0)
      : _toDouble(widget.onesolution.price);

  double get activeOfferPrice => selectedChild != null
      ? (selectedChild!['__offerPrice'] ?? 0.0)
      : _toDouble(widget.onesolution.offerPrice);

  List<String> get activeImages {
    if (selectedChild != null &&
        selectedChild!['__images'] != null &&
        (selectedChild!['__images'] as List).isNotEmpty) {
      return List<String>.from(selectedChild!['__images']);
    }

    if (widget.onesolution.images.isNotEmpty) {
      return List<String>.from(widget.onesolution.images);
    }

    if (widget.onesolution.firstImage.isNotEmpty) {
      return [widget.onesolution.firstImage];
    }

    return [];
  }

  String? get activeVideoUrl {
    String? url;

    if (selectedChild != null) {
      final u = (selectedChild!['__videoUrl'] as String?);
      if (u != null && u.trim().isNotEmpty) url = u.trim();
    }

    if (url == null || url.isEmpty) {
      final parentMap = _parentVariant;
      if (parentMap != null) {
        final u = (parentMap['__videoUrl'] as String?);
        if (u != null && u.trim().isNotEmpty) url = u.trim();
      }
    }

    return url;
  }

  bool get hasActiveVideo {
    final url = activeVideoUrl;
    if (url == null || url.trim().isEmpty) return false;
    final videoId = YoutubePlayer.convertUrlToId(url);
    return videoId != null && videoId.isNotEmpty;
  }

  int get discountPercent {
    if (activePrice <= 0) return 0;
    final diff = activePrice - activeOfferPrice;
    if (diff <= 0) return 0;
    return ((diff / activePrice) * 100).round();
  }

  // ---------------------------------------------------------
  // SPECS LOADING (per product)
  // ---------------------------------------------------------
  Future<void> _loadSpecsFor(int productId) async {
    setState(() => _isLoadingSpecs = true);
    try {
      final sections = await ProductService.getSpecSectionsWithFields();
      final values = await ProductService.getProductSpecs(productId);

      if (!mounted) return;
      setState(() {
        _specSections = sections;
        _specValues = values; // fieldId -> value
      });
    } catch (e) {
      print("❌ Spec load error: $e");
      if (!mounted) return;
      setState(() {
        _specSections = [];
        _specValues = {};
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSpecs = false);
      }
    }
  }

  // ---------------------------------------------------------
  // ⭐ RATINGS LOADING (per product)
  // ---------------------------------------------------------
  Future<void> _loadRatingsFor(int productId) async {
    setState(() => _isLoadingRating = true);
    try {
      final summary = await RatingService.fetchSummary(productId);
      final reviews = await RatingService.fetchReviews(productId);

      if (!mounted) return;

      final starCountsDynamic =
          (summary['starCounts'] as Map<int, int>? ?? {});

      setState(() {
        _averageRating = (summary['average'] as double?) ?? 0.0;
        _totalReviews = (summary['total'] as int?) ?? 0;
        _starCounts = {
          5: starCountsDynamic[5] ?? 0,
          4: starCountsDynamic[4] ?? 0,
          3: starCountsDynamic[3] ?? 0,
          2: starCountsDynamic[2] ?? 0,
          1: starCountsDynamic[1] ?? 0,
        };
        _reviews = reviews;
      });
    } catch (e) {
      print("❌ Rating load error: $e");
      if (!mounted) return;
      setState(() {
        _averageRating = 0.0;
        _totalReviews = 0;
        _starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        _reviews = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingRating = false);
      }
    }
  }

  // ---------------------------------------------------------
  // YOUTUBE CONTROLS
  // ---------------------------------------------------------
  void _playVideo() {
    final url = activeVideoUrl;
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video not available")),
      );
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null || videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid video URL")),
      );
      return;
    }

    if (_ytController == null) {
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    } else {
      _ytController!.load(videoId);
    }

    setState(() {
      _isVideoVisible = true;
      _isMiniPlayer = false;
    });
  }

  void _closeVideo() {
    _ytController?.pause();
    setState(() {
      _isVideoVisible = false;
      _isMiniPlayer = false;
    });
  }

  void _toggleMiniPlayer() {
    setState(() {
      _isMiniPlayer = !_isMiniPlayer;
    });
  }

  Widget _buildVideoCard(String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    final thumbUrl =
        videoId != null ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg' : null;

    return GestureDetector(
      onTap: _playVideo,
      child: Stack(
        children: [
          Positioned.fill(
            child: thumbUrl != null
                ? OnesolutionImage(
                    image: thumbUrl,
                    height: 300,
                    width: double.infinity,
                  )
                : Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, size: 60),
                    ),
                  ),
          ),
          Container(
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Product Video",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // CART
  // ---------------------------------------------------------
  Future<void> _addToCart() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please log in to add items"),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      final added = await CartService.addToCart(user.id, activeId, 1);
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$activeName added to cart"),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to add to cart"),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      print("❌ Cart add error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to add to cart"),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  // ---------------------------------------------------------
  // ⭐ RATING HELPERS + UI
  // ---------------------------------------------------------
  List<Widget> _buildStarIcons(double rating, {double size = 16}) {
    final stars = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      IconData icon;
      if (rating >= i) {
        icon = Icons.star;
      } else if (rating >= i - 0.5) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      stars.add(Icon(icon, color: Colors.amber, size: size));
    }
    return stars;
  }
  
Future<void> _openWriteReviewDialog() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Please log in to write a review"),
      backgroundColor: Colors.redAccent,
    ));
    return;
  }

  int tempRating = 0;
  String tempComment = '';

  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Write a review'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        starIndex <= tempRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          tempRating = starIndex;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Your review',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => tempComment = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tempRating == 0) return;

                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;

                  /// 🔥 REAL NAME from profiles table
                  final displayName = await _getUserDisplayName();

                  await RatingService.submitReview(
                    productId: activeId,
                    userId: user.id,
                    userName: displayName, // real profile name
                    rating: tempRating,
                    comment: tempComment.trim(),
                  );

                  await _loadRatingsFor(activeId);

                  if (mounted) Navigator.pop(dialogCtx);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}


Widget _buildRatingSection() {
  if (_isLoadingRating) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const SizedBox(height: 8),
      const Text(
        "Ratings & Reviews",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),

      // -------------------------------------
      // NO REVIEWS YET
      // -------------------------------------
      if (_totalReviews == 0) ...[
        const Text(
          "No ratings yet.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _openWriteReviewDialog,
          icon: const Icon(Icons.rate_review),
          label: const Text("Write a review"),
        ),
      ] else ...[
        // -------------------------------------
        // AVERAGE + STAR BARS
        // -------------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildStarIcons(_averageRating, size: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  "$_totalReviews ratings",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // STAR DISTRIBUTION BARS
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  final count = _starCounts[star] ?? 0;
                  final ratio =
                      _totalReviews == 0 ? 0.0 : count / _totalReviews;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            "$star★",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                _kAccentRed,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 28,
                          child: Text(
                            "$count",
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openWriteReviewDialog,
            icon: const Icon(Icons.rate_review),
            label: const Text("Write a review"),
          ),
        ),

        const SizedBox(height: 8),

        // -------------------------------------
        // REVIEW LIST (UP TO 5)
        // -------------------------------------
        Column(
          children: _reviews.take(5).map((r) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // USER + DATE ROW
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        child: Text(
                          (r.userName.isNotEmpty
                                  ? r.userName[0]
                                  : 'U')
                              .toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        "${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}",
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // STAR RATING
                  Row(
                    children:
                        _buildStarIcons(r.rating.toDouble(), size: 14),
                  ),

                  const SizedBox(height: 4),

                  // COMMENT
                  if (r.comment.isNotEmpty)
                    Text(
                      r.comment,
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ],
  );
}

  // ---------------------------------------------------------
  // TABS UI
  // ---------------------------------------------------------
  Widget _buildDetailsTab() {
    final images = activeImages;
    final hasVideo = hasActiveVideo;
    final totalMedia = images.length + (hasVideo ? 1 : 0);
    final pageController = PageController(initialPage: _currentImage);

    return Column(
      children: [
        // IMAGE + VIDEO CAROUSEL
        Hero(
          tag: widget.heroTag,
          child: SizedBox(
            height: 300,
            child: totalMedia == 0
                ? Center(
                    child: Container(
                      height: 200,
                      width: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  )
                : PageView.builder(
                    controller: pageController,
                    itemCount: totalMedia,
                    onPageChanged: (i) => setState(() => _currentImage = i),
                    itemBuilder: (_, i) {
                      if (hasVideo && i == 0) {
                        final url = activeVideoUrl!;
                        return Stack(
                          children: [
                            _buildVideoCard(url),
                            if (activeOfferPrice < activePrice)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "-$discountPercent%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }

                      final imgIndex = hasVideo ? i - 1 : i;
                      final img = images[imgIndex];
                      final url = img.startsWith("http")
                          ? img
                          : ApiService.baseUrl.replaceAll('/api', '') + img;

                      return Stack(
                        children: [
                          OnesolutionImage(
                            image: url,
                            height: 300,
                            width: double.infinity,
                          ),
                          if (activeOfferPrice < activePrice)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "-$discountPercent%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ),

        // DOTS
        if (totalMedia > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalMedia,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: _currentImage == i ? 10 : 6,
                height: _currentImage == i ? 10 : 6,
                decoration: BoxDecoration(
                  color: _currentImage == i
                      ? _kAccentRed
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

        // CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRICE ROW (with small fade animation on variant change)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Row(
                    key: ValueKey<int>(activeId),
                    children: [
                      Text(
                        "₹${activeOfferPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: _kAccentRed,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (activeOfferPrice < activePrice)
                        Text(
                          "₹${activePrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // VARIANTS
                if (_isLoadingVariants)
                  const Center(child: CircularProgressIndicator())
                else if (variantChildren.isNotEmpty) ...[
                  const Text(
                    "Variants",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: variantChildren.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final v = variantChildren[index];
                        final isSelected = selectedChild != null &&
                            selectedChild!['__id'] == v['__id'];

                        final List<String> vImages =
                            (v['__images'] ?? []).cast<String>();

                        final img =
                            vImages.isNotEmpty ? vImages.first : null;

                        final imageUrl = img != null
                            ? (img.startsWith("http")
                                ? img
                                : ApiService.baseUrl
                                        .replaceAll('/api', '') +
                                    img)
                            : null;

                        final price = (v['__offerPrice'] ?? 0.0) as double;
                        final rawPrice = (v['__price'] ?? 0.0) as double;

                        final fullName =
                            v['__name'] ?? v['name'] ?? v['Name'] ?? '';
                        final variantLabel =
                            _extractVariantLabel(fullName);

                        final vVideo = (v['__videoUrl'] as String?);
                        final hasVideo =
                            vVideo != null && vVideo.trim().isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            // 🔙 push previous selection into history
                            if (selectedChild?['__id'] != v['__id']) {
                              setState(() {
                                _variantHistory.add(selectedChild);
                                selectedChild = v;
                                _currentImage = 0;
                              });
                              _loadSpecsFor(activeId);
                              _loadRatingsFor(activeId);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            width: 170,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? _kAccentRed
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.red.shade50
                                  : Colors.white,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.10),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: imageUrl != null
                                            ? OnesolutionImage(
                                                image: imageUrl,
                                                width: 170,
                                                height: 80,
                                              )
                                            : Container(
                                                color: Colors
                                                    .grey.shade200,
                                                child: const Icon(
                                                    Icons.image),
                                              ),
                                      ),
                                      if (hasVideo)
                                        Positioned(
                                          right: 4,
                                          top: 4,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  variantLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "₹${price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    if (rawPrice > price)
                                      Text(
                                        "₹$rawPrice",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          decoration: TextDecoration
                                              .lineThrough,
                                        ),
                                      )
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // DESCRIPTION
                const Text(
                  "Description",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(activeDescription),

                const SizedBox(height: 16),

                // ⭐ RATINGS SECTION (Amazon-style)
                _buildRatingSection(),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsTab() {
    if (_isLoadingSpecs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_specSections.isEmpty) {
      return const Center(
        child: Text("No specifications configured for this product."),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      itemCount: _specSections.length,
      itemBuilder: (_, idx) {
        final sec = _specSections[idx];
        if (sec.fields.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sec.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: sec.fields.map((f) {
                    final value = _specValues[f.fieldId] ?? "-";
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              f.name,
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: Text(
                              value,
                              style: const TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // BUILD  +  BACK HANDLING
  // ---------------------------------------------------------
  Future<bool> _handleWillPop() async {
    // If user has switched variants, go back to previous variant/parent
    if (_variantHistory.isNotEmpty) {
      setState(() {
        selectedChild = _variantHistory.removeLast();
        _currentImage = 0;
      });
      _loadSpecsFor(activeId);
      _loadRatingsFor(activeId);
      return false; // don't pop route yet
    }
    // No history → allow normal back (pop to previous page)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                activeName,
                key: ValueKey<int>(activeId),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            foregroundColor: Colors.black,
            bottom: const TabBar(
              labelColor: _kAccentRed,
              unselectedLabelColor: Colors.black54,
              indicatorColor: _kAccentRed,
              tabs: [
                Tab(text: "Details"),
                Tab(text: "Specifications"),
              ],
            ),
          ),
          body: Stack(
            children: [
              TabBarView(
                children: [
                  _buildDetailsTab(),
                  _buildSpecsTab(),
                ],
              ),
              if (_isVideoVisible && _ytController != null)
                Positioned(
                  right: 16,
                  bottom: _isMiniPlayer ? 16 : null,
                  left: _isMiniPlayer ? null : 16,
                  top: _isMiniPlayer
                      ? null
                      : MediaQuery.of(context).padding.top +
                          kToolbarHeight +
                          16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: _isMiniPlayer
                          ? 180
                          : MediaQuery.of(context).size.width - 32,
                      height: _isMiniPlayer ? 100 : 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            YoutubePlayer(
                              controller: _ytController!,
                              showVideoProgressIndicator: true,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isMiniPlayer
                                          ? Icons.fullscreen
                                          : Icons.picture_in_picture_alt,
                                    ),
                                    color: Colors.white,
                                    onPressed: _toggleMiniPlayer,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    color: Colors.white,
                                    onPressed: _closeVideo,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text(
                  "Add to Cart",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentRed,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =======================================================
/// ⭐ SIMPLE IN-MEMORY RATING SERVICE
/// (Works now, no extra files. Later you can replace with real API.)
/// =======================================================

class _ProductReview {
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  _ProductReview({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class RatingService {
  /// productId -> list of reviews
  static final Map<int, List<_ProductReview>> _reviewStore = {};

  static Future<Map<String, dynamic>> fetchSummary(int productId) async {
    // simulate small delay
    await Future.delayed(const Duration(milliseconds: 120));

    final list = _reviewStore[productId] ?? [];
    if (list.isEmpty) {
      return {
        'average': 0.0,
        'total': 0,
        'starCounts': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    double sum = 0;
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in list) {
      sum += r.rating;
      counts[r.rating] = (counts[r.rating] ?? 0) + 1;
    }

    final avg = sum / list.length;
    return {
      'average': double.parse(avg.toStringAsFixed(1)),
      'total': list.length,
      'starCounts': counts,
    };
  }

  static Future<List<_ProductReview>> fetchReviews(int productId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final list = List<_ProductReview>.from(_reviewStore[productId] ?? []);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<bool> submitReview({
    required int productId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    final review = _ProductReview(
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    final list = _reviewStore.putIfAbsent(productId, () => []);
    list.add(review);
    return true;
  }
}
