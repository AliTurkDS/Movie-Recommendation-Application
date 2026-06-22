import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/models/movie.dart';
import '../../../shared/widgets/poster_image.dart';
import '../../detail/widgets/movie_detail_sheet.dart';
import '../providers/watchlist_provider.dart';

/// Horizontal scrolling row of saved poster thumbnails, ending in a
/// dashed "+" placeholder.
class WatchlistGrid extends ConsumerWidget {
  const WatchlistGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(watchlistProvider).valueOrNull ?? const [];

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: movies.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          if (i == movies.length) return const _AddPlaceholder();
          final movie = movies[i];
          return _Thumb(
            movie: movie,
            onTap: () => showMovieDetailSheet(context, ref, movie),
            onLongPress: () => _confirmRemove(context, ref, movie),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, Movie movie) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Remove from watchlist?'),
        content: Text(
          '"${movie.title}" will be removed from your watchlist.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (remove == true) {
      await ref.read(watchlistProvider.notifier).remove(movie.id);
    }
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.movie,
    required this.onTap,
    required this.onLongPress,
  });

  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 120,
        child: PosterImage(url: movie.posterUrl, borderRadius: 14),
      ),
    );
  }
}

class _AddPlaceholder extends StatelessWidget {
  const _AddPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: const Center(
          child: Icon(Icons.add, color: AppColors.textSecondary, size: 32),
        ),
      ),
    );
  }
}

/// Paints a rounded dashed border for the "+" add card.
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.genreTagBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final path = Path()..addRRect(rrect);

    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(
          metric.extractPath(dist, next.clamp(0, metric.length)),
          paint,
        );
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
