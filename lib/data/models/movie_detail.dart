import '../../core/constants.dart';
import 'movie.dart';

/// A single top-billed cast member.
class CastMember {
  const CastMember({required this.name, required this.character, this.profilePath});

  final String name;
  final String character;
  final String? profilePath;

  String? get profileUrl =>
      profilePath == null ? null : '${ApiConfig.imageBaseW185}$profilePath';
}

/// A streaming/where-to-watch provider for a region.
class WatchProvider {
  const WatchProvider({required this.name, this.logoPath});

  final String name;
  final String? logoPath;

  String? get logoUrl =>
      logoPath == null ? null : '${ApiConfig.imageBaseW185}$logoPath';
}

/// Rich movie detail assembled from `/movie/{id}` with
/// `append_to_response=credits,videos,watch/providers,recommendations`.
class MovieDetail {
  const MovieDetail({
    required this.movie,
    required this.cast,
    required this.director,
    required this.writers,
    required this.trailerYoutubeKey,
    required this.originalLanguage,
    required this.watchProviders,
    required this.watchLink,
    required this.recommendations,
  });

  /// The base movie (title, overview, runtime, genres, poster, etc.).
  final Movie movie;
  final List<CastMember> cast;
  final String? director;
  final List<String> writers;

  /// YouTube video key for the trailer, or null when none is available.
  final String? trailerYoutubeKey;

  /// Display name of the original language (e.g. "Korean").
  final String originalLanguage;

  /// Streaming providers for the chosen region (flatrate).
  final List<WatchProvider> watchProviders;

  /// TMDB "where to watch" page for the region, if available.
  final String? watchLink;

  /// "More like this" recommendations.
  final List<Movie> recommendations;

  factory MovieDetail.fromJson(Map<String, dynamic> json,
      {String? preferredRegion}) {
    final movie = Movie.fromJson(json);

    // ---- Credits (cast + crew) ----
    final credits = json['credits'] as Map<String, dynamic>?;
    final castJson = (credits?['cast'] as List?) ?? const [];
    final cast = castJson
        .take(12)
        .map((e) => CastMember(
              name: (e['name'] as String?) ?? '',
              character: (e['character'] as String?) ?? '',
              profilePath: e['profile_path'] as String?,
            ))
        .where((c) => c.name.isNotEmpty)
        .toList();

    final crew = (credits?['crew'] as List?) ?? const [];
    String? director;
    final writers = <String>[];
    for (final c in crew) {
      final name = (c['name'] as String?) ?? '';
      if (name.isEmpty) continue;
      final job = c['job'] as String?;
      final dept = c['department'] as String?;
      if (job == 'Director' && director == null) director = name;
      final isWriter = dept == 'Writing' ||
          job == 'Screenplay' ||
          job == 'Writer' ||
          job == 'Story';
      if (isWriter && !writers.contains(name)) writers.add(name);
    }

    // ---- Videos -> trailer ----
    final videos = (json['videos']?['results'] as List?) ?? const [];
    String? trailerKey;
    for (final v in videos) {
      if (v['site'] != 'YouTube') continue;
      if (v['type'] == 'Trailer') {
        trailerKey ??= v['key'] as String?;
        if (v['official'] == true) {
          trailerKey = v['key'] as String?;
          break;
        }
      }
    }
    if (trailerKey == null) {
      for (final v in videos) {
        if (v['site'] == 'YouTube' && v['type'] == 'Teaser') {
          trailerKey = v['key'] as String?;
          break;
        }
      }
    }

    // ---- Watch providers (prefer the device region, then US, then any;
    // include streaming, free, ad-supported, rent and buy) ----
    final providersByRegion =
        json['watch/providers']?['results'] as Map<String, dynamic>?;
    final watchProviders = <WatchProvider>[];
    String? watchLink;
    if (providersByRegion != null && providersByRegion.isNotEmpty) {
      final region = <String?>[preferredRegion, 'US'].firstWhere(
        (r) => r != null && providersByRegion.containsKey(r),
        orElse: () => providersByRegion.keys.first,
      );
      final regionData = providersByRegion[region] as Map<String, dynamic>?;
      watchLink = regionData?['link'] as String?;
      final seen = <String>{};
      for (final group in const ['flatrate', 'free', 'ads', 'rent', 'buy']) {
        for (final e in (regionData?[group] as List?) ?? const []) {
          final name = (e['provider_name'] as String?) ?? '';
          if (name.isEmpty || !seen.add(name)) continue;
          watchProviders.add(WatchProvider(
            name: name,
            logoPath: e['logo_path'] as String?,
          ));
        }
      }
    }

    // ---- Recommendations ----
    final recsJson = (json['recommendations']?['results'] as List?) ?? const [];
    final recommendations = recsJson
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .where((m) => m.posterPath != null)
        .take(12)
        .toList();

    // ---- Original language ----
    final langCode = json['original_language'] as String?;
    final language = kLanguageNames[langCode] ?? (langCode?.toUpperCase() ?? '');

    return MovieDetail(
      movie: movie,
      cast: cast,
      director: director,
      writers: writers,
      trailerYoutubeKey: trailerKey,
      originalLanguage: language,
      watchProviders: watchProviders,
      watchLink: watchLink,
      recommendations: recommendations,
    );
  }
}
