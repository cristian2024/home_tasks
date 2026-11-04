/// Tamaños. Los iconos no coinciden con los de Figma: `size/icon-sm` es
/// [iconSmall], `size/icon-md` es [iconCompact] y `size/icon-lg` es [iconMedium].
abstract final class AppSizes {
  /// Área táctil mínima (WCAG 2.1 AA, spec §14.2).
  static const double minTouchTarget = 48.0;

  /// `size/touch-target` de Figma, el mínimo de iOS. En la app manda
  /// [minTouchTarget], que también cumple el de Android.
  static const double touchTarget = 44.0;

  static const double controlSmall = 32.0;
  static const double controlMedium = 40.0;
  static const double controlLarge = 48.0;

  static const double iconSmall = 16.0;
  static const double iconCompact = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 48.0;

  static const double strokeThin = 1.0;
  static const double strokeThick = 2.0;
}
