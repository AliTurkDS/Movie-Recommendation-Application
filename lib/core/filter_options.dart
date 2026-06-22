import 'constants.dart';

/// A selectable genre option for the Category filter (TMDB genre id + label).
class FilterGenre {
  const FilterGenre(this.id, this.label);
  final int id;
  final String label;
}

/// All TMDB genres, sorted alphabetically, for the Category dropdown.
final List<FilterGenre> kFilterGenres = kGenreNames.entries
    .map((e) => FilterGenre(e.key, e.value))
    .toList()
  ..sort((a, b) => a.label.compareTo(b.label));

/// A country option (ISO 3166-1 alpha-2 code, display name, continent).
class Country {
  const Country(this.code, this.name, this.continent);
  final String code;
  final String name;
  final String continent;
}

/// Countries available for the Country / Continent filters, grouped by the
/// continent each belongs to. Codes are passed to TMDB as `with_origin_country`.
const List<Country> kCountries = [
  // Africa
  Country('DZ', 'Algeria', 'Africa'),
  Country('AO', 'Angola', 'Africa'),
  Country('CM', 'Cameroon', 'Africa'),
  Country('CI', 'Ivory Coast', 'Africa'),
  Country('EG', 'Egypt', 'Africa'),
  Country('ET', 'Ethiopia', 'Africa'),
  Country('GH', 'Ghana', 'Africa'),
  Country('KE', 'Kenya', 'Africa'),
  Country('MA', 'Morocco', 'Africa'),
  Country('ML', 'Mali', 'Africa'),
  Country('MZ', 'Mozambique', 'Africa'),
  Country('NG', 'Nigeria', 'Africa'),
  Country('SN', 'Senegal', 'Africa'),
  Country('ZA', 'South Africa', 'Africa'),
  Country('TZ', 'Tanzania', 'Africa'),
  Country('TN', 'Tunisia', 'Africa'),
  Country('UG', 'Uganda', 'Africa'),
  Country('ZW', 'Zimbabwe', 'Africa'),

  // Asia
  Country('AM', 'Armenia', 'Asia'),
  Country('AZ', 'Azerbaijan', 'Asia'),
  Country('BD', 'Bangladesh', 'Asia'),
  Country('KH', 'Cambodia', 'Asia'),
  Country('CN', 'China', 'Asia'),
  Country('GE', 'Georgia', 'Asia'),
  Country('HK', 'Hong Kong', 'Asia'),
  Country('IN', 'India', 'Asia'),
  Country('ID', 'Indonesia', 'Asia'),
  Country('IR', 'Iran', 'Asia'),
  Country('IQ', 'Iraq', 'Asia'),
  Country('IL', 'Israel', 'Asia'),
  Country('JP', 'Japan', 'Asia'),
  Country('JO', 'Jordan', 'Asia'),
  Country('KZ', 'Kazakhstan', 'Asia'),
  Country('KW', 'Kuwait', 'Asia'),
  Country('LB', 'Lebanon', 'Asia'),
  Country('MY', 'Malaysia', 'Asia'),
  Country('MN', 'Mongolia', 'Asia'),
  Country('MM', 'Myanmar', 'Asia'),
  Country('NP', 'Nepal', 'Asia'),
  Country('PK', 'Pakistan', 'Asia'),
  Country('PH', 'Philippines', 'Asia'),
  Country('QA', 'Qatar', 'Asia'),
  Country('SA', 'Saudi Arabia', 'Asia'),
  Country('SG', 'Singapore', 'Asia'),
  Country('KR', 'South Korea', 'Asia'),
  Country('LK', 'Sri Lanka', 'Asia'),
  Country('SY', 'Syria', 'Asia'),
  Country('TW', 'Taiwan', 'Asia'),
  Country('TH', 'Thailand', 'Asia'),
  Country('TR', 'Turkey', 'Asia'),
  Country('AE', 'United Arab Emirates', 'Asia'),
  Country('VN', 'Vietnam', 'Asia'),

  // Europe
  Country('AL', 'Albania', 'Europe'),
  Country('AT', 'Austria', 'Europe'),
  Country('BE', 'Belgium', 'Europe'),
  Country('BA', 'Bosnia and Herzegovina', 'Europe'),
  Country('BG', 'Bulgaria', 'Europe'),
  Country('HR', 'Croatia', 'Europe'),
  Country('CY', 'Cyprus', 'Europe'),
  Country('CZ', 'Czech Republic', 'Europe'),
  Country('DK', 'Denmark', 'Europe'),
  Country('EE', 'Estonia', 'Europe'),
  Country('FI', 'Finland', 'Europe'),
  Country('FR', 'France', 'Europe'),
  Country('DE', 'Germany', 'Europe'),
  Country('GR', 'Greece', 'Europe'),
  Country('HU', 'Hungary', 'Europe'),
  Country('IS', 'Iceland', 'Europe'),
  Country('IE', 'Ireland', 'Europe'),
  Country('IT', 'Italy', 'Europe'),
  Country('LV', 'Latvia', 'Europe'),
  Country('LT', 'Lithuania', 'Europe'),
  Country('LU', 'Luxembourg', 'Europe'),
  Country('MK', 'North Macedonia', 'Europe'),
  Country('NL', 'Netherlands', 'Europe'),
  Country('NO', 'Norway', 'Europe'),
  Country('PL', 'Poland', 'Europe'),
  Country('PT', 'Portugal', 'Europe'),
  Country('RO', 'Romania', 'Europe'),
  Country('RU', 'Russia', 'Europe'),
  Country('RS', 'Serbia', 'Europe'),
  Country('SK', 'Slovakia', 'Europe'),
  Country('SI', 'Slovenia', 'Europe'),
  Country('ES', 'Spain', 'Europe'),
  Country('SE', 'Sweden', 'Europe'),
  Country('CH', 'Switzerland', 'Europe'),
  Country('UA', 'Ukraine', 'Europe'),
  Country('GB', 'United Kingdom', 'Europe'),

  // North America
  Country('CA', 'Canada', 'North America'),
  Country('CR', 'Costa Rica', 'North America'),
  Country('CU', 'Cuba', 'North America'),
  Country('DO', 'Dominican Republic', 'North America'),
  Country('SV', 'El Salvador', 'North America'),
  Country('GT', 'Guatemala', 'North America'),
  Country('HN', 'Honduras', 'North America'),
  Country('JM', 'Jamaica', 'North America'),
  Country('MX', 'Mexico', 'North America'),
  Country('PA', 'Panama', 'North America'),
  Country('PR', 'Puerto Rico', 'North America'),
  Country('US', 'United States', 'North America'),

  // South America
  Country('AR', 'Argentina', 'South America'),
  Country('BO', 'Bolivia', 'South America'),
  Country('BR', 'Brazil', 'South America'),
  Country('CL', 'Chile', 'South America'),
  Country('CO', 'Colombia', 'South America'),
  Country('EC', 'Ecuador', 'South America'),
  Country('PY', 'Paraguay', 'South America'),
  Country('PE', 'Peru', 'South America'),
  Country('UY', 'Uruguay', 'South America'),
  Country('VE', 'Venezuela', 'South America'),

  // Oceania
  Country('AU', 'Australia', 'Oceania'),
  Country('FJ', 'Fiji', 'Oceania'),
  Country('NZ', 'New Zealand', 'Oceania'),
  Country('PG', 'Papua New Guinea', 'Oceania'),
];

/// Distinct continents, in display order.
const List<String> kContinents = [
  'Africa',
  'Asia',
  'Europe',
  'North America',
  'South America',
  'Oceania',
];

/// Origin-country codes belonging to [continent].
List<String> countryCodesForContinent(String continent) =>
    kCountries.where((c) => c.continent == continent).map((c) => c.code).toList();

/// Selectable release years, newest first, back to 1950.
List<int> filterYears() {
  final current = DateTime.now().year;
  return [for (var y = current; y >= 1950; y--) y];
}
