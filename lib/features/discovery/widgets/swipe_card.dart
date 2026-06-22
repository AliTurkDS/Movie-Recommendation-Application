import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../data/models/movie.dart';
import '../../../shared/widgets/poster_image.dart';

/// The visual content of a single movie card: full-bleed poster, bottom
/// gradient, and overlaid info. The swipe-direction guide is drawn by
/// CardStack as a separate (screen-clamped) layer.
class SwipeCard extends StatelessWidget {
  const SwipeCard({
    super.key,
    required this.movie,
    this.heroTag,
  });

  final Movie movie;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final genres = movie.genreLabels();

    Widget poster = PosterImage(url: movie.posterUrl, fit: BoxFit.cover);
    if (heroTag != null) {
      poster = Hero(tag: heroTag!, child: poster);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Poster
          poster,

          // Bottom gradient (covers lower ~45%)
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xCC0A0A0A),
                      Color(0xF20A0A0A),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Info overlay
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified,
                        color: AppColors.saveGreen, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${movie.matchPercent}% Match',
                      style: const TextStyle(
                        color: AppColors.saveGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  movie.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (movie.year.isNotEmpty) ...[
                      Text(movie.year,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                      const Text('  •  ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                    const Icon(Icons.star,
                        color: AppColors.textSecondary, size: 15),
                    const SizedBox(width: 4),
                    Text(movie.rating,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
                if (genres.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final g in genres) _GenreTag(g)],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreTag extends StatelessWidget {
  const _GenreTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.genreTagBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.genreTagBorder, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
