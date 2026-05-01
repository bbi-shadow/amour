import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../themes/app_theme.dart';

class CachedPhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final String? uid;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CachedPhotoWidget({
    super.key,
    this.photoUrl,
    this.uid,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppColors.primary.withOpacity(0.1),
        child: const Icon(Icons.person, color: AppColors.primary),
      );
    }

    return CachedNetworkImage(
      imageUrl: photoUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        color: AppColors.primary.withOpacity(0.05),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.primary.withOpacity(0.1),
        child: const Icon(Icons.error_outline, color: AppColors.primary),
      ),
    );
  }
}
