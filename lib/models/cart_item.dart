class CartItem {
  final int id; // Cart ID
  final int productId;
  final String productName;
  final double price; // ✅ Original MRP Price
  final double offerPrice; // ✅ Discounted price (if available)
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.offerPrice,
    required this.imageUrl,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    double _parseDouble(dynamic v, [double fallback = 0]) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    // ✅ Resolve Image URL
    String? imageUrl = (json['imageUrl'] ??
            json['ImageUrl'] ??
            json['image'] ??
            json['Image'])
        ?.toString();

    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      final imgs = json['images'] ?? json['imageUrls'];
      if (imgs is List && imgs.isNotEmpty) {
        imageUrl = imgs.first.toString();
      }
    }
    imageUrl ??= 'https://via.placeholder.com/300';

    // ✅ Parse prices clearly
    final double originalPrice =
        _parseDouble(json['price'] ?? json['Price'] ?? json['originalPrice']);
    final double offerPrice =
        _parseDouble(json['offerPrice'] ?? json['OfferPrice'] ?? 0);

    // ✅ Fallback logic
    final double finalOfferPrice =
        (offerPrice > 0 && offerPrice < originalPrice)
            ? offerPrice
            : originalPrice;

    return CartItem(
      id: _parseInt(json['id'] ?? json['cartId'] ?? json['CartID']),
      productId:
          _parseInt(json['productId'] ?? json['ProductID'] ?? json['product_id']),
      productName: (json['ProductName'] ??
              json['productName'] ??
              json['name'] ??
              'Unknown')
          .toString(),
      price: originalPrice,
      offerPrice: finalOfferPrice,
      imageUrl: imageUrl,
      quantity: _parseInt(json['quantity'] ?? json['Quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'offerPrice': offerPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}
