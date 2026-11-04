import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colores semánticos del sistema de diseño de Figma (colecciones `Theme Light`
/// y `Theme Dark`): `bg/surface-raised` es `bgSurfaceRaised`. Cubren lo que
/// `ColorScheme` no tiene, como los estados de éxito e información o los de
/// hover y pressed. Se leen del tema con [AppThemeColors.of].
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSurfaceRaised,
    required this.bgSurfaceSunken,
    required this.bgSurfaceHover,
    required this.bgSurfacePressed,
    required this.bgBrandSubtle,
    required this.bgBrandMuted,
    required this.bgDisabled,
    required this.bgDangerSubtle,
    required this.bgSuccessSubtle,
    required this.bgWarningSubtle,
    required this.bgInfoSubtle,
    required this.bgScrim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textBrand,
    required this.textOnBrand,
    required this.textOnBrandSubtle,
    required this.textOnDanger,
    required this.textDanger,
    required this.textSuccess,
    required this.textWarning,
    required this.textInfo,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderHover,
    required this.borderBrand,
    required this.borderBrandSubtle,
    required this.borderFocus,
    required this.borderDanger,
    required this.borderSuccess,
    required this.borderDisabled,
    required this.actionPrimaryDefault,
    required this.actionPrimaryHover,
    required this.actionPrimaryPressed,
    required this.actionSecondaryDefault,
    required this.actionSecondaryHover,
    required this.actionSecondaryPressed,
    required this.actionGhostHover,
    required this.actionGhostPressed,
    required this.actionDangerDefault,
    required this.actionDangerHover,
    required this.actionDangerPressed,
    required this.actionDisabled,
    required this.shadowSoft,
    required this.shadowStrong,
  });

  static const AppThemeColors light = AppThemeColors(
    bgCanvas: AppColors.neutral50,
    bgSurface: AppColors.neutral0,
    bgSurfaceRaised: AppColors.neutral0,
    bgSurfaceSunken: AppColors.neutral100,
    bgSurfaceHover: AppColors.neutral50,
    bgSurfacePressed: AppColors.neutral100,
    bgBrandSubtle: AppColors.violet50,
    bgBrandMuted: AppColors.violet100,
    bgDisabled: AppColors.neutral100,
    bgDangerSubtle: AppColors.red50,
    bgSuccessSubtle: AppColors.green50,
    bgWarningSubtle: AppColors.amber100,
    bgInfoSubtle: AppColors.blue100,
    bgScrim: AppColors.alphaBlack40,
    textPrimary: AppColors.neutral900,
    textSecondary: AppColors.neutral600,
    textTertiary: AppColors.neutral500,
    textDisabled: AppColors.neutral400,
    textBrand: AppColors.violet700,
    textOnBrand: AppColors.neutral0,
    textOnBrandSubtle: AppColors.violet800,
    textOnDanger: AppColors.neutral0,
    textDanger: AppColors.red700,
    textSuccess: AppColors.green700,
    textWarning: AppColors.amber700,
    textInfo: AppColors.blue700,
    borderDefault: AppColors.neutral200,
    borderStrong: AppColors.neutral450,
    borderHover: AppColors.neutral600,
    borderBrand: AppColors.violet700,
    borderBrandSubtle: AppColors.violet200,
    borderFocus: AppColors.violet600,
    borderDanger: AppColors.red600,
    borderSuccess: AppColors.green600,
    borderDisabled: AppColors.neutral200,
    actionPrimaryDefault: AppColors.violet700,
    actionPrimaryHover: AppColors.violet800,
    actionPrimaryPressed: AppColors.violet900,
    actionSecondaryDefault: AppColors.violet100,
    actionSecondaryHover: AppColors.violet200,
    actionSecondaryPressed: AppColors.violet300,
    actionGhostHover: AppColors.violet50,
    actionGhostPressed: AppColors.violet100,
    actionDangerDefault: AppColors.red600,
    actionDangerHover: AppColors.red700,
    actionDangerPressed: AppColors.red800,
    actionDisabled: AppColors.neutral200,
    shadowSoft: AppColors.alphaViolet8,
    shadowStrong: AppColors.alphaViolet16,
  );

  static const AppThemeColors dark = AppThemeColors(
    bgCanvas: AppColors.neutral950,
    bgSurface: AppColors.neutral900,
    bgSurfaceRaised: AppColors.neutral800,
    bgSurfaceSunken: AppColors.neutral950,
    bgSurfaceHover: AppColors.neutral800,
    bgSurfacePressed: AppColors.neutral700,
    bgBrandSubtle: AppColors.violet950,
    bgBrandMuted: AppColors.violet900,
    bgDisabled: AppColors.neutral800,
    bgDangerSubtle: AppColors.red950,
    bgSuccessSubtle: AppColors.green950,
    bgWarningSubtle: AppColors.amber950,
    bgInfoSubtle: AppColors.blue950,
    bgScrim: AppColors.alphaBlack60,
    textPrimary: AppColors.neutral100,
    textSecondary: AppColors.neutral400,
    textTertiary: AppColors.neutral450,
    textDisabled: AppColors.neutral600,
    textBrand: AppColors.violet300,
    textOnBrand: AppColors.violet1000,
    textOnBrandSubtle: AppColors.violet200,
    textOnDanger: AppColors.red950,
    textDanger: AppColors.red400,
    textSuccess: AppColors.green400,
    textWarning: AppColors.amber400,
    textInfo: AppColors.blue400,
    borderDefault: AppColors.neutral700,
    borderStrong: AppColors.neutral500,
    borderHover: AppColors.neutral400,
    borderBrand: AppColors.violet400,
    borderBrandSubtle: AppColors.violet800,
    borderFocus: AppColors.violet300,
    borderDanger: AppColors.red400,
    borderSuccess: AppColors.green400,
    borderDisabled: AppColors.neutral700,
    actionPrimaryDefault: AppColors.violet400,
    actionPrimaryHover: AppColors.violet300,
    actionPrimaryPressed: AppColors.violet200,
    actionSecondaryDefault: AppColors.violet900,
    actionSecondaryHover: AppColors.violet800,
    actionSecondaryPressed: AppColors.violet700,
    actionGhostHover: AppColors.violet950,
    actionGhostPressed: AppColors.violet900,
    actionDangerDefault: AppColors.red400,
    actionDangerHover: AppColors.red300,
    actionDangerPressed: AppColors.red100,
    actionDisabled: AppColors.neutral700,
    shadowSoft: AppColors.alphaBlack40,
    shadowStrong: AppColors.alphaBlack60,
  );

  static AppThemeColors of(BuildContext context) => Theme.of(context).extension<AppThemeColors>()!;

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceRaised;
  final Color bgSurfaceSunken;
  final Color bgSurfaceHover;
  final Color bgSurfacePressed;
  final Color bgBrandSubtle;
  final Color bgBrandMuted;
  final Color bgDisabled;
  final Color bgDangerSubtle;
  final Color bgSuccessSubtle;
  final Color bgWarningSubtle;
  final Color bgInfoSubtle;
  final Color bgScrim;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textBrand;
  final Color textOnBrand;
  final Color textOnBrandSubtle;
  final Color textOnDanger;
  final Color textDanger;
  final Color textSuccess;
  final Color textWarning;
  final Color textInfo;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderHover;
  final Color borderBrand;
  final Color borderBrandSubtle;
  final Color borderFocus;
  final Color borderDanger;
  final Color borderSuccess;
  final Color borderDisabled;
  final Color actionPrimaryDefault;
  final Color actionPrimaryHover;
  final Color actionPrimaryPressed;
  final Color actionSecondaryDefault;
  final Color actionSecondaryHover;
  final Color actionSecondaryPressed;
  final Color actionGhostHover;
  final Color actionGhostPressed;
  final Color actionDangerDefault;
  final Color actionDangerHover;
  final Color actionDangerPressed;
  final Color actionDisabled;
  final Color shadowSoft;
  final Color shadowStrong;

  @override
  AppThemeColors copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSurfaceRaised,
    Color? bgSurfaceSunken,
    Color? bgSurfaceHover,
    Color? bgSurfacePressed,
    Color? bgBrandSubtle,
    Color? bgBrandMuted,
    Color? bgDisabled,
    Color? bgDangerSubtle,
    Color? bgSuccessSubtle,
    Color? bgWarningSubtle,
    Color? bgInfoSubtle,
    Color? bgScrim,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? textBrand,
    Color? textOnBrand,
    Color? textOnBrandSubtle,
    Color? textOnDanger,
    Color? textDanger,
    Color? textSuccess,
    Color? textWarning,
    Color? textInfo,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderHover,
    Color? borderBrand,
    Color? borderBrandSubtle,
    Color? borderFocus,
    Color? borderDanger,
    Color? borderSuccess,
    Color? borderDisabled,
    Color? actionPrimaryDefault,
    Color? actionPrimaryHover,
    Color? actionPrimaryPressed,
    Color? actionSecondaryDefault,
    Color? actionSecondaryHover,
    Color? actionSecondaryPressed,
    Color? actionGhostHover,
    Color? actionGhostPressed,
    Color? actionDangerDefault,
    Color? actionDangerHover,
    Color? actionDangerPressed,
    Color? actionDisabled,
    Color? shadowSoft,
    Color? shadowStrong,
  }) =>
      AppThemeColors(
        bgCanvas: bgCanvas ?? this.bgCanvas,
        bgSurface: bgSurface ?? this.bgSurface,
        bgSurfaceRaised: bgSurfaceRaised ?? this.bgSurfaceRaised,
        bgSurfaceSunken: bgSurfaceSunken ?? this.bgSurfaceSunken,
        bgSurfaceHover: bgSurfaceHover ?? this.bgSurfaceHover,
        bgSurfacePressed: bgSurfacePressed ?? this.bgSurfacePressed,
        bgBrandSubtle: bgBrandSubtle ?? this.bgBrandSubtle,
        bgBrandMuted: bgBrandMuted ?? this.bgBrandMuted,
        bgDisabled: bgDisabled ?? this.bgDisabled,
        bgDangerSubtle: bgDangerSubtle ?? this.bgDangerSubtle,
        bgSuccessSubtle: bgSuccessSubtle ?? this.bgSuccessSubtle,
        bgWarningSubtle: bgWarningSubtle ?? this.bgWarningSubtle,
        bgInfoSubtle: bgInfoSubtle ?? this.bgInfoSubtle,
        bgScrim: bgScrim ?? this.bgScrim,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        textDisabled: textDisabled ?? this.textDisabled,
        textBrand: textBrand ?? this.textBrand,
        textOnBrand: textOnBrand ?? this.textOnBrand,
        textOnBrandSubtle: textOnBrandSubtle ?? this.textOnBrandSubtle,
        textOnDanger: textOnDanger ?? this.textOnDanger,
        textDanger: textDanger ?? this.textDanger,
        textSuccess: textSuccess ?? this.textSuccess,
        textWarning: textWarning ?? this.textWarning,
        textInfo: textInfo ?? this.textInfo,
        borderDefault: borderDefault ?? this.borderDefault,
        borderStrong: borderStrong ?? this.borderStrong,
        borderHover: borderHover ?? this.borderHover,
        borderBrand: borderBrand ?? this.borderBrand,
        borderBrandSubtle: borderBrandSubtle ?? this.borderBrandSubtle,
        borderFocus: borderFocus ?? this.borderFocus,
        borderDanger: borderDanger ?? this.borderDanger,
        borderSuccess: borderSuccess ?? this.borderSuccess,
        borderDisabled: borderDisabled ?? this.borderDisabled,
        actionPrimaryDefault: actionPrimaryDefault ?? this.actionPrimaryDefault,
        actionPrimaryHover: actionPrimaryHover ?? this.actionPrimaryHover,
        actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
        actionSecondaryDefault: actionSecondaryDefault ?? this.actionSecondaryDefault,
        actionSecondaryHover: actionSecondaryHover ?? this.actionSecondaryHover,
        actionSecondaryPressed: actionSecondaryPressed ?? this.actionSecondaryPressed,
        actionGhostHover: actionGhostHover ?? this.actionGhostHover,
        actionGhostPressed: actionGhostPressed ?? this.actionGhostPressed,
        actionDangerDefault: actionDangerDefault ?? this.actionDangerDefault,
        actionDangerHover: actionDangerHover ?? this.actionDangerHover,
        actionDangerPressed: actionDangerPressed ?? this.actionDangerPressed,
        actionDisabled: actionDisabled ?? this.actionDisabled,
        shadowSoft: shadowSoft ?? this.shadowSoft,
        shadowStrong: shadowStrong ?? this.shadowStrong,
      );

  @override
  AppThemeColors lerp(covariant ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceRaised: Color.lerp(bgSurfaceRaised, other.bgSurfaceRaised, t)!,
      bgSurfaceSunken: Color.lerp(bgSurfaceSunken, other.bgSurfaceSunken, t)!,
      bgSurfaceHover: Color.lerp(bgSurfaceHover, other.bgSurfaceHover, t)!,
      bgSurfacePressed: Color.lerp(bgSurfacePressed, other.bgSurfacePressed, t)!,
      bgBrandSubtle: Color.lerp(bgBrandSubtle, other.bgBrandSubtle, t)!,
      bgBrandMuted: Color.lerp(bgBrandMuted, other.bgBrandMuted, t)!,
      bgDisabled: Color.lerp(bgDisabled, other.bgDisabled, t)!,
      bgDangerSubtle: Color.lerp(bgDangerSubtle, other.bgDangerSubtle, t)!,
      bgSuccessSubtle: Color.lerp(bgSuccessSubtle, other.bgSuccessSubtle, t)!,
      bgWarningSubtle: Color.lerp(bgWarningSubtle, other.bgWarningSubtle, t)!,
      bgInfoSubtle: Color.lerp(bgInfoSubtle, other.bgInfoSubtle, t)!,
      bgScrim: Color.lerp(bgScrim, other.bgScrim, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      textOnBrandSubtle: Color.lerp(textOnBrandSubtle, other.textOnBrandSubtle, t)!,
      textOnDanger: Color.lerp(textOnDanger, other.textOnDanger, t)!,
      textDanger: Color.lerp(textDanger, other.textDanger, t)!,
      textSuccess: Color.lerp(textSuccess, other.textSuccess, t)!,
      textWarning: Color.lerp(textWarning, other.textWarning, t)!,
      textInfo: Color.lerp(textInfo, other.textInfo, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderHover: Color.lerp(borderHover, other.borderHover, t)!,
      borderBrand: Color.lerp(borderBrand, other.borderBrand, t)!,
      borderBrandSubtle: Color.lerp(borderBrandSubtle, other.borderBrandSubtle, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderDanger: Color.lerp(borderDanger, other.borderDanger, t)!,
      borderSuccess: Color.lerp(borderSuccess, other.borderSuccess, t)!,
      borderDisabled: Color.lerp(borderDisabled, other.borderDisabled, t)!,
      actionPrimaryDefault: Color.lerp(actionPrimaryDefault, other.actionPrimaryDefault, t)!,
      actionPrimaryHover: Color.lerp(actionPrimaryHover, other.actionPrimaryHover, t)!,
      actionPrimaryPressed: Color.lerp(actionPrimaryPressed, other.actionPrimaryPressed, t)!,
      actionSecondaryDefault: Color.lerp(actionSecondaryDefault, other.actionSecondaryDefault, t)!,
      actionSecondaryHover: Color.lerp(actionSecondaryHover, other.actionSecondaryHover, t)!,
      actionSecondaryPressed: Color.lerp(actionSecondaryPressed, other.actionSecondaryPressed, t)!,
      actionGhostHover: Color.lerp(actionGhostHover, other.actionGhostHover, t)!,
      actionGhostPressed: Color.lerp(actionGhostPressed, other.actionGhostPressed, t)!,
      actionDangerDefault: Color.lerp(actionDangerDefault, other.actionDangerDefault, t)!,
      actionDangerHover: Color.lerp(actionDangerHover, other.actionDangerHover, t)!,
      actionDangerPressed: Color.lerp(actionDangerPressed, other.actionDangerPressed, t)!,
      actionDisabled: Color.lerp(actionDisabled, other.actionDisabled, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
      shadowStrong: Color.lerp(shadowStrong, other.shadowStrong, t)!,
    );
  }
}
