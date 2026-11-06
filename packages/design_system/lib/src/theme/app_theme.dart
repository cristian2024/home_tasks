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
    OutlineInputBorder fieldBorder(Color color, {double width = AppSizes.strokeThin}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(color: color, width: width),
          gapPadding: AppSpacing.s0,
        );

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
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: AppSizes.topBarHeight,
        leadingWidth: AppSizes.minTouchTarget,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actionsIconTheme: IconThemeData(color: colors.textPrimary),
        actionsPadding: const EdgeInsets.only(right: AppSpacing.xs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minimumButtonSize,
          shape: buttonShape,
          padding: buttonPadding,
          iconSize: AppSizes.iconCompact,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minimumButtonSize,
          shape: buttonShape,
          padding: buttonPadding,
          iconSize: AppSizes.iconCompact,
          foregroundColor: colors.textPrimary,
        ).copyWith(
          side: WidgetStateBorderSide.resolveWith(
            (Set<WidgetState> states) => BorderSide(
              color: states.contains(WidgetState.disabled) ? colors.borderDisabled : colors.borderStrong,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minimumButtonSize, shape: buttonShape, iconSize: AppSizes.iconCompact),
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
        fillColor: colors.bgSurface,
        hintStyle: AppTypography.mobileBodyM.copyWith(color: colors.textTertiary),
        border: fieldBorder(colors.borderStrong),
        enabledBorder: fieldBorder(colors.borderStrong),
        focusedBorder: fieldBorder(colors.borderFocus, width: AppSizes.strokeThick),
        errorBorder: fieldBorder(colors.borderDanger),
        focusedErrorBorder: fieldBorder(colors.borderDanger, width: AppSizes.strokeThick),
        disabledBorder: fieldBorder(colors.borderDisabled),
      ),
      // `AppCheckTile` dibuja la casilla más grande: el borde y el radio se
      // compensan para que queden como en el diseño.
      checkboxTheme: CheckboxThemeData(
        side: WidgetStateBorderSide.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? BorderSide.none : BorderSide(color: colors.borderStrong, width: 0.75),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.extraSmall * 0.75)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.s300),
        horizontalTitleGap: AppSpacing.s300,
        minLeadingWidth: AppSizes.iconMedium,
        minTileHeight: AppSizes.minTouchTarget,
        minVerticalPadding: AppSpacing.s300,
        iconColor: colors.textSecondary,
        titleTextStyle: AppTypography.mobileBodyM.copyWith(color: colors.textPrimary),
        subtitleTextStyle: AppTypography.mobileBodyS.copyWith(color: colors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: colors.bgBrandSubtle,
        disabledColor: Colors.transparent,
        checkmarkColor: colors.textBrand,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s300, vertical: AppSpacing.s150),
        labelStyle: AppTypography.mobileLabelM.copyWith(
          color: WidgetStateColor.resolveWith(
            (Set<WidgetState> states) => states.contains(WidgetState.selected) ? colors.textBrand : colors.textPrimary,
          ),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (Set<WidgetState> states) => BorderSide(
            color: states.contains(WidgetState.selected) ? colors.borderBrand : colors.borderDefault,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.bgSurfaceRaised,
        contentTextStyle: AppTypography.mobileBodyS.copyWith(color: colors.textPrimary),
        actionTextColor: colors.textBrand,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          side: BorderSide(color: colors.borderDefault),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgSurfaceRaised,
        surfaceTintColor: Colors.transparent,
        barrierColor: colors.bgScrim,
        elevation: AppSpacing.md,
        shadowColor: colors.shadowStrong,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        titleTextStyle: AppTypography.mobileH4.copyWith(color: colors.textPrimary),
        contentTextStyle: AppTypography.mobileBodyS.copyWith(color: colors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.extraLarge)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgSurfaceRaised,
        modalBackgroundColor: colors.bgSurfaceRaised,
        modalBarrierColor: colors.bgScrim,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.extraLarge)),
        ),
      ),
    );
  }
}
