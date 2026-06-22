import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/services/sync_service.dart';
import '../../discovery/providers/seen_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../unwatched/providers/unwatched_provider.dart';
import '../../watched/providers/watched_provider.dart';
import '../../watchlist/providers/watchlist_provider.dart';

/// What the sync UI is currently doing.
enum SyncPhase { idle, backingUp, restoring, success, error }

/// Outcome of the one-time startup sign-in.
enum SignInResult { restored, freshStart, error }

class SyncStatus {
  const SyncStatus(this.phase, [this.message]);

  final SyncPhase phase;
  final String? message;

  bool get busy =>
      phase == SyncPhase.backingUp || phase == SyncPhase.restoring;

  static const idle = SyncStatus(SyncPhase.idle);
}

/// Holds the remembered credentials and drives backup/restore.
class AccountNotifier extends AsyncNotifier<AccountCredentials?> {
  @override
  Future<AccountCredentials?> build() {
    return ref.read(accountRepositoryProvider).load();
  }

  /// Remembers credentials locally (does not touch the cloud).
  Future<void> remember(AccountCredentials creds) async {
    await ref.read(accountRepositoryProvider).save(creds);
    state = AsyncData(creds);
  }

  /// Clears the locally-remembered credentials.
  Future<void> forget() async {
    await ref.read(accountRepositoryProvider).clear();
    state = const AsyncData(null);
  }
}

final accountProvider =
    AsyncNotifierProvider<AccountNotifier, AccountCredentials?>(
        AccountNotifier.new);

/// Transient status of the most recent backup/restore action.
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;

  /// Bundles local data and uploads it under the key for [creds].
  Future<void> backup(AccountCredentials creds) async {
    if (state.busy) return;
    state = const SyncStatus(SyncPhase.backingUp);
    try {
      await ref.read(accountProvider.notifier).remember(creds);
      final bundle = await ref.read(syncRepositoryProvider).buildBundle();
      final key = SyncService.keyFor(creds.email, creds.password);
      await ref.read(syncServiceProvider).upload(key, bundle);
      state = const SyncStatus(SyncPhase.success, 'Backup saved to the cloud.');
    } catch (e) {
      state = SyncStatus(SyncPhase.error, _friendly(e));
    }
  }

  /// Downloads the backup for [creds] and overwrites local data with it.
  /// Returns true if a backup was found and applied.
  Future<bool> restore(AccountCredentials creds) async {
    if (state.busy) return false;
    state = const SyncStatus(SyncPhase.restoring);
    try {
      final key = SyncService.keyFor(creds.email, creds.password);
      final bundle = await ref.read(syncServiceProvider).download(key);
      if (bundle == null) {
        state = const SyncStatus(
            SyncPhase.error, 'No backup found for that email and password.');
        return false;
      }
      await ref.read(syncRepositoryProvider).applyBundle(bundle);
      await ref.read(accountProvider.notifier).remember(creds);
      _refreshAll();
      state = const SyncStatus(SyncPhase.success, 'Your data has been restored.');
      return true;
    } catch (e) {
      state = SyncStatus(SyncPhase.error, _friendly(e));
      return false;
    }
  }

  /// One-time startup sign-in: remember [creds] for future backups and, if a
  /// cloud backup already exists for them, restore it quietly. Unlike [restore]
  /// this never surfaces a "no backup found" error — a first-time user simply
  /// starts fresh.
  Future<SignInResult> signIn(AccountCredentials creds) async {
    try {
      final key = SyncService.keyFor(creds.email, creds.password);
      final bundle = await ref.read(syncServiceProvider).download(key);
      if (bundle != null) {
        await ref.read(syncRepositoryProvider).applyBundle(bundle);
      }
      await ref.read(accountProvider.notifier).remember(creds);
      if (bundle != null) {
        _refreshAll();
        return SignInResult.restored;
      }
      return SignInResult.freshStart;
    } catch (_) {
      // Still remember the credentials so backup works once back online.
      await ref.read(accountProvider.notifier).remember(creds);
      return SignInResult.error;
    }
  }

  void reset() => state = SyncStatus.idle;

  /// Reload every list-backed notifier from the freshly-written local storage.
  void _refreshAll() {
    ref.invalidate(watchlistProvider);
    ref.invalidate(watchedProvider);
    ref.invalidate(unwatchedProvider);
    ref.invalidate(seenMoviesProvider);
    ref.invalidate(onboardingSeenProvider);
  }

  String _friendly(Object e) =>
      'Something went wrong. Check your connection and try again.';
}
