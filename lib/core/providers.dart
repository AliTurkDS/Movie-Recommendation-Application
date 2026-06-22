import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/account_repository.dart';
import '../data/repositories/login_prompt_repository.dart';
import '../data/repositories/movie_repository.dart';
import '../data/repositories/onboarding_repository.dart';
import '../data/repositories/seen_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/repositories/unwatched_repository.dart';
import '../data/repositories/watched_repository.dart';
import '../data/repositories/watchlist_repository.dart';
import '../data/services/sync_service.dart';
import '../data/services/tmdb_service.dart';

/// Shared singletons for the data layer.
final tmdbServiceProvider = Provider<TmdbService>((ref) => TmdbService());

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepository(ref.watch(tmdbServiceProvider)),
);

final watchlistRepositoryProvider =
    Provider<WatchlistRepository>((ref) => WatchlistRepository());

final seenRepositoryProvider =
    Provider<SeenRepository>((ref) => SeenRepository());

final watchedRepositoryProvider =
    Provider<WatchedRepository>((ref) => WatchedRepository());

final unwatchedRepositoryProvider =
    Provider<UnwatchedRepository>((ref) => UnwatchedRepository());

final onboardingRepositoryProvider =
    Provider<OnboardingRepository>((ref) => OnboardingRepository());

/// Cloud backup/restore wiring.
final accountRepositoryProvider =
    Provider<AccountRepository>((ref) => AccountRepository());

final loginPromptRepositoryProvider =
    Provider<LoginPromptRepository>((ref) => LoginPromptRepository());

final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(
    watchlist: ref.watch(watchlistRepositoryProvider),
    watched: ref.watch(watchedRepositoryProvider),
    unwatched: ref.watch(unwatchedRepositoryProvider),
    seen: ref.watch(seenRepositoryProvider),
    onboarding: ref.watch(onboardingRepositoryProvider),
  ),
);
