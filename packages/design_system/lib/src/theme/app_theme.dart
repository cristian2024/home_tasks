import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

/// Temas claro y oscuro construidos a partir de los tokens.
///
/// Las tipografías son las de Material 3: Flutter las escala con el
/// `TextScaler` del sistema, así que soportan el 200 % del §14.3.
abstract final class AppTheme {
  static ThemeData get light => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primaryDark,
          secondary: AppColors.secondary,
          error: AppColors.error,
          surface: AppColors.surfaceLight,
        ),
        scaffoldBackground: AppColors.backgroundLight,
      );

  static ThemeData get dark => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          error: const Color(0xFFEF9A9A), // Contraste suficiente sobre fondo oscuro.
          surface: AppColors.surfaceDark,
        ),
        scaffoldBackground: AppColors.backgroundDark,
      );

  static ThemeData _build(ColorScheme scheme, {required Color scaffoldBackground}) {
    const minimumButtonSize = Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.medium));
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minimumButtonSize, shape: buttonShape, padding: buttonPadding),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: minimumButtonSize, shape: buttonShape, padding: buttonPadding),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minimumButtonSize, shape: buttonShape),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: minimumButtonSize)),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
      ),
    );
  }
}
