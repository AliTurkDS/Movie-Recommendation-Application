import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../../../core/providers.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/movie_detail.dart';
import '../../../shared/widgets/poster_image.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../../watched/providers/watched_provider.dart';
import '../../watchlist/providers/watchlist_provider.dart';

/// Opens [url] in an external app (browser / YouTube). No-op on failure.
Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Opens the movie detail bottom sheet for [movie].
Future<void> showMovieDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Movie movie, {
  Object? heroTag,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MovieDetailSheet(movie: movie, heroTag: heroTag),
  );
}

class _MovieDetailSheet extends ConsumerStatefulWidget {
  const _MovieDetailSheet({required this.movie, this.heroTag});
  final Movie movie;
  final Object? heroTag;

  @override
  ConsumerState<_MovieDetailSheet> createState() => _MovieDetailSheetState();
}

class _MovieDetailSheetState extends ConsumerState<_MovieDetailSheet> {
  late Future<MovieDetail?> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _loadDetail();
  }

  Future<MovieDetail?> _loadDetail() async {
    try {
      return await ref.read(movieRepositoryProvider).fetchDetail(widget.movie.id);
    } catch (_) {
      // Fall back to the list data we already have.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<MovieDetail?>(
            future: _detail,
            builder: (context, snap) {
              final detail = snap.data;
              final movie = detail != null
                  ? widget.movie.mergeDetail(detail.movie)
                  : widget.movie;
              final loading =
                  snap.connectionState == ConnectionState.waiting;
              return _content(scrollController, movie, detail, loading);
            },
          ),
        );
      },
    );
  }

  Widget _content(ScrollController controller, Movie movie,
      MovieDetail? detail, bool loading) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.genreTagBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Poster
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 320,
                    width: 220,
                    child: widget.heroTag != null
                        ? Hero(
                            tag: widget.heroTag!,
                            child: PosterImage(
                                url: movie.backdropUrl ?? movie.posterUrl),
                          )
                        : PosterImage(
                            url: movie.posterUrl ?? movie.backdropUrl),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(movie.title,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
              if ((movie.tagline ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  movie.tagline!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _MetaRow(movie: movie, loading: loading),
              const SizedBox(height: 16),
              if (movie.genreLabels(max: 6).isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in movie.genreLabels(max: 6)) _Chip(g),
                  ],
                ),
              const SizedBox(height: 20),
              const Text('Overview', style: AppText.sectionTitle),
              const SizedBox(height: 8),
              if (loading && movie.overview.isEmpty)
                const ShimmerBlock(height: 80, borderRadius: 8)
              else
                Text(
                  movie.overview.isEmpty
                      ? 'No overview available.'
                      : movie.overview,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.5, fontSize: 15),
                ),

              // ---- Cast ----
              if (detail != null && detail.cast.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Cast', style: AppText.sectionTitle),
                const SizedBox(height: 12),
                _CastRow(cast: detail.cast),
              ],

              // ---- Director / Writers / Language ----
              if (detail != null) ...[
                const SizedBox(height: 20),
                if (detail.director != null)
                  _Fact(label: 'Director', value: detail.director!),
                if (detail.writers.isNotEmpty)
                  _Fact(
                    label: detail.writers.length > 1 ? 'Writers' : 'Writer',
                    value: detail.writers.take(3).join(', '),
                  ),
                if (detail.originalLanguage.isNotEmpty)
                  _Fact(label: 'Language', value: detail.originalLanguage),
              ],

              // ---- Trailer ----
              if (detail?.trailerYoutubeKey != null) ...[
                const SizedBox(height: 20),
                _TrailerButton(youtubeKey: detail!.trailerYoutubeKey!),
              ],

              // ---- Where to watch ----
              if (detail != null &&
                  (detail.watchProviders.isNotEmpty ||
                      detail.watchLink != null)) ...[
                const SizedBox(height: 24),
                _WhereToWatch(
                  providers: detail.watchProviders,
                  link: detail.watchLink,
                ),
              ],

              const SizedBox(height: 28),
              _WatchlistButton(movie: movie),
              const SizedBox(height: 12),
              _WatchedButton(movie: movie),

              // ---- More like this ----
              if (detail != null && detail.recommendations.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('More like this', style: AppText.sectionTitle),
                const SizedBox(height: 12),
                _RecommendationsRow(
                  movies: detail.recommendations,
                  onTap: (m) => showMovieDetailSheet(context, ref, m),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.movie, required this.loading});
  final Movie movie;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[
      _meta(Icons.star, movie.rating, AppColors.accent),
      if (movie.year.isNotEmpty)
        _meta(Icons.calendar_today_outlined, movie.year, AppColors.textSecondary),
      if (movie.runtime != null)
        _meta(Icons.schedule, '${movie.runtime} min', AppColors.textSecondary)
      else if (loading)
        const ShimmerBlock(width: 60, height: 16),
    ];
    return Wrap(spacing: 18, runSpacing: 8, children: parts);
  }

  Widget _meta(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.genreTagBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.genreTagBorder),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _WatchlistButton extends ConsumerWidget {
  const _WatchlistButton({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(watchlistProvider); // rebuild on changes
    final inList = ref.read(watchlistProvider.notifier).contains(movie.id);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          final notifier = ref.read(watchlistProvider.notifier);
          if (inList) {
            notifier.remove(movie.id);
          } else {
            // add() enforces watchlist/watched mutual exclusivity.
            notifier.add(movie);
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: inList ? AppColors.surface : AppColors.saveGreen,
          side: inList
              ? const BorderSide(color: AppColors.saveGreen, width: 1.5)
              : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(inList ? Icons.check : Icons.favorite,
            color: inList ? AppColors.saveGreen : Colors.white, size: 20),
        label: Text(
          inList ? 'In Watchlist' : 'Add to Watchlist',
          style: TextStyle(
            color: inList ? AppColors.saveGreen : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _WatchedButton extends ConsumerWidget {
  const _WatchedButton({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(watchedProvider); // rebuild on changes
    final watched = ref.read(watchedProvider.notifier).contains(movie.id);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(watchedProvider.notifier).toggle(movie),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              watched ? AppColors.watchedBlue : Colors.transparent,
          side: const BorderSide(color: AppColors.watchedBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(
          watched ? Icons.check_circle : Icons.check_circle_outline,
          color: watched ? Colors.white : AppColors.watchedBlue,
          size: 20,
        ),
        label: Text(
          watched ? 'Watched' : 'Mark as Watched',
          style: TextStyle(
            color: watched ? Colors.white : AppColors.watchedBlue,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Horizontal scroll of top-billed cast: circular photo, name, character.
class _CastRow extends StatelessWidget {
  const _CastRow({required this.cast});
  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final member = cast[i];
          return SizedBox(
            width: 74,
            child: Column(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: PosterImage(url: member.profileUrl),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, height: 1.15),
                ),
                if (member.character.isNotEmpty)
                  Text(
                    member.character,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A "Label   Value" credit line (Director / Writers / Language).
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// "Watch Trailer" button that opens the YouTube video.
class _TrailerButton extends StatelessWidget {
  const _TrailerButton({required this.youtubeKey});
  final String youtubeKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () =>
            _launchUrl('https://www.youtube.com/watch?v=$youtubeKey'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.textSecondary, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.play_circle_outline,
            color: AppColors.textPrimary, size: 22),
        label: const Text('Watch Trailer',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
      ),
    );
  }
}

/// Streaming-provider logos for the region, opening the TMDB watch page.
class _WhereToWatch extends StatelessWidget {
  const _WhereToWatch({required this.providers, required this.link});
  final List<WatchProvider> providers;
  final String? link;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Where to watch', style: AppText.sectionTitle),
        const SizedBox(height: 12),
        if (providers.isEmpty)
          TextButton(
            onPressed: link == null ? null : () => _launchUrl(link!),
            child: const Text('Find where to watch',
                style: TextStyle(color: AppColors.accent)),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in providers)
                GestureDetector(
                  onTap: link == null ? null : () => _launchUrl(link!),
                  child: Tooltip(
                    message: p.name,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 46,
                        height: 46,
                        color: Colors.white,
                        child: PosterImage(url: p.logoUrl),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Horizontal poster row of recommended movies; tapping opens its detail.
class _RecommendationsRow extends StatelessWidget {
  const _RecommendationsRow({required this.movies, required this.onTap});
  final List<Movie> movies;
  final void Function(Movie) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final movie = movies[i];
          return GestureDetector(
            onTap: () => onTap(movie),
            child: SizedBox(
              width: 112,
              child: PosterImage(url: movie.posterUrl, borderRadius: 12),
            ),
          );
        },
      ),
    );
  }
}
