// // variant_models.dart
// import 'dart:io';
// import 'dart:typed_data';

// class VariantCombo {
//   Map<String, String> selections;
//   double price;
//   double offerPrice;
//   int stock;
//   String? sku;
//   String description;
//   bool useParentImages;

//   File? imageFile;
//   Uint8List? imageBytes;
//   List<dynamic>? extraImages; // for multi-images (if needed)

//   String? imageUrl; // from server when editing
//   String? videoUrl; // 🔴 NEW: per-variant YouTube URL

//   VariantCombo({
//     required this.selections,
//     this.price = 0,
//     this.offerPrice = 0,
//     this.stock = 0,
//     this.sku,
//     this.description = '',
//     this.useParentImages = true,
//     this.imageFile,
//     this.imageBytes,
//     this.extraImages,
//     this.imageUrl,
//     this.videoUrl,
//   });

//   /// Generate deterministic key from selections
//   String comboKey() {
//     final entries = selections.entries.toList()
//       ..sort((a, b) => a.key.compareTo(b.key));
//     final raw = entries.map((e) => '${e.key}:${e.value}').join('|');
//     return raw
//         .replaceAll(RegExp(r'[^a-zA-Z0-9\-_.]'), '_')
//         .replaceAll(RegExp(r'_+'), '_')
//         .replaceAll(RegExp(r'^_+|_+$'), '');
//   }
// }
