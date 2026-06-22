import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/movie.dart';
import '../../discovery/providers/seen_provider.dart';
import '../../unwatched/providers/unwatched_provider.dart';
import '../../watchlist/providers/watchlist_provider.dart';

/// Holds the user's "watched" movies, backed by shared_preferences.
///
/// Marking a movie watched is a one-way move out of the watchlist: it is added
/// here, removed from the watchlist, and recorded as "seen" so it never
/// resurfaces in the discovery deck.
class WatchedNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() {
    return ref.read(watchedRepositoryProvider).load();
  }

  bool contains(int id) =>
      (state.valueOrNull ?? const []).any((m) => m.id == id);

  Future<void> add(Movie movie) async {
    // Keep the three lists mutually exclusive.
    await ref.read(watchlistProvider.notifier).remove(movie.id);
    await ref.read(unwatchedProvider.notifier).remove(movie.id);

    final current = state.valueOrNull ?? const <Movie>[];
    if (!current.any((m) => m.id == movie.id)) {
      final updated = [movie, ...current];
      state = AsyncData(updated);
      await ref.read(watchedRepositoryProvider).save(updated);
    }
    // Keep it out of the discovery deck.
    await ref.read(seenMoviesProvider.notifier).markSeen(movie.id);
  }

  Future<void> remove(int id) async {
    final current = state.valueOrNull ?? const <Movie>[];
    final updated = current.where((m) => m.id != id).toList();
    state = AsyncData(updated);
    await ref.read(watchedRepositoryProvider).save(updated);
  }

  Future<void> toggle(Movie movie) async {
    if (contains(movie.id)) {
      await remove(movie.id);
    } else {
      await add(movie);
    }
  }
}

final watchedProvider =
    AsyncNotifierProvider<WatchedNotifier, List<Movie>>(WatchedNotifier.new);

/// Convenience: the watched count for the top-bar pill.
final watchedCountProvider = Provider<int>((ref) {
  return ref.watch(watchedProvider).valueOrNull?.length ?? 0;
});
