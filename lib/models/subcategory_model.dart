class Subcategory {
  final int subcategoryId;
  final String name;
  final int categoryId;
  final String categoryName;
  final String? image;

  Subcategory({
    required this.subcategoryId,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.image,
  });

  factory Subcategory.fromMap(Map<String, dynamic> map) {
    return Subcategory(
      subcategoryId: map['subcategoryId'] ?? map['SubcategoryID'] ?? 0,
      name: map['name'] ?? map['Name'] ?? '',
      categoryId: map['categoryId'] ?? map['CategoryID'] ?? 0,
      categoryName: map['categoryName'] ?? map['CategoryName'] ?? '',
      image: map['image'] ?? '',
    );
  }
}
