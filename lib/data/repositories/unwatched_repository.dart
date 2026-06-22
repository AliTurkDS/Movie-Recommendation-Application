import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

/// Persists the "unwatched" list as a JSON list of movies in
/// shared_preferences.
///
/// Mirrors [WatchedRepository] / [WatchlistRepository] but under its own key:
/// films the user explicitly wants to keep aside as not-yet-watched.
class UnwatchedRepository {
  static const _key = 'cineswipe_unwatched_v1';

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
