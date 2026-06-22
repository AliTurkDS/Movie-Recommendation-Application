import 'package:flutter/material.dart';

import 'constants.dart';

/// The global dark theme for CineSwipe.
ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.saveGreen,
      surface: AppColors.surface,
    ),
    canvasColor: AppColors.background,
    splashColor: Colors.white10,
    highlightColor: Colors.white10,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
