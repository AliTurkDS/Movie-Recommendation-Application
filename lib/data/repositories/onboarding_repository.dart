import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has seen the swipe-gesture onboarding guide.
class OnboardingRepository {
  static const _key = 'cineswipe_onboarding_seen_v1';

  Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
