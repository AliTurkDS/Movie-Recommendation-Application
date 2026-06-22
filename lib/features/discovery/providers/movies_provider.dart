import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/movie.dart';
import 'filter_provider.dart';
import 'search_provider.dart';
import 'seen_provider.dart';

/// Manages the swipeable deck of movies for the selected genre.
///
/// The deck is the AsyncValue's data: the front card is `state[0]`. When the
/// deck runs low we transparently fetch the next page and append, dedup'd by id.
class MoviesNotifier extends AsyncNotifier<List<Movie>> {
  int _page = 0;
  MovieFilter _filter = const MovieFilter();
  String _query = '';
  bool _fetchingMore = false;
  bool _exhausted = false;
  final Set<int> _seenIds = {};

  @override
  Future<List<Movie>> build() async {
    // Rebuild (and reset) whenever the filter or search query changes.
    _filter = ref.watch(movieFilterProvider);
    _query = ref.watch(searchQueryProvider).trim();
    _page = 0;
    _exhausted = false;
    _fetchingMore = false;
    _seenIds.clear();
    // Make sure the persisted "seen" set is loaded before the first fetch so
    // already watched/skipped movies are filtered out from the start. Read
    // (not watch) so marking a movie seen doesn't rebuild/reset the deck.
    await ref.read(seenMoviesProvider.future);
    return _fetchPage();
  }

  /// Fetch the next page for the current genre and return ONLY the new,
  /// deduplicated movies from that page (does not include the existing deck).
  Future<List<Movie>> _fetchPage() async {
    final repo = ref.read(movieRepositoryProvider);
    final next = _page + 1;
    final batch =
        await repo.fetchPage(filter: _filter, query: _query, page: next);
    _page = next;

    // While browsing, filter out movies already watched/skipped so they never
    // resurface. While searching, the user is explicitly looking a title up —
    // show it even if it was skipped or is already in a list.
    final searching = _query.isNotEmpty;
    final seen = searching
        ? const <int>{}
        : ref.read(seenMoviesProvider.notifier).ids;

    final fresh = <Movie>[];
    for (final m in batch) {
      if (m.posterPath == null) continue; // skip posterless cards
      if (seen.contains(m.id)) continue; // already watched/skipped
      if (_seenIds.add(m.id)) fresh.add(m);
    }
    // For search, surface the highest-rated matches first (TMDB returns search
    // results by text relevance). Ties break on popularity.
    if (searching) {
      fresh.sort((a, b) {
        final byRating = b.voteAverage.compareTo(a.voteAverage);
        return byRating != 0 ? byRating : b.popularity.compareTo(a.popularity);
      });
    }
    if (fresh.isEmpty) _exhausted = true;
    return fresh;
  }

  /// Remove the front card after a swipe, then top up the buffer if low.
  void removeTop() {
    final deck = state.valueOrNull;
    if (deck == null || deck.isEmpty) return;
    state = AsyncData(deck.sublist(1));
    _maybeFetchMore();
  }

  /// Fetch another page in the background when fewer than 3 cards remain.
  Future<void> _maybeFetchMore() async {
    if (_fetchingMore || _exhausted) return;
    final deck = state.valueOrNull ?? const [];
    if (deck.length >= 3) return;

    _fetchingMore = true;
    try {
      final fresh = await _fetchPage();
      final current = state.valueOrNull ?? const <Movie>[];
      state = AsyncData([...current, ...fresh]);
    } catch (_) {
      // Keep the existing deck; a later swipe will retry.
    } finally {
      _fetchingMore = false;
    }
  }

  /// True while a background top-up fetch is in flight.
  bool get isFetchingMore => _fetchingMore;

  /// True when the API has no more results for this genre.
  bool get isExhausted => _exhausted;

  /// Re-fetch from page 1 (used by the empty / error states' refresh button).
  Future<void> refresh() async {
    _page = 0;
    _exhausted = false;
    _seenIds.clear();
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchPage);
  }
}

final moviesProvider =
    AsyncNotifierProvider<MoviesNotifier, List<Movie>>(MoviesNotifier.new);
