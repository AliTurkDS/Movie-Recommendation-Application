import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The locally-remembered cloud-backup credentials (email + password).
///
/// These are *not* an authenticated account — they're only kept so the user
/// doesn't have to retype them on every backup/restore. Cleared by "Forget".
class AccountCredentials {
  const AccountCredentials({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};

  static AccountCredentials? fromJson(Map<String, dynamic> json) {
    final email = json['email'];
    final password = json['password'];
    if (email is! String || password is! String) return null;
    if (email.isEmpty || password.isEmpty) return null;
    return AccountCredentials(email: email, password: password);
  }
}

/// Persists [AccountCredentials] in shared_preferences.
class AccountRepository {
  static const _key = 'cineswipe_account_v1';

  Future<AccountCredentials?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AccountCredentials.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AccountCredentials creds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(creds.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
