import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide color palette for the cinematic dark theme.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF111111);
  static const cardBg = Color(0xFF1A1A1A);
  static const accent = Color(0xFFE24B4A); // red
  static const saveGreen = Color(0xFF22C55E); // green
  static const watchedBlue = Color(0xFF3B82F6); // blue (watched action)
  static const unwatchedPurple = Color(0xFFA855F7); // purple (unwatched action)
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9CA3AF);
  static const genreTagBg = Color(0xFF1F1F1F);
  static const genreTagBorder = Color(0xFF333333);
}

/// TMDB API configuration.
class ApiConfig {
  ApiConfig._();

  static const baseUrl = 'https://api.themoviedb.org/3';
  static const imageBaseW185 = 'https://image.tmdb.org/t/p/w185';
  static const imageBaseW500 = 'https://image.tmdb.org/t/p/w500';
  static const imageBaseOriginal = 'https://image.tmdb.org/t/p/original';

  /// Read from the bundled .env file at runtime via flutter_dotenv.
  static const apiKeyEnvName = 'TMDB_API_KEY';
}

/// Cloud backup/restore (the Vercel serverless function backed by Blob storage).
class SyncConfig {
  SyncConfig._();

  /// Name of the `.env` var holding the deployed Vercel function base URL.
  static const baseUrlEnvName = 'SYNC_BASE_URL';

  /// Base URL of the deployed Vercel function, e.g.
  /// 'https://your-app.vercel.app'. The `/api/data` endpoint is appended.
  ///
  /// Read from the bundled `.env` at runtime so the deployment URL isn't
  /// hardcoded in source control. Empty when unset — cloud sync is then
  /// effectively disabled and backup/restore surface a friendly error.
  static String get baseUrl => dotenv.maybeGet(baseUrlEnvName) ?? '';

  /// Current bundle schema version, written into every backup.
  static const bundleVersion = 1;
}

/// A selectable genre filter pill.
///
/// `id == null` with no [feed] means "All" (popular movies, no genre filter).
/// [feed] overrides routing to a named TMDB list (e.g. 'top_rated').
class Genre {
  const Genre(this.label, this.id, {this.feed});

  final String label;
  final int? id;

  /// Named TMDB feed for non-genre tabs (e.g. 'top_rated'). Null for normal
  /// genre / "All" tabs.
  final String? feed;
}

/// The genre pills shown in the top genre bar (TMDB genre ids).
const List<Genre> kGenres = [
  Genre('All', null),
  Genre('Popular', null, feed: 'top_rated'),
  Genre('Action', 28),
  Genre('Comedy', 35),
  Genre('Horror', 27),
  Genre('Romance', 10749),
  Genre('Sci-Fi', 878),
  Genre('Thriller', 53),
  Genre('Drama', 18),
];

/// Maps TMDB genre ids to short labels for the on-card genre tags.
const Map<int, String> kGenreNames = {
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  10770: 'TV Movie',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
};

/// Maps common ISO 639-1 language codes to display names (for the original
/// language field). Falls back to the uppercased code when not listed.
const Map<String, String> kLanguageNames = {
  'en': 'English',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'it': 'Italian',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'ja': 'Japanese',
  'ko': 'Korean',
  'zh': 'Chinese',
  'cn': 'Chinese',
  'hi': 'Hindi',
  'ta': 'Tamil',
  'te': 'Telugu',
  'ar': 'Arabic',
  'tr': 'Turkish',
  'fa': 'Persian',
  'th': 'Thai',
  'id': 'Indonesian',
  'vi': 'Vietnamese',
  'nl': 'Dutch',
  'sv': 'Swedish',
  'no': 'Norwegian',
  'da': 'Danish',
  'fi': 'Finnish',
  'pl': 'Polish',
  'cs': 'Czech',
  'el': 'Greek',
  'he': 'Hebrew',
  'uk': 'Ukrainian',
  'ro': 'Romanian',
  'hu': 'Hungarian',
  'ms': 'Malay',
  'tl': 'Filipino',
};

/// Shared text styles.
class AppText {
  AppText._();

  static const logo = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: 0.5,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
}
