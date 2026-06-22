import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Tracks every movie the user has swiped away (watched or skipped), backed by
/// shared_preferences. The discovery deck consults this set so a dismissed
/// movie never reappears in the queue.
class SeenNotifier extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() {
    return ref.read(seenRepositoryProvider).load();
  }

  /// The currently loaded set of seen ids (empty until loaded).
  Set<int> get ids => state.valueOrNull ?? const {};

  bool contains(int id) => ids.contains(id);

  /// Record a movie as seen so it is filtered out of future fetches.
  Future<void> markSeen(int id) async {
    final current = ids;
    if (current.contains(id)) return;
    final updated = {...current, id};
    state = AsyncData(updated);
    await ref.read(seenRepositoryProvider).save(updated);
  }

  /// Forget all seen movies (lets the deck start over from scratch).
  Future<void> reset() async {
    state = const AsyncData(<int>{});
    await ref.read(seenRepositoryProvider).save(const {});
  }
}

final seenMoviesProvider =
    AsyncNotifierProvider<SeenNotifier, Set<int>>(SeenNotifier.new);
