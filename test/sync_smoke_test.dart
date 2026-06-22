// Live smoke test for the cloud sync flow against the deployed Vercel backend.
// Drives the real SyncService (same code the app runs): derive key ->
// upload -> download -> verify round-trip, plus the wrong-password case.
//
// Hits the network, so it is tagged 'live' and skipped by default. Run with:
//   flutter test test/sync_smoke_test.dart --tags live
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/services/sync_service.dart';

void main() {
  test('cloud sync round-trip against live backend', () async {
    final sync = SyncService();

    const email = 'sync-smoke@example.com';
    const password = 'correct-horse-battery-staple';
    final key = SyncService.keyFor(email, password);

    // Key must match the backend's /^[a-f0-9]{64}$/ validation.
    expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(key), isTrue,
        reason: 'derived key is a 64-char lowercase hex sha256');

    final bundle = <String, dynamic>{
      'schemaVersion': 1,
      'watchlist': [27205, 157336, 155],
      'seen': [550, 680],
      'updatedAt': '2026-06-20T00:00:00Z',
    };

    // [1] upload
    await sync.upload(key, bundle);

    // [2] download -> round-trip matches what we uploaded
    final restored = await sync.download(key);
    expect(restored, isNotNull);
    expect(restored!['schemaVersion'], 1);
    expect((restored['watchlist'] as List).length, 3);
    expect((restored['seen'] as List).length, 2);

    // [3] wrong password -> different key -> no backup found (null)
    final wrongKey = SyncService.keyFor(email, 'wrong-password');
    final none = await sync.download(wrongKey);
    expect(none, isNull, reason: 'wrong password must not resolve a backup');

    // ignore: avoid_print
    print('SYNC LIVE SMOKE: PASS — upload/download/restore + wrong-pw all OK');
  }, tags: 'live', timeout: const Timeout(Duration(seconds: 60)));
}
