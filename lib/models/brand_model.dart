class Brand {
  final int id;
  final String name;

  Brand({
    required this.id,
    required this.name,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['BrandID'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
    );
  }
}
