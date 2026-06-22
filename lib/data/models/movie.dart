import '../../core/constants.dart';

/// A movie as used throughout the app. Built from TMDB JSON, and also
/// (de)serialized to/from a compact JSON form for shared_preferences storage.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.overview,
    required this.genreIds,
    this.popularity = 0,
    this.tagline,
    this.runtime,
  });

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final String overview;
  final List<int> genreIds;

  /// TMDB popularity score (used to rank search results).
  final double popularity;
  final String? tagline;
  final int? runtime;

  /// Full poster URL (w500), or null when no poster is available.
  String? get posterUrl =>
      posterPath == null ? null : '${ApiConfig.imageBaseW500}$posterPath';

  /// Full backdrop URL (original), falling back to the poster.
  String? get backdropUrl {
    final path = backdropPath ?? posterPath;
    return path == null ? null : '${ApiConfig.imageBaseOriginal}$path';
  }

  /// Release year as a 4-char string, or empty when unknown.
  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';

  /// A "% Match" figure derived from the TMDB vote average (0–10 → 0–100).
  int get matchPercent => (voteAverage * 10).round().clamp(0, 100);

  /// Human-readable rating, e.g. "8.6".
  String get rating => voteAverage.toStringAsFixed(1);

  /// Up to [max] short genre labels resolved from [genreIds].
  List<String> genreLabels({int max = 3}) {
    final labels = <String>[];
    for (final id in genreIds) {
      final name = kGenreNames[id];
      if (name != null) labels.add(name);
      if (labels.length >= max) break;
    }
    return labels;
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    // The detail endpoint returns `genres: [{id, name}]`, while list
    // endpoints return `genre_ids: [int]`. Support both.
    final List<int> genreIds;
    if (json['genre_ids'] is List) {
      genreIds = (json['genre_ids'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    } else if (json['genres'] is List) {
      genreIds = (json['genres'] as List)
          .map((e) => (e['id'] as num).toInt())
          .toList();
    } else {
      genreIds = const [];
    }

    return Movie(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? json['name'] ?? 'Untitled') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: (json['release_date'] as String?) ?? '',
      overview: (json['overview'] as String?) ?? '',
      genreIds: genreIds,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      tagline: json['tagline'] as String?,
      runtime: (json['runtime'] as num?)?.toInt(),
    );
  }

  /// Merge richer detail fields (tagline, runtime, full genres) onto an
  /// existing list-derived movie.
  Movie mergeDetail(Movie detail) {
    return Movie(
      id: id,
      title: detail.title.isNotEmpty ? detail.title : title,
      posterPath: detail.posterPath ?? posterPath,
      backdropPath: detail.backdropPath ?? backdropPath,
      voteAverage: detail.voteAverage,
      releaseDate: detail.releaseDate.isNotEmpty
          ? detail.releaseDate
          : releaseDate,
      overview: detail.overview.isNotEmpty ? detail.overview : overview,
      genreIds: detail.genreIds.isNotEmpty ? detail.genreIds : genreIds,
      popularity: detail.popularity > 0 ? detail.popularity : popularity,
      tagline: detail.tagline ?? tagline,
      runtime: detail.runtime ?? runtime,
    );
  }

  /// Compact form persisted to shared_preferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'vote_average': voteAverage,
        'release_date': releaseDate,
        'overview': overview,
        'genre_ids': genreIds,
        'popularity': popularity,
        'tagline': tagline,
        'runtime': runtime,
      };

  @override
  bool operator ==(Object other) => other is Movie && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
