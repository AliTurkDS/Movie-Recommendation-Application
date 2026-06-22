import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the one-time startup login/welcome screen has been shown.
///
/// `true` once the user has either signed in or tapped "Skip for now", so the
/// welcome screen never auto-appears again. Backup setup afterwards happens from
/// the Account / Sync sheet instead.
class LoginPromptRepository {
  static const _key = 'cineswipe_login_prompted_v1';

  Future<bool> hasPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
