import '../../core/constants.dart';
import '../models/movie.dart';
import 'onboarding_repository.dart';
import 'seen_repository.dart';
import 'unwatched_repository.dart';
import 'watched_repository.dart';
import 'watchlist_repository.dart';

/// Bundles every locally-persisted list into a single JSON object for cloud
/// backup, and applies a downloaded bundle back onto local storage.
///
/// Restore is a *full overwrite*: the bundle becomes local state. The notifiers
/// that read these repositories should be invalidated afterwards so the UI
/// reloads from the freshly-written values.
class SyncRepository {
  SyncRepository({
    required WatchlistRepository watchlist,
    required WatchedRepository watched,
    required UnwatchedRepository unwatched,
    required SeenRepository seen,
    required OnboardingRepository onboarding,
  })  : _watchlist = watchlist,
        _watched = watched,
        _unwatched = unwatched,
        _seen = seen,
        _onboarding = onboarding;

  final WatchlistRepository _watchlist;
  final WatchedRepository _watched;
  final UnwatchedRepository _unwatched;
  final SeenRepository _seen;
  final OnboardingRepository _onboarding;

  /// Reads all local lists and assembles the backup payload.
  Future<Map<String, dynamic>> buildBundle() async {
    final watchlist = await _watchlist.load();
    final watched = await _watched.load();
    final unwatched = await _unwatched.load();
    final seen = await _seen.load();
    final onboarding = await _onboarding.hasSeen();

    return {
      'version': SyncConfig.bundleVersion,
      'watchlist': watchlist.map((m) => m.toJson()).toList(),
      'watched': watched.map((m) => m.toJson()).toList(),
      'unwatched': unwatched.map((m) => m.toJson()).toList(),
      'seen': seen.toList(),
      'onboarding': onboarding,
    };
  }

  /// Overwrites every local list from [bundle]. Missing fields are treated as
  /// empty so a partial/older bundle still applies cleanly.
  Future<void> applyBundle(Map<String, dynamic> bundle) async {
    await _watchlist.save(_movies(bundle['watchlist']));
    await _watched.save(_movies(bundle['watched']));
    await _unwatched.save(_movies(bundle['unwatched']));
    await _seen.save(_ids(bundle['seen']));
    if (bundle['onboarding'] == true) {
      await _onboarding.markSeen();
    }
  }

  List<Movie> _movies(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromJson)
        .toList();
  }

  Set<int> _ids(dynamic raw) {
    if (raw is! List) return <int>{};
    return raw
        .map((e) => e is int ? e : int.tryParse('$e'))
        .whereType<int>()
        .toSet();
  }
}
