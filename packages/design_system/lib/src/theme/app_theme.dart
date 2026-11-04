import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_theme_colors.dart';
import '../tokens/app_typography.dart';

/// Temas claro y oscuro construidos a partir de los tokens.
///
/// Las tipografías son los estilos `mobile*` de [AppTypography]: Flutter las
/// escala con el `TextScaler` del sistema, así que soportan el 200 % del §14.3.
abstract final class AppTheme {
  /// Conserva la escala de Material (el cuerpo por defecto sigue siendo 14) para
  /// que las pantallas no cambien de tamaño. `mobileBodyL` queda fuera: el lienzo
  /// no usa el cuerpo de 17.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTypography.mobileDisplay,
    displayMedium: AppTypography.mobileH1,
    displaySmall: AppTypography.mobileH2,
    headlineLarge: AppTypography.mobileH1,
    headlineMedium: AppTypography.mobileH2,
    headlineSmall: AppTypography.mobileH3,
    titleLarge: AppTypography.mobileH4,
    titleMedium: AppTypography.mobileLabelL,
    titleSmall: AppTypography.mobileLabelM,
    bodyLarge: AppTypography.mobileBodyM,
    bodyMedium: AppTypography.mobileBodyS,
    bodySmall: AppTypography.mobileCaption,
    labelLarge: AppTypography.mobileLabelM,
    labelMedium: AppTypography.mobileLabelS,
    labelSmall: AppTypography.mobileLabelS,
  );

  /// Semántica de `Theme Light` en Figma. Los tonos `tertiary` son los de aviso.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.violet700,
    onPrimary: AppColors.neutral0,
    primaryContainer: AppColors.violet100,
    onPrimaryContainer: AppColors.violet800,
    secondary: AppColors.violet700,
    onSecondary: AppColors.neutral0,
    secondaryContainer: AppColors.violet100,
    onSecondaryContainer: AppColors.violet800,
    tertiary: AppColors.amber700,
    onTertiary: AppColors.neutral0,
    tertiaryContainer: AppColors.amber100,
    onTertiaryContainer: AppColors.amber700,
    error: AppColors.red700,
    onError: AppColors.neutral0,
    errorContainer: AppColors.red50,
    onErrorContainer: AppColors.red800,
    surface: AppColors.neutral0,
    onSurface: AppColors.neutral900,
    onSurfaceVariant: AppColors.neutral600,
    surfaceContainerLowest: AppColors.neutral0,
    surfaceContainerLow: AppColors.neutral0,
    surfaceContainer: AppColors.neutral0,
    surfaceContainerHigh: AppColors.neutral0,
    surfaceContainerHighest: AppColors.neutral100,
    outline: AppColors.neutral450,
    outlineVariant: AppColors.neutral200,
    inverseSurface: AppColors.neutral800,
    onInverseSurface: AppColors.neutral100,
    inversePrimary: AppColors.violet300,
  );

  /// Semántica de `Theme Dark` en Figma. `surfaceContainerHighest` usa el tono
  /// elevado, no el hundido, porque Material lo pinta sobre las superficies.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.violet400,
    onPrimary: AppColors.violet1000,
    primaryContainer: AppColors.violet900,
    onPrimaryContainer: AppColors.violet200,
    secondary: AppColors.violet300,
    onSecondary: AppColors.violet1000,
    secondaryContainer: AppColors.violet900,
    onSecondaryContainer: AppColors.violet200,
    tertiary: AppColors.amber400,
    onTertiary: AppColors.amber950,
    tertiaryContainer: AppColors.amber950,
    onTertiaryContainer: AppColors.amber400,
    error: AppColors.red400,
    onError: AppColors.red950,
    errorContainer: AppColors.red950,
    onErrorContainer: AppColors.red300,
    surface: AppColors.neutral900,
    onSurface: AppColors.neutral100,
    onSurfaceVariant: AppColors.neutral400,
    surfaceContainerLowest: AppColors.neutral950,
    surfaceContainerLow: AppColors.neutral900,
    surfaceContainer: AppColors.neutral900,
    surfaceContainerHigh: AppColors.neutral800,
    surfaceContainerHighest: AppColors.neutral800,
    outline: AppColors.neutral500,
    outlineVariant: AppColors.neutral700,
    inverseSurface: AppColors.neutral100,
    onInverseSurface: AppColors.neutral800,
    inversePrimary: AppColors.violet700,
  );

  static ThemeData get light => _build(_lightScheme, AppThemeColors.light);

  static ThemeData get dark => _build(_darkScheme, AppThemeColors.dark);

  static ThemeData _build(ColorScheme scheme, AppThemeColors colors) {
    const Size minimumButtonSize = Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget);
    final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.small));
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme,
      primaryTextTheme: _textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.bgCanvas,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgCanvas,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
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
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.extraLarge)),
        ),
      ),
    );
  }
}
