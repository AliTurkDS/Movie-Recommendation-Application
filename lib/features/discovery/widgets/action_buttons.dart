import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// The Skip / Watched / Unwatched / Save / Info action row below the stack.
class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.onSkip,
    required this.onWatched,
    required this.onUnwatched,
    required this.onInfo,
    required this.onSave,
    this.enabled = true,
  });

  final VoidCallback onSkip;
  final VoidCallback onWatched;
  final VoidCallback onUnwatched;
  final VoidCallback onInfo;
  final VoidCallback onSave;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CircleButton(
          size: 52,
          icon: Icons.close,
          color: AppColors.accent,
          onTap: enabled ? onSkip : null,
        ),
        const SizedBox(width: 16),
        _CircleButton(
          size: 52,
          icon: Icons.check,
          color: AppColors.watchedBlue,
          onTap: enabled ? onWatched : null,
        ),
        const SizedBox(width: 16),
        _CircleButton(
          size: 52,
          icon: Icons.visibility_off,
          color: AppColors.unwatchedPurple,
          onTap: enabled ? onUnwatched : null,
        ),
        const SizedBox(width: 16),
        _CircleButton(
          size: 52,
          icon: Icons.favorite,
          color: AppColors.saveGreen,
          onTap: enabled ? onSave : null,
        ),
        const SizedBox(width: 16),
        _CircleButton(
          size: 52,
          icon: Icons.info_outline,
          color: AppColors.textSecondary,
          onTap: enabled ? onInfo : null,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.size,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
          ),
          child: Icon(icon, color: color, size: size * 0.42),
        ),
      ),
    );
  }
}
