import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The active search query. Empty string means "not searching" — the deck
/// falls back to genre browsing.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Whether a search is currently active.
final isSearchingProvider = Provider<bool>(
  (ref) => ref.watch(searchQueryProvider).trim().isNotEmpty,
);
