import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/models/movie.dart';
import '../../../shared/widgets/poster_image.dart';
import '../../../shared/widgets/sheet_search_field.dart';
import '../../detail/widgets/movie_detail_sheet.dart';
import '../providers/unwatched_provider.dart';

/// Sheet sizes as fractions of the screen height.
const double _collapsedSize = 0.5;
const double _expandedSize = 0.92;
const double _minSize = 0.3;

/// Opens the slide-up "Unwatched" bottom sheet.
Future<void> showUnwatchedSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _UnwatchedSheet(),
  );
}

class _UnwatchedSheet extends ConsumerStatefulWidget {
  const _UnwatchedSheet();

  @override
  ConsumerState<_UnwatchedSheet> createState() => _UnwatchedSheetState();
}

class _UnwatchedSheetState extends ConsumerState<_UnwatchedSheet> {
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
    final shouldExpand = _controller.size > (_collapsedSize + _expandedSize) / 2;
    if (shouldExpand != _expanded) {
      setState(() => _expanded = shouldExpand);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(unwatchedCountProvider);
    final movies = ref.watch(unwatchedProvider).valueOrNull ?? const [];
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
                      const Text('Unwatched', style: AppText.sectionTitle),
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
                    hint: 'Search unwatched…',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                Expanded(
                  child: count == 0
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 40, horizontal: 20),
                          child: Text(
                            "You haven't set aside any unwatched movies yet.\n"
                            'Swipe a card down to store it here for later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary, height: 1.5),
                          ),
                        )
                      : filtered.isEmpty
                          ? const SheetNoMatches()
                          : _UnwatchedGridView(
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

/// Scrollable poster grid of every unwatched movie. Tap opens detail,
/// long-press removes from the unwatched list.
class _UnwatchedGridView extends ConsumerWidget {
  const _UnwatchedGridView({
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
          onLongPress: () => _confirmRemove(context, ref, movie),
          child: Stack(
            children: [
              Positioned.fill(
                child: PosterImage(url: movie.posterUrl, borderRadius: 14),
              ),
              // Small "unwatched" badge in the corner.
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.unwatchedPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.visibility_off,
                      size: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, Movie movie) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Remove from unwatched?'),
        content: Text(
          '"${movie.title}" will be removed from your unwatched list.',
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
      await ref.read(unwatchedProvider.notifier).remove(movie.id);
    }
  }
}
