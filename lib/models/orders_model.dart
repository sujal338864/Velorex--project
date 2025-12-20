// orders_model.dart





import 'package:Velorex/models/onesolution.dart';

class Order {
  final List<Items> items;
  final double totalAmount;
  final DateTime dateTime;

  Order({
    required this.items,
    required this.totalAmount,
    required this.dateTime,
  });
}

class OrdersModel {
  static final OrdersModel _singleton = OrdersModel._internal();

  factory OrdersModel() => _singleton;

  OrdersModel._internal();

  final List<Order> _orders = [];

  List<Order> get orders => _orders;

  void addOrder(List<Items> items, double totalAmount) {
    _orders.insert(
      0,
      Order(
        items: List<Items>.from(items),
        totalAmount: totalAmount,
        dateTime: DateTime.now(),
      ),
    );
  }

  void removeOrder(Order order) {
    _orders.remove(order);
  }

  bool contains(Order order) => _orders.contains(order);

  double get totalRevenue =>
      _orders.fold(0.0, (total, current) => total + current.totalAmount);

  int get count => _orders.length;
}
