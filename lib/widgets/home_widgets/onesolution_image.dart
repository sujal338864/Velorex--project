import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OnesolutionImage extends StatelessWidget {
  final String image;
  final double height;
  final double? width;
  final String? placeholder;

  const OnesolutionImage({
    Key? key,
    required this.image,
    required this.height,
    this.width,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ If image URL is empty or invalid, show placeholder immediately
    if (image.isEmpty || !image.startsWith('http')) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: image,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 600, // ✅ Optimize memory for large images
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) {
        debugPrint("❌ Failed to load image: $url -> $error");
        return _buildPlaceholder();
      },
    );
  }

  // ✅ Local placeholder (if image fails or missing)
  Widget _buildPlaceholder() {
    return Image.asset(
      placeholder ?? 'assets/images/placeholder.png',
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class OnesolutionImage extends StatelessWidget {
//   final String image;
//   final double height;
//   final double? width;
//   final String? placeholder;

//   const OnesolutionImage({
//     Key? key,
//     required this.image,
//     required this.height,
//     this.width,
//     this.placeholder,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     debugPrint("📸 Loading image: $image"); // log each image

//     return CachedNetworkImage(
//       imageUrl: image,
//       height: height,
//       width: width ?? double.infinity,
//       fit: BoxFit.cover,
//       placeholder: (context, url) =>
//           const Center(child: CircularProgressIndicator(strokeWidth: 2)),
//       errorWidget: (context, url, error) {
//         debugPrint("❌ Failed to load: $url");
//         return Image.asset(
//           placeholder ?? 'assets/images/placeholder.png',
//           height: height,
//           width: width ?? double.infinity,
//           fit: BoxFit.cover,
//         );
//       },
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:velocity_x/velocity_x.dart';

// class OnesolutionImage extends StatelessWidget {
//   final String image;
//   final double height;
//   final double width;

//   const OnesolutionImage({
//     Key? key,
//     required this.image,
//     this.height = 100,
//     this.width = 100,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final imageUrl = image.isNotEmpty ? image : 'https://via.placeholder.com/150';

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12), // Rounded corners ✅
//       child: Image.network(
//         imageUrl,
//         height: height,
//         width: width,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
//       ),
//     )
//         .box
//         .p8
//         .color(context.canvasColor)
//         .make()
//         .p8(); // a little outer padding
//   }
// }

