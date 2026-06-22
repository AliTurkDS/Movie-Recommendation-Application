import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the TMDB API key. Don't crash if .env is missing — the UI surfaces
  // a friendly error state instead.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not bundled; TmdbService will raise a clear message on first call.
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: CineSwipeApp()));
}
