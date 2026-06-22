import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/movie.dart';
import '../../discovery/providers/seen_provider.dart';
import '../../watched/providers/watched_provider.dart';
import '../../watchlist/providers/watchlist_provider.dart';

/// Holds the user's "unwatched" movies, backed by shared_preferences.
///
/// These are films the user wants to set aside as explicitly not-yet-watched.
/// Watchlist / Watched / Unwatched are mutually exclusive: adding here moves
/// the movie out of the other two lists and records it as "seen" so it never
/// resurfaces in the discovery deck.
class UnwatchedNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() {
    return ref.read(unwatchedRepositoryProvider).load();
  }

  bool contains(int id) =>
      (state.valueOrNull ?? const []).any((m) => m.id == id);

  Future<void> add(Movie movie) async {
    // Keep the three lists mutually exclusive.
    await ref.read(watchlistProvider.notifier).remove(movie.id);
    await ref.read(watchedProvider.notifier).remove(movie.id);

    final current = state.valueOrNull ?? const <Movie>[];
    if (!current.any((m) => m.id == movie.id)) {
      final updated = [movie, ...current];
      state = AsyncData(updated);
      await ref.read(unwatchedRepositoryProvider).save(updated);
    }
    // Keep it out of the discovery deck.
    await ref.read(seenMoviesProvider.notifier).markSeen(movie.id);
  }

  Future<void> remove(int id) async {
    final current = state.valueOrNull ?? const <Movie>[];
    final updated = current.where((m) => m.id != id).toList();
    state = AsyncData(updated);
    await ref.read(unwatchedRepositoryProvider).save(updated);
  }

  Future<void> toggle(Movie movie) async {
    if (contains(movie.id)) {
      await remove(movie.id);
    } else {
      await add(movie);
    }
  }
}

final unwatchedProvider =
    AsyncNotifierProvider<UnwatchedNotifier, List<Movie>>(
        UnwatchedNotifier.new);

/// Convenience: the unwatched count for the top-bar pill.
final unwatchedCountProvider = Provider<int>((ref) {
  return ref.watch(unwatchedProvider).valueOrNull?.length ?? 0;
});
