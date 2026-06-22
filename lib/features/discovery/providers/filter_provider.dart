import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filter_options.dart';

/// The combined discovery filter: category (genre) + year + region.
///
/// Region is hierarchical: [continent] is the broad parent and [countryCode]
/// an optional refinement within it. Picking a country auto-sets its
/// continent; the query uses the specific country when set, otherwise every
/// country in the continent.
class MovieFilter {
  const MovieFilter({
    this.genreId,
    this.genreLabel,
    this.year,
    this.countryCode,
    this.countryName,
    this.continent,
    this.topRated = false,
  });

  final int? genreId;
  final String? genreLabel;
  final int? year;
  final String? countryCode;
  final String? countryName;
  final String? continent;

  /// When true, browse TMDB's highest-rated films (standalone — ignores the
  /// other filter dimensions).
  final bool topRated;

  bool get isEmpty =>
      !topRated &&
      genreId == null &&
      year == null &&
      countryCode == null &&
      continent == null;

  /// Origin-country codes for the TMDB query: the single chosen country, or
  /// every country in the chosen continent, or null when no region is set.
  List<String>? get originCountries {
    if (countryCode != null) return [countryCode!];
    if (continent != null) return countryCodesForContinent(continent!);
    return null;
  }
}

/// Holds the active [MovieFilter]. Each setter replaces the state so the
/// discovery deck rebuilds; choosing a country/continent clears the other.
class MovieFilterNotifier extends Notifier<MovieFilter> {
  @override
  MovieFilter build() => const MovieFilter();

  void setGenre(FilterGenre? genre) {
    state = MovieFilter(
      genreId: genre?.id,
      genreLabel: genre?.label,
      year: state.year,
      countryCode: state.countryCode,
      countryName: state.countryName,
      continent: state.continent,
    );
  }

  void setYear(int? year) {
    state = MovieFilter(
      genreId: state.genreId,
      genreLabel: state.genreLabel,
      year: year,
      countryCode: state.countryCode,
      countryName: state.countryName,
      continent: state.continent,
    );
  }

  void setCountry(Country? country) {
    // Picking a country auto-sets its continent; clearing it (null) keeps the
    // current continent so the region stays scoped.
    state = MovieFilter(
      genreId: state.genreId,
      genreLabel: state.genreLabel,
      year: state.year,
      countryCode: country?.code,
      countryName: country?.name,
      continent: country?.continent ?? state.continent,
    );
  }

  void setContinent(String? continent) {
    // Keep a selected country only if it still belongs to the chosen
    // continent (its continent always equals the current state when set).
    final keepCountry = continent != null &&
        state.countryCode != null &&
        continent == state.continent;
    state = MovieFilter(
      genreId: state.genreId,
      genreLabel: state.genreLabel,
      year: state.year,
      countryCode: keepCountry ? state.countryCode : null,
      countryName: keepCountry ? state.countryName : null,
      continent: continent,
    );
  }

  /// Top Rated is a standalone feed: enabling it clears every other filter,
  /// disabling it returns to the default (popular) feed.
  void setTopRated(bool value) {
    state = value ? const MovieFilter(topRated: true) : const MovieFilter();
  }

  void clearAll() => state = const MovieFilter();
}

final movieFilterProvider =
    NotifierProvider<MovieFilterNotifier, MovieFilter>(MovieFilterNotifier.new);
