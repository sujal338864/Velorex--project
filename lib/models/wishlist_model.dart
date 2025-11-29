import 'package:one_solution/models/onesolution.dart';

class WishlistModel {
  static final WishlistModel _singleton = WishlistModel._internal();
  factory WishlistModel() => _singleton;
  WishlistModel._internal();

  final List<Items> _items = [];

  List<Items> get items => List.unmodifiable(_items);

  void add(Items item) {
    if (!_items.any((e) => e.id == item.id)) {
      _items.add(item);
    }
  }

  void addAll(List<Items> list) {
    for (var item in list) {
      add(item);
    }
  }

  void remove(Items item) {
    _items.removeWhere((e) => e.id == item.id);
  }

  bool isInWishlist(Items item) {
    return _items.any((e) => e.id == item.id);
  }

  void clear() => _items.clear();
}
