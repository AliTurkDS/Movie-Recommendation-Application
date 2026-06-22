import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/constants.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';

/// Thrown when a TMDB request fails in a way worth surfacing to the user.
class TmdbException implements Exception {
  TmdbException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin wrapper around the TMDB REST API using dio.
class TmdbService {
  TmdbService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  final Dio _dio;

  String get _apiKey {
    final key = dotenv.maybeGet(ApiConfig.apiKeyEnvName);
    if (key == null || key.isEmpty) {
      throw TmdbException(
        'Missing TMDB API key. Add TMDB_API_KEY to your .env file.',
      );
    }
    return key;
  }

  Future<List<Movie>> _fetchList(String path, Map<String, dynamic> query) async {
    try {
      final res = await _dio.get(path, queryParameters: {
        'api_key': _apiKey,
        ...query,
      });
      final results = (res.data['results'] as List?) ?? const [];
      return results
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw TmdbException(_messageFor(e));
    }
  }

  /// Popular movies (used for the "All" genre).
  Future<List<Movie>> popular({int page = 1}) =>
      _fetchList('/movie/popular', {'page': page});

  /// Top-rated movies (used for the "Popular" tab — the highest-rated titles).
  Future<List<Movie>> topRated({int page = 1}) =>
      _fetchList('/movie/top_rated', {'page': page});

  /// Search movies by free-text query.
  Future<List<Movie>> search(String query, {int page = 1}) =>
      _fetchList('/search/movie', {
        'query': query,
        'page': page,
        'include_adult': false,
      });

  /// Discover movies filtered by any combination of genre, release year, and
  /// origin countries (passed OR'd together as `with_origin_country`).
  Future<List<Movie>> discover({
    int? genreId,
    int? year,
    List<String>? originCountries,
    int page = 1,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'sort_by': 'popularity.desc',
      'include_adult': false,
    };
    if (genreId != null) query['with_genres'] = genreId;
    if (year != null) query['primary_release_year'] = year;
    if (originCountries != null && originCountries.isNotEmpty) {
      query['with_origin_country'] = originCountries.join('|');
    }
    return _fetchList('/discover/movie', query);
  }

  /// Full movie detail plus credits, videos, watch providers, and
  /// recommendations in a single request.
  Future<MovieDetail> detail(int id) async {
    try {
      final res = await _dio.get('/movie/$id', queryParameters: {
        'api_key': _apiKey,
        'append_to_response': 'credits,videos,watch/providers,recommendations',
      });
      return MovieDetail.fromJson(
        res.data as Map<String, dynamic>,
        preferredRegion: ui.PlatformDispatcher.instance.locale.countryCode,
      );
    } on DioException catch (e) {
      throw TmdbException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network problem. Check your connection and try again.';
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return 'Invalid TMDB API key (401). Check your .env file.';
    }
    if (status != null) {
      return 'TMDB request failed ($status). Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
