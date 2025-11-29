// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:one_solution/Pages/home_detail_full_page.dart';
import 'package:one_solution/models/onesolution.dart';
import 'package:one_solution/services/produc_services.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Items> _allProducts = [];
  List<Items> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ProductService.getProducts();
      setState(() {
        _allProducts = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ---------------- FILTER -----------------
  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _allProducts);
    } else {
      setState(() {
        _filtered = _allProducts.where((item) {
          return item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  // ----------- STOCK LABEL TEXT ------------
  String _getStockLabel(Items p) {
    if (p.stock == null) return "";
    final s = p.stock ?? 0;

    if (s == 0) return "Out of Stock";
    if (s <= 10) return "$s left";
    return "In Stock";
  }

  // ----------- STOCK LABEL COLOR -----------
  Color _getStockColor(Items p) {
    final s = p.stock ?? 0;

    if (s == 0) return Colors.redAccent;
    if (s <= 10) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            // SEARCH INPUT
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
              ),
            ),

            // CLOSE BUTTON
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SUGGESTED KEYWORDS
                if (_controller.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _filtered.take(5).map((p) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              backgroundColor: Colors.redAccent.shade100,
                              label: Text(p.name),
                              onPressed: () {
                                _controller.text = p.name;
                                _filter(p.name);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // PRODUCT GRID
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text("No matching products"),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final p = _filtered[index];

                            final img = p.images.isNotEmpty
                                ? p.images.first
                                : "https://via.placeholder.com/150";

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HomeDetailFullPage(
                                      onesolution: p,
                                      heroTag: 'search_${p.id}',
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
                                      color: Colors.black12.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // IMAGE
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                        child: Image.network(
                                          img,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.image_not_supported,
                                                  size: 50, color: Colors.grey),
                                        ),
                                      ),
                                    ),

                                    // DETAILS
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "₹${p.offerPrice.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // STOCK STATUS (NEW)
                                          Text(
                                            _getStockLabel(p),
                                            style: TextStyle(
                                              color: _getStockColor(p),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
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
              ],
            ),
    );
  }
}


// ProductService
// import 'package:flutter/material.dart';
// import 'package:one_solution/models/onesolution.dart';
// import 'package:one_solution/Pages/home_detai_page.dart';
// import 'package:one_solution/services/api_service.dart';

// class SearchPage extends StatefulWidget {
//   const SearchPage({super.key});

//   @override
//   State<SearchPage> createState() => _SearchPageState();
// }

// class _SearchPageState extends State<SearchPage> {
//   final TextEditingController _controller = TextEditingController();
//   List<Items> _allProducts = [];
//   List<Items> _filtered = [];
//   List<String> _suggestions = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }

//   Future<void> _loadProducts() async {
//     final products = await ApiService.getProducts();
//     setState(() {
//       _allProducts = products;
//       _filtered = products;
//     });
//   }

//   void _onSearchChanged(String query) {
//     if (query.isEmpty) {
//       setState(() {
//         _filtered = _allProducts;
//         _suggestions.clear();
//       });
//       return;
//     }

//     final q = query.toLowerCase();

//     // 🔹 Suggestions for dropdown
//     _suggestions = _allProducts
//         .where((item) => item.name.toLowerCase().contains(q))
//         .map((e) => e.name)
//         .take(6)
//         .toList();

//     // 🔹 Filtered results
//     _filtered = _allProducts
//         .where((item) =>
//             item.name.toLowerCase().contains(q) ||
//             item.description.toLowerCase().contains(q))
//         .toList();

//     setState(() {});
//   }

//   void _selectSuggestion(String suggestion) {
//     _controller.text = suggestion;
//     _onSearchChanged(suggestion);
//     FocusScope.of(context).unfocus();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.redAccent,
//         title: TextField(
//           controller: _controller,
//           style: const TextStyle(color: Colors.white),
//           decoration: const InputDecoration(
//             hintText: "Search products...",
//             hintStyle: TextStyle(color: Colors.white70),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.white),
//           ),
//           onChanged: _onSearchChanged,
//           cursorColor: Colors.white,
//         ),
//       ),
//       body: Stack(
//         children: [
//           // 🔹 Search Results
//           ListView.builder(
//             itemCount: _filtered.length,
//             itemBuilder: (context, i) {
//               final p = _filtered[i];
//               return ListTile(
//                 leading: p.firstImage != null
//                     ? Image.network(p.firstImage!, width: 60, fit: BoxFit.cover)
//                     : const Icon(Icons.image),
//                 title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
//                 subtitle: Text("₹${p.offerPrice}", style: const TextStyle(color: Colors.redAccent)),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => HomeDetailPage(
//                         onesolution: p,
//                         heroTag: 'search-${p.id}',
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),

//           // 🔹 Suggestion overlay (appears when typing)
//           if (_suggestions.isNotEmpty)
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: Material(
//                 elevation: 4,
//                 color: Colors.white,
//                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
//                 child: ListView.builder(
//                   padding: EdgeInsets.zero,
//                   shrinkWrap: true,
//                   itemCount: _suggestions.length,
//                   itemBuilder: (context, i) {
//                     return ListTile(
//                       leading: const Icon(Icons.history, color: Colors.grey),
//                       title: Text(_suggestions[i]),
//                       onTap: () => _selectSuggestion(_suggestions[i]),
//                     );
//                   },
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
