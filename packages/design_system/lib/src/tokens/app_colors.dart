import 'package:flutter/widgets.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF26A69A);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// La spec tenía `Color(0xD32F2F)`, sin canal alfa (casi transparente).
  static const Color error = Color(0xFFD32F2F);
}
