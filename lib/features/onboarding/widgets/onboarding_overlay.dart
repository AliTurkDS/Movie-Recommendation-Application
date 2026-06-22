import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// Shows the one-time swipe-gesture guide as a modal overlay.
Future<void> showOnboardingGuide(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (_) => const _OnboardingDialog(),
  );
}

class _OnboardingDialog extends StatelessWidget {
  const _OnboardingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How to swipe', style: AppText.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Swipe a movie card in any direction',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          const _SwipeDiagram(),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 44, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Got it',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

/// A mock movie card surrounded by the four directional swipe cues.
class _SwipeDiagram extends StatelessWidget {
  const _SwipeDiagram();

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Up → Watched.
        const _Cue(
          axis: Axis.vertical,
          arrow: Icons.keyboard_double_arrow_up_rounded,
          label: 'Watched',
          color: AppColors.watchedBlue,
          arrowFirst: true,
        ),
        gap,
        // Left | card | Right — equal Expanded sides keep the card centered
        // and the two side cues an equal distance from it.
        Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _Cue(
                  axis: Axis.horizontal,
                  arrow: Icons.keyboard_double_arrow_left_rounded,
                  label: 'Skip',
                  color: AppColors.accent,
                  arrowFirst: false,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _card(),
            const SizedBox(width: 14),
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Cue(
                  axis: Axis.horizontal,
                  arrow: Icons.keyboard_double_arrow_right_rounded,
                  label: 'Watchlist',
                  color: AppColors.saveGreen,
                  arrowFirst: true,
                ),
              ),
            ),
          ],
        ),
        gap,
        // Down → Unwatched.
        const _Cue(
          axis: Axis.vertical,
          arrow: Icons.keyboard_double_arrow_down_rounded,
          label: 'Unwatched',
          color: AppColors.unwatchedPurple,
          arrowFirst: false,
        ),
      ],
    );
  }

  Widget _card() {
    return Container(
      width: 104,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.genreTagBorder),
      ),
      child: const Icon(Icons.local_movies_outlined,
          color: AppColors.textSecondary, size: 40),
    );
  }
}

/// An arrow + label cue pointing in one swipe direction. Lays out as a
/// column (vertical swipes) or row (horizontal swipes), with the arrow on
/// the outer side toward the screen edge.
class _Cue extends StatelessWidget {
  const _Cue({
    required this.axis,
    required this.arrow,
    required this.label,
    required this.color,
    required this.arrowFirst,
  });

  final Axis axis;
  final IconData arrow;
  final String label;
  final Color color;
  final bool arrowFirst;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(arrow, color: color, size: 30);
    final Widget textWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
    // In a Row the label must be Flexible so a long word can't overflow; in a
    // Column it sizes naturally (a Flexible would get unbounded height).
    final text =
        axis == Axis.horizontal ? Flexible(child: textWidget) : textWidget;

    final children = arrowFirst
        ? [icon, const SizedBox(width: 4, height: 2), text]
        : [text, const SizedBox(width: 4, height: 2), icon];

    return axis == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
