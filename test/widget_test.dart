import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/models/movie.dart';

void main() {
  group('Movie model', () {
    final json = {
      'id': 157336,
      'title': 'Interstellar',
      'poster_path': '/poster.jpg',
      'backdrop_path': '/backdrop.jpg',
      'vote_average': 8.6,
      'release_date': '2014-11-05',
      'overview': 'A team of explorers travel through a wormhole.',
      'genre_ids': [878, 18],
    };

    test('parses TMDB list json', () {
      final m = Movie.fromJson(json);
      expect(m.id, 157336);
      expect(m.title, 'Interstellar');
      expect(m.year, '2014');
      expect(m.rating, '8.6');
      expect(m.matchPercent, 86);
      expect(m.genreLabels(), ['Sci-Fi', 'Drama']);
      expect(m.posterUrl, contains('/poster.jpg'));
    });

    test('round-trips through toJson/fromJson', () {
      final m = Movie.fromJson(json);
      final restored = Movie.fromJson(m.toJson());
      expect(restored.id, m.id);
      expect(restored.title, m.title);
      expect(restored.genreIds, m.genreIds);
    });
  });
}
