/// Márgenes, retículas y anchos de referencia (`layout/*` en Figma).
abstract final class AppLayout {
  static const double marginMobile = 16.0;
  static const double marginTablet = 24.0;
  static const double marginDesktop = 32.0;

  static const double gutterMobile = 16.0;
  static const double gutterDesktop = 24.0;

  static const double containerMax = 1200.0;

  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;

  static const double frameMobile = 390.0;
  static const double frameDesktop = 1440.0;
}
