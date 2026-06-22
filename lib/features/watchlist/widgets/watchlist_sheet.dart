import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/models/movie.dart';
import '../../../shared/widgets/poster_image.dart';
import '../../../shared/widgets/sheet_search_field.dart';
import '../../detail/widgets/movie_detail_sheet.dart';
import '../../watched/providers/watched_provider.dart';
import '../providers/watchlist_provider.dart';

/// Sheet sizes as fractions of the screen height.
const double _collapsedSize = 0.5;
const double _expandedSize = 0.92;
const double _minSize = 0.3;

/// Opens the slide-up "My Watchlist" bottom sheet.
Future<void> showWatchlistSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WatchlistSheet(),
  );
}

class _WatchlistSheet extends ConsumerStatefulWidget {
  const _WatchlistSheet();

  @override
  ConsumerState<_WatchlistSheet> createState() => _WatchlistSheetState();
}

class _WatchlistSheetState extends ConsumerState<_WatchlistSheet> {
  final _controller = DraggableScrollableController();
  bool _expanded = false;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final target = _expanded ? _collapsedSize : _expandedSize;
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _onSizeChanged() {
    // Keep the arrow direction in sync when the user drags the sheet.
    final shouldExpand = _controller.size > (_collapsedSize + _expandedSize) / 2;
    if (shouldExpand != _expanded) {
      setState(() => _expanded = shouldExpand);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(watchlistCountProvider);
    final movies = ref.watch(watchlistProvider).valueOrNull ?? const [];
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? movies
        : movies.where((m) => m.title.toLowerCase().contains(query)).toList();

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: _collapsedSize,
      minChildSize: _minSize,
      maxChildSize: _expandedSize,
      expand: false,
      builder: (context, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (_) {
            _onSizeChanged();
            return false;
          },
          child: Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Drag handle.
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('My Watchlist', style: AppText.sectionTitle),
                      const SizedBox(width: 8),
                      if (count > 0)
                        Text('$count',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 15)),
                      const Spacer(),
                      IconButton(
                        tooltip: _expanded ? 'Collapse' : 'Expand',
                        onPressed: _toggle,
                        icon: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (count > 0)
                  SheetSearchField(
                    hint: 'Search your watchlist…',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                Expanded(
                  child: count == 0
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 40, horizontal: 20),
                          child: Text(
                            'Your watchlist is empty.\n'
                            'Swipe right on a movie to save it.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary, height: 1.5),
                          ),
                        )
                      : filtered.isEmpty
                          ? const SheetNoMatches()
                          : _WatchlistGridView(
                              movies: filtered,
                              scrollController: scrollController,
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Scrollable poster grid of every saved movie. Tap opens detail,
/// long-press removes.
class _WatchlistGridView extends ConsumerWidget {
  const _WatchlistGridView({
    required this.movies,
    required this.scrollController,
  });

  final List<Movie> movies;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: movies.length,
      itemBuilder: (context, i) {
        final movie = movies[i];
        return GestureDetector(
          onTap: () => showMovieDetailSheet(context, ref, movie),
          onLongPress: () => _showActions(context, ref, movie),
          child: PosterImage(url: movie.posterUrl, borderRadius: 14),
        );
      },
    );
  }

  /// Long-press menu: mark watched (moves it out of the watchlist) or remove.
  Future<void> _showActions(
      BuildContext context, WidgetRef ref, Movie movie) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                movie.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline,
                  color: AppColors.watchedBlue),
              title: const Text('Mark as Watched'),
              onTap: () => Navigator.pop(ctx, 'watched'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.accent),
              title: const Text('Remove from watchlist'),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'watched') {
      // Adds to watched and removes from the watchlist in one move.
      await ref.read(watchedProvider.notifier).add(movie);
    } else if (action == 'remove' && context.mounted) {
      await _confirmRemove(context, ref, movie);
    }
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
