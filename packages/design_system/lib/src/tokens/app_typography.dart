import 'package:flutter/widgets.dart';

/// Tipografía del sistema de diseño de Figma (colección `Typography` y estilos
/// `Web/*` y `Mobile/*`). La fuente aún no viene incluida en el paquete: sin
/// ella, Flutter usa la del sistema. El interlineado se expresa como factor del
/// tamaño y el espaciado entre letras, en píxeles, porque en Figma es un
/// porcentaje.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static const double size12 = 12.0;
  static const double size14 = 14.0;
  static const double size16 = 16.0;
  static const double size17 = 17.0;
  static const double size18 = 18.0;
  static const double size20 = 20.0;
  static const double size22 = 22.0;
  static const double size24 = 24.0;
  static const double size28 = 28.0;
  static const double size32 = 32.0;
  static const double size40 = 40.0;
  static const double size56 = 56.0;

  static const double lineHeight16 = 16.0;
  static const double lineHeight20 = 20.0;
  static const double lineHeight24 = 24.0;
  static const double lineHeight28 = 28.0;
  static const double lineHeight32 = 32.0;
  static const double lineHeight36 = 36.0;
  static const double lineHeight40 = 40.0;
  static const double lineHeight48 = 48.0;
  static const double lineHeight64 = 64.0;

  static const TextStyle webDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: size56,
    height: lineHeight64 / size56,
    fontWeight: FontWeight.w700,
    letterSpacing: size56 * -0.02,
  );
  static const TextStyle webH1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size40,
    height: lineHeight48 / size40,
    fontWeight: FontWeight.w700,
    letterSpacing: size40 * -0.015,
  );
  static const TextStyle webH2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size32,
    height: lineHeight40 / size32,
    fontWeight: FontWeight.w600,
    letterSpacing: size32 * -0.01,
  );
  static const TextStyle webH3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size24,
    height: lineHeight32 / size24,
    fontWeight: FontWeight.w600,
    letterSpacing: size24 * -0.005,
  );
  static const TextStyle webH4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size20,
    height: lineHeight28 / size20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle webBodyL = TextStyle(
    fontFamily: fontFamily,
    fontSize: size18,
    height: lineHeight28 / size18,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle webBodyM = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    height: lineHeight24 / size16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle webBodyS = TextStyle(
    fontFamily: fontFamily,
    fontSize: size14,
    height: lineHeight20 / size14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle webLabelL = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    height: lineHeight24 / size16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle webLabelM = TextStyle(
    fontFamily: fontFamily,
    fontSize: size14,
    height: lineHeight20 / size14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle webLabelS = TextStyle(
    fontFamily: fontFamily,
    fontSize: size12,
    height: lineHeight16 / size12,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle webCaption = TextStyle(
    fontFamily: fontFamily,
    fontSize: size12,
    height: lineHeight16 / size12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle mobileDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: size40,
    height: lineHeight48 / size40,
    fontWeight: FontWeight.w700,
    letterSpacing: size40 * -0.015,
  );
  static const TextStyle mobileH1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size32,
    height: lineHeight40 / size32,
    fontWeight: FontWeight.w700,
    letterSpacing: size32 * -0.01,
  );
  static const TextStyle mobileH2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size28,
    height: lineHeight36 / size28,
    fontWeight: FontWeight.w600,
    letterSpacing: size28 * -0.005,
  );
  static const TextStyle mobileH3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size22,
    height: lineHeight28 / size22,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle mobileH4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: size18,
    height: lineHeight24 / size18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle mobileBodyL = TextStyle(
    fontFamily: fontFamily,
    fontSize: size17,
    height: lineHeight24 / size17,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle mobileBodyM = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    height: lineHeight24 / size16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle mobileBodyS = TextStyle(
    fontFamily: fontFamily,
    fontSize: size14,
    height: lineHeight20 / size14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle mobileLabelL = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    height: lineHeight24 / size16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle mobileLabelM = TextStyle(
    fontFamily: fontFamily,
    fontSize: size14,
    height: lineHeight20 / size14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle mobileLabelS = TextStyle(
    fontFamily: fontFamily,
    fontSize: size12,
    height: lineHeight16 / size12,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle mobileCaption = TextStyle(
    fontFamily: fontFamily,
    fontSize: size12,
    height: lineHeight16 / size12,
    fontWeight: FontWeight.w400,
  );
}
