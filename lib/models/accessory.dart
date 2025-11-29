
// / / class Items {
//   final int id;
//   final String name;
//   final String desc;
//   final num price;
//   final String image; // ✅ Add this
//   final String mobileno;

//   int quantity;

//   Items({
//     required this.id,
//     required this.name,
//     required this.desc,
//     required this.price,
//     required this.image, // ✅ Initialize
//     required this.mobileno,
//     this.quantity = 1,
//   });
// factory Items.fromMap(Map<String, dynamic> map) {
//   return Items(
//     id: map['id'],
//     name: map['name'],
//     desc: map['desc'],
//     price: map['price'],
//     image: map['image'] is String ? map['image'] : map['image']['url'],
//     mobileno: map['mobileno'],
//     quantity: map['quantity'] ?? 1,
//   );
// }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'desc': desc,
//       'price': price,
//       'image': image, // ✅ Include image
//       'mobileno': mobileno,
//       'quantity': quantity,
//     };
//   }
// }
