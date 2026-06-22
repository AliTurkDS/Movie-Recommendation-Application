import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../account/widgets/account_sheet.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../onboarding/widgets/onboarding_overlay.dart';
import '../unwatched/providers/unwatched_provider.dart';
import '../unwatched/widgets/unwatched_sheet.dart';
import '../watched/providers/watched_provider.dart';
import '../watched/widgets/watched_sheet.dart';
import '../watchlist/providers/watchlist_provider.dart';
import '../watchlist/widgets/watchlist_sheet.dart';
import 'providers/search_provider.dart';
import 'widgets/card_stack.dart';
import 'widgets/filter_bar.dart';
import 'widgets/search_bar.dart';

/// The main discovery screen: top bar, genre filters, and the swipe deck.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  bool _promptedOnboarding = false;

  @override
  Widget build(BuildContext context) {
    final searching = ref.watch(isSearchingProvider);

    // Auto-show the swipe guide once, the first time it resolves to unseen.
    final seen = ref.watch(onboardingSeenProvider).valueOrNull;
    if (seen == false && !_promptedOnboarding) {
      _promptedOnboarding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showOnboardingGuide(context).then((_) {
          ref.read(onboardingSeenProvider.notifier).markSeen();
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            const SizedBox(height: 12),
            const MovieSearchBar(),
            const SizedBox(height: 12),
            // Filters are only relevant when not actively searching.
            if (!searching) ...const [
              FilterBar(),
              SizedBox(height: 8),
            ],
            const Expanded(child: CardStack()),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistCount = ref.watch(watchlistCountProvider);
    final watchedCount = ref.watch(watchedCountProvider);
    final unwatchedCount = ref.watch(unwatchedCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              style: AppText.logo,
              children: [
                TextSpan(text: 'Cine', style: TextStyle(color: Colors.white)),
                TextSpan(
                    text: 'Swipe', style: TextStyle(color: AppColors.accent)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TopBarPill(
                tooltip: 'Watched',
                icon: Icons.check_circle_outline,
                color: AppColors.watchedBlue,
                count: watchedCount,
                onTap: () => showWatchedSheet(context),
              ),
              const SizedBox(width: 8),
              _TopBarPill(
                tooltip: 'Watchlist',
                icon: Icons.favorite_border,
                color: AppColors.saveGreen,
                count: watchlistCount,
                onTap: () => showWatchlistSheet(context),
              ),
              const SizedBox(width: 8),
              _TopBarPill(
                tooltip: 'Unwatched',
                icon: Icons.visibility_off_outlined,
                color: AppColors.unwatchedPurple,
                count: unwatchedCount,
                onTap: () => showUnwatchedSheet(context),
              ),
              const SizedBox(width: 8),
              const _OverflowMenu(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overflow (⋮) menu in the header. Currently hosts "Account / Sync";
/// a natural home for future settings.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (value) {
        if (value == 'account') showAccountSheet(context);
        if (value == 'help') showOnboardingGuide(context);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'account',
          child: Row(
            children: [
              Icon(Icons.cloud_sync_outlined,
                  color: AppColors.textPrimary, size: 20),
              SizedBox(width: 12),
              Text('Account / Sync',
                  style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'help',
          child: Row(
            children: [
              Icon(Icons.help_outline,
                  color: AppColors.textPrimary, size: 20),
              SizedBox(width: 12),
              Text('How to swipe',
                  style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact icon + count pill used for the Watched / Watchlist shortcuts.
///
/// Tinted with the action's color: a soft gradient fill, a colored border and
/// glow, and a gradient count badge, with a springy press animation.
class _TopBarPill extends StatefulWidget {
  const _TopBarPill({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  State<_TopBarPill> createState() => _TopBarPillState();
}

class _TopBarPillState extends State<_TopBarPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 6, 7, 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
