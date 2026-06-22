import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Whether the one-time startup login/welcome screen has been shown, backed by
/// shared_preferences. `false` until the user signs in or skips it.
class LoginPromptNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.read(loginPromptRepositoryProvider).hasPrompted();
  }

  Future<void> markPrompted() async {
    if (state.valueOrNull == true) return;
    state = const AsyncData(true);
    await ref.read(loginPromptRepositoryProvider).markPrompted();
  }
}

final loginPromptedProvider =
    AsyncNotifierProvider<LoginPromptNotifier, bool>(LoginPromptNotifier.new);
