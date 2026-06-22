import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'shimmer_card.dart';

/// A cached poster/backdrop image with a shimmer placeholder and an
/// emoji fallback when the url is missing or fails to load.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  final String? url;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final Widget child;
    if (url == null) {
      child = const _Fallback();
    } else {
      child = CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        placeholder: (_, _) => const ShimmerCard(borderRadius: 0),
        errorWidget: (_, _, _) => const _Fallback(),
      );
    }
    return ClipRRect(borderRadius: radius, child: child);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      alignment: Alignment.center,
      child: const Text('🎬', style: TextStyle(fontSize: 48)),
    );
  }
}
