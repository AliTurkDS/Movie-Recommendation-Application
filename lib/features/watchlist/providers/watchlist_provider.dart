import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/movie.dart';
import '../../discovery/providers/seen_provider.dart';
import '../../unwatched/providers/unwatched_provider.dart';
import '../../watched/providers/watched_provider.dart';

/// Holds the user's watchlist, backed by shared_preferences.
class WatchlistNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() {
    return ref.read(watchlistRepositoryProvider).load();
  }

  bool contains(int id) =>
      (state.valueOrNull ?? const []).any((m) => m.id == id);

  Future<void> add(Movie movie) async {
    // Keep the three lists mutually exclusive.
    await ref.read(watchedProvider.notifier).remove(movie.id);
    await ref.read(unwatchedProvider.notifier).remove(movie.id);

    final current = state.valueOrNull ?? const <Movie>[];
    if (!current.any((m) => m.id == movie.id)) {
      final updated = [movie, ...current];
      state = AsyncData(updated);
      await ref.read(watchlistRepositoryProvider).save(updated);
    }
    // Keep it out of the discovery deck.
    await ref.read(seenMoviesProvider.notifier).markSeen(movie.id);
  }

  Future<void> remove(int id) async {
    final current = state.valueOrNull ?? const <Movie>[];
    final updated = current.where((m) => m.id != id).toList();
    state = AsyncData(updated);
    await ref.read(watchlistRepositoryProvider).save(updated);
  }

  Future<void> toggle(Movie movie) async {
    if (contains(movie.id)) {
      await remove(movie.id);
    } else {
      await add(movie);
    }
  }
}

final watchlistProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<Movie>>(
        WatchlistNotifier.new);

/// Convenience: the watchlist count for the app-bar badge.
final watchlistCountProvider = Provider<int>((ref) {
  return ref.watch(watchlistProvider).valueOrNull?.length ?? 0;
});
