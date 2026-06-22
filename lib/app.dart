import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'features/account/providers/account_provider.dart';
import 'features/account/providers/login_prompt_provider.dart';
import 'features/account/widgets/login_screen.dart';
import 'features/discovery/discovery_screen.dart';

class CineSwipeApp extends StatelessWidget {
  const CineSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineSwipe',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _RootGate(),
    );
  }
}

/// Decides the first screen: the one-time login on first launch (unless already
/// signed in), otherwise the main discovery screen.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    final prompted = ref.watch(loginPromptedProvider);

    // Wait for both flags to load before deciding (avoids a flash of the wrong
    // screen). Show a plain branded splash meanwhile.
    if (account.isLoading || prompted.isLoading) {
      return const _Splash();
    }

    final signedIn = account.valueOrNull != null;
    final alreadyPrompted = prompted.valueOrNull ?? false;

    // Show the welcome/login only on first launch and only if not signed in.
    if (!signedIn && !alreadyPrompted) {
      return const LoginScreen();
    }
    return const DiscoveryScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: RichText(
          text: const TextSpan(
            style: AppText.logo,
            children: [
              TextSpan(text: 'Cine', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Swipe', style: TextStyle(color: AppColors.accent)),
            ],
          ),
        ),
      ),
    );
  }
}
