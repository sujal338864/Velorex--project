import 'package:one_solution/models/onesolution.dart';

class CartModel {
  static final CartModel _singleton = CartModel._internal();
  factory CartModel() => _singleton;
  CartModel._internal();

  late OnesolutionModel onesolution; // ✅ add this line back

  final List<_CartEntry> _items = [];
  List<_CartEntry> get items => _items;

  void add(Items item) {
    final index = _items.indexWhere((e) => e.item.id == item.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(_CartEntry(item: item));
    }
  }

  void remove(Items item) {
    final index = _items.indexWhere((e) => e.item.id == item.id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    }
  }

  void removeCompletely(Items item) => _items.removeWhere((e) => e.item.id == item.id);

  bool contains(Items item) => _items.any((e) => e.item.id == item.id);
  double get totalPrice => _items.fold(0, (t, e) => t + (e.item.price * e.quantity));
  int get totalItems => _items.fold(0, (t, e) => t + e.quantity);

  void clear() => _items.clear();
}

class _CartEntry {
  final Items item;
  int quantity;
  // ignore: unused_element_parameter
  _CartEntry({required this.item, this.quantity = 1});
}
