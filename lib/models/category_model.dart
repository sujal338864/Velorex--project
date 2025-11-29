class Category {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

factory Category.fromJson(Map<String, dynamic> json) {
  return Category(
    id: json['id'] ?? json['CategoryID'] ?? 0,
    name: json['name'] ?? json['Name'] ?? '',
    description: json['description'] ?? json['Description'],
    imageUrl: json['imageUrl'] ?? json['ImageUrl'] ?? '',
  );
}

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
      };
}
