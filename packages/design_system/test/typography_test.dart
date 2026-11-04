import 'dart:convert';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/gallery.dart';

/// En su propio archivo porque Inter, una vez cargada, sigue en memoria para los
/// tests siguientes, y `textContrastGuideline` mide píxeles: a 12 px el suavizado
/// de una fuente real no llega al color puro y da un contraste falso.
void main() {
  const String family = 'packages/design_system/Inter';

  /// Aquí el paquete es la raíz, así que el manifiesto dice `Inter`. En quien
  /// lo consume es `packages/design_system/Inter` (ver el test de la galería).
  Future<List<Map<String, dynamic>>> interFonts() async {
    final List<dynamic> manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
    final Map<String, dynamic> inter = manifest
        .cast<Map<String, dynamic>>()
        .firstWhere((Map<String, dynamic> font) => font['family'] == AppTypography.fontFamily);
    return (inter['fonts'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> loadInter() async {
    final FontLoader loader = FontLoader(family);
    for (final Map<String, dynamic> font in await interFonts()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }

  test('el paquete declara Inter con los cuatro pesos', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final Iterable<int> weights = (await interFonts()).map((Map<String, dynamic> font) => font['weight'] as int);

    expect(weights, unorderedEquals(<int>[400, 500, 600, 700]));
  });

  test('todos los estilos del tema usan Inter, en claro y en oscuro', () {
    for (final ThemeData theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      final TextTheme text = theme.textTheme;
      final List<TextStyle?> styles = <TextStyle?>[
        text.displayLarge, text.displayMedium, text.displaySmall,
        text.headlineLarge, text.headlineMedium, text.headlineSmall,
        text.titleLarge, text.titleMedium, text.titleSmall,
        text.bodyLarge, text.bodyMedium, text.bodySmall,
        text.labelLarge, text.labelMedium, text.labelSmall,
      ];

      for (final TextStyle? style in styles) {
        expect(style?.fontFamily, family);
        expect(style?.color, isNotNull);
      }
    }
  });

  test('el tema aplica los estilos del lienzo', () {
    final TextTheme text = AppTheme.light.textTheme;

    expect(text.titleLarge?.fontSize, 18);
    expect(text.titleLarge?.fontWeight, FontWeight.w600);
    expect(text.bodyLarge?.fontSize, 16);
    expect(text.bodyLarge?.height, 1.5);
    expect(text.bodyMedium?.fontSize, 14);
    expect(text.bodySmall?.fontSize, 12);
    expect(text.labelLarge?.fontWeight, FontWeight.w600);
  });

  test('el tema no conserva el espaciado entre letras de Material', () {
    final TextTheme text = AppTheme.light.textTheme;

    for (final TextStyle? style in <TextStyle?>[
      text.titleMedium, text.titleSmall,
      text.bodyLarge, text.bodyMedium, text.bodySmall,
      text.labelLarge, text.labelMedium, text.labelSmall,
    ]) {
      expect(style?.letterSpacing, 0);
    }
  });

  testWidgets('la fuente carga y sustituye a la de pruebas', (WidgetTester tester) async {
    const String sample = 'Lista de la compra';
    const TextStyle fallback = TextStyle(fontFamily: 'SinFuente', fontSize: 16);
    await tester.runAsync(loadInter);

    double widthOf(TextStyle style) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: sample, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final double width = painter.width;
      painter.dispose();
      return width;
    }

    expect(widthOf(AppTypography.mobileBodyM), isNot(closeTo(widthOf(fallback), 0.1)));
    expect(
      widthOf(AppTypography.mobileBodyM.copyWith(fontWeight: FontWeight.w700)),
      greaterThan(widthOf(AppTypography.mobileBodyM)),
    );
  });

  testWidgets('los componentes no desbordan con Inter y el texto al 200 %', (WidgetTester tester) async {
    await tester.runAsync(loadInter);
    tester.view.physicalSize = const Size(360, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(gallery(), textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
