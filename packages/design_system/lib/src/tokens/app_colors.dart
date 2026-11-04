import 'package:flutter/widgets.dart';

/// Colores primitivos del sistema de diseño de Figma (colección `Primitives`),
/// con los mismos nombres. Los componentes no los usan directamente: leen los
/// colores del tema, que `AppTheme` asigna en claro y en oscuro.
abstract final class AppColors {
  static const Color violet50 = Color(0xFFF5F3FF);
  static const Color violet100 = Color(0xFFEDE9FE);
  static const Color violet200 = Color(0xFFDDD6FE);
  static const Color violet300 = Color(0xFFC4B5FD);
  static const Color violet400 = Color(0xFFA78BFA);
  static const Color violet500 = Color(0xFF8B5CF6);
  static const Color violet600 = Color(0xFF7C3AED);
  static const Color violet700 = Color(0xFF6D28D9);
  static const Color violet800 = Color(0xFF5B21B6);
  static const Color violet900 = Color(0xFF4C1D95);
  static const Color violet950 = Color(0xFF2E1065);
  static const Color violet1000 = Color(0xFF1E0E45);

  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFAFC);
  static const Color neutral100 = Color(0xFFF4F3F8);
  static const Color neutral200 = Color(0xFFE7E5EF);
  static const Color neutral300 = Color(0xFFD3D0DF);
  static const Color neutral400 = Color(0xFFA5A1B8);
  static const Color neutral450 = Color(0xFF8C889E);
  static const Color neutral500 = Color(0xFF767289);
  static const Color neutral600 = Color(0xFF5A566C);
  static const Color neutral700 = Color(0xFF454154);
  static const Color neutral800 = Color(0xFF2C2939);
  static const Color neutral900 = Color(0xFF1B1926);
  static const Color neutral950 = Color(0xFF100E18);
  static const Color neutral1000 = Color(0xFF000000);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red400 = Color(0xFFF87171);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red950 = Color(0xFF3B0A0A);

  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);
  static const Color green950 = Color(0xFF052E16);

  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber950 = Color(0xFF451A03);

  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue950 = Color(0xFF172554);

  static const Color alphaViolet8 = Color(0x141E0E45);
  static const Color alphaViolet16 = Color(0x291E0E45);
  static const Color alphaBlack40 = Color(0x66000000);
  static const Color alphaBlack60 = Color(0x99000000);
}
