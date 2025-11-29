class Poster {
  final int id;
  final String title;
  final String imageUrl;
  final DateTime createdAt;

  Poster({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Poster.fromMap(Map<String, dynamic> map) {
    return Poster(
      id: map['id'],
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // ✅ Add this getter here
String get posterImageUrl {
  if (imageUrl.startsWith('http')) return imageUrl;
  return "https://zyryndjeojrzvoubsqsg.supabase.co/storage/v1/object/public/posters/$imageUrl?width=600&quality=80";
}

}
