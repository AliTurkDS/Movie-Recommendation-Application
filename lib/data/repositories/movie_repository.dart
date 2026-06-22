import '../../features/discovery/providers/filter_provider.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../services/tmdb_service.dart';

/// Coordinates movie fetching for the discovery deck.
class MovieRepository {
  MovieRepository(this._service);

  final TmdbService _service;

  /// Fetch a page of movies. A non-empty [query] takes precedence (search);
  /// an empty [filter] falls back to popular; otherwise discover by the
  /// filter's genre / year / region.
  Future<List<Movie>> fetchPage({
    required MovieFilter filter,
    String? query,
    int page = 1,
  }) {
    if (query != null && query.trim().isNotEmpty) {
      return _service.search(query.trim(), page: page);
    }
    if (filter.topRated) {
      return _service.topRated(page: page);
    }
    if (filter.isEmpty) {
      return _service.popular(page: page);
    }
    return _service.discover(
      genreId: filter.genreId,
      year: filter.year,
      originCountries: filter.originCountries,
      page: page,
    );
  }

  /// Fetch full detail (credits, videos, providers, recommendations).
  Future<MovieDetail> fetchDetail(int id) => _service.detail(id);
}
