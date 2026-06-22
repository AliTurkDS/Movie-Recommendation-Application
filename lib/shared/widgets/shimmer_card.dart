import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants.dart';

/// A shimmering placeholder shaped like a movie card, shown while loading.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.borderRadius = 24});

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBg,
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A small shimmering rectangle, used for poster thumbnails / generic blocks.
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBg,
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
