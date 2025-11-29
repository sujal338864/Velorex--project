import 'package:supabase_flutter/supabase_flutter.dart';

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
  required String userName, // ignore incoming name
  required int rating,
  required String comment,
}) async {
  // Always fetch real name from profile
  final profileName = await fetchProfileName(userId);

  final review = _ProductReview(
    userId: userId,
    userName: profileName,
    rating: rating,
    comment: comment,
    createdAt: DateTime.now(),
  );

  final list = _reviewStore.putIfAbsent(productId, () => []);
  list.add(review);
  return true;
}

  static Future<String> fetchProfileName(String userId) async {
  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();

    if (data != null && data['full_name'] != null && data['full_name'].toString().trim().isNotEmpty) {
      return data['full_name'];
    }
  } catch (e) {
    print("❌ Error fetching profile name: $e");
  }

  return "Guest User"; // fallback
}

   }