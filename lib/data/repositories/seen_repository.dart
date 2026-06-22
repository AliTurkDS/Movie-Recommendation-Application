import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of "seen" movie ids (swiped — watched or skipped) so they
/// never resurface in the discovery deck, even across genre switches, refreshes
/// or app restarts.
class SeenRepository {
  static const _key = 'cineswipe_seen_v1';

  Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return {};
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> save(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((e) => e.toString()).toList());
  }
}
