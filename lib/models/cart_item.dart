class CartItem {
  final int id; 
  final int productId;
  final String productName;

  final double price;           // MRP
  final double offerPrice;      // Selling price
  final String imageUrl;

  int quantity;
  final double finalAmount;     // User-paid price AFTER coupon + delivery share

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.offerPrice,
    required this.imageUrl,
    required this.quantity,
    required this.finalAmount,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0 : double.tryParse(v.toString()) ?? 0;

    int _i(dynamic v) =>
        v == null ? 0 : int.tryParse(v.toString()) ?? 0;

    // PICK IMAGE
    String? image = json['imageUrl'] ??
        json['image'] ??
        (json['images'] is List ? json['images'][0] : null);

    image ??= "https://via.placeholder.com/300";

    double price = _d(json['price']);
    double offerPrice = _d(json['offerPrice']);

    if (offerPrice <= 0 || offerPrice >= price) {
      offerPrice = price;
    }

    double parsedFinal = _d(json['finalAmount']);

    return CartItem(
      id: _i(json['id'] ?? json['cartId']),
      productId: _i(json['productId']),
      productName: json['name'] ?? json['productName'] ?? "Product",
      price: price,
      offerPrice: offerPrice,
      imageUrl: image,
      quantity: _i(json['quantity']),
      finalAmount: parsedFinal > 0
          ? parsedFinal
          : offerPrice * _i(json['quantity']), // fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "productId": productId,
      "productName": productName,
      "price": price,
      "offerPrice": offerPrice,
      "imageUrl": imageUrl,
      "quantity": quantity,
      "finalAmount": finalAmount,
    };
  }
}
