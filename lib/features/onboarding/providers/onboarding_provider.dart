import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Whether the swipe-gesture onboarding guide has been seen, backed by
/// shared_preferences. `false` until the user dismisses it the first time.
class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.read(onboardingRepositoryProvider).hasSeen();
  }

  Future<void> markSeen() async {
    if (state.valueOrNull == true) return;
    state = const AsyncData(true);
    await ref.read(onboardingRepositoryProvider).markSeen();
  }
}

final onboardingSeenProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
