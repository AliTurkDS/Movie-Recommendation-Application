import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

/// Persists the "watched" list as a JSON list of movies in shared_preferences.
///
/// Mirrors [WatchlistRepository] but under a separate key, so the two lists
/// (want-to-watch vs already-watched) are kept independently.
class WatchedRepository {
  static const _key = 'cineswipe_watched_v1';

  Future<List<Movie>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(movies.map((m) => m.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
