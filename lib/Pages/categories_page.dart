// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:one_solution/models/category_model.dart';
import 'package:one_solution/services/category_service.dart';
import 'package:one_solution/Pages/subcategory_page.dart';

class CategoryPage extends StatefulWidget {
  final String userId;

  const CategoryPage({super.key, required this.userId});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    setState(() => isLoading = true);
    final service = CategoryService();
    categories = await service.getCategories();
    setState(() => isLoading = false);
  }

  void openSubcategoryPage(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubcategoryPage(
          category: category,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Shop by Category",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.redAccent),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : RefreshIndicator(
              color: Colors.redAccent,
              onRefresh: loadCategories,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return InkWell(
                    onTap: () => openSubcategoryPage(cat),
                    borderRadius: BorderRadius.circular(15),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: Colors.redAccent.withOpacity(0.2),
                        ),
                      ),
                      elevation: 3,
                      shadowColor: Colors.redAccent.withOpacity(0.15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ✅ Category Image
                          if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                cat.imageUrl ??
                                    'https://via.placeholder.com/150', // ✅ safe fallback
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 80,
                                    width: 80,
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      color: Colors.redAccent,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.redAccent,
                                    size: 40,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.category,
                                color: Colors.redAccent,
                                size: 40,
                              ),
                            ),

                          const SizedBox(height: 10),

                          // 🔹 Category Name
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // 🔹 “Explore now” text
                          Text(
                            "Explore now →",
                            style: TextStyle(
                              color: Colors.redAccent.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
