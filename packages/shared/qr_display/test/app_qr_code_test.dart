import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_display/qr_display.dart';

Future<void> pumpQr(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

QrPainter painterOf(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.descendant(of: find.byType(AppQrCode), matching: find.byType(CustomPaint))).painter!
        as QrPainter;

void main() {
  testWidgets('se anuncia como imagen con su etiqueta, sin leer el contenido', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await pumpQr(tester, const AppQrCode(data: 'secreto', semanticLabel: 'Código para unirse', size: 200));

    expect(find.bySemanticsLabel('Código para unirse'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('secreto')), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Código para unirse')),
      matchesSemantics(label: 'Código para unirse', isImage: true),
    );
    semantics.dispose();
  });

  testWidgets('con size es un cuadrado de ese lado; sin él, ocupa el ancho', (WidgetTester tester) async {
    await pumpQr(tester, const AppQrCode(data: 'hola', semanticLabel: 'QR', size: 120));
    expect(tester.getSize(find.byType(AppQrCode)), const Size(120, 120));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Align(alignment: Alignment.topLeft, child: SizedBox(width: 300, child: AppQrCode(data: 'hola', semanticLabel: 'QR'))))),
    );
    expect(tester.getSize(find.byType(AppQrCode)), const Size(300, 300));
  });

  testWidgets('pinta el fondo y luego los módulos oscuros con sus colores', (WidgetTester tester) async {
    await pumpQr(
      tester,
      const AppQrCode(
        data: 'hola',
        semanticLabel: 'QR',
        size: 116,
        color: Color(0xFF112233),
        backgroundColor: Color(0xFFFFEEDD),
      ),
    );

    // 21 módulos + 2 × 4 de margen = 29 módulos de 4 px. El primer patrón de
    // posición empieza en (16, 16) y ocupa 7 módulos (28 px).
    expect(
      find.descendant(of: find.byType(AppQrCode), matching: find.byType(CustomPaint)),
      paints
        ..rect(rect: const Rect.fromLTWH(0, 0, 116, 116), color: const Color(0xFFFFEEDD))
        ..path(
          color: const Color(0xFF112233),
          includes: <Offset>[const Offset(18, 18), const Offset(42, 18), const Offset(30, 30)],
          excludes: <Offset>[const Offset(2, 2), const Offset(22, 22), const Offset(114, 114)],
        ),
    );
  });

  testWidgets('sin margen, los módulos llegan al borde', (WidgetTester tester) async {
    await pumpQr(tester, const AppQrCode(data: 'hola', semanticLabel: 'QR', size: 84, quietZone: 0));

    expect(
      find.descendant(of: find.byType(AppQrCode), matching: find.byType(CustomPaint)),
      paints
        ..rect()
        ..path(includes: <Offset>[const Offset(1, 1)], excludes: <Offset>[const Offset(5, 5)]),
    );
  });

  testWidgets('vuelve a codificar solo si cambian los datos o el nivel', (WidgetTester tester) async {
    await pumpQr(tester, const AppQrCode(data: 'hola', semanticLabel: 'QR'));
    final QrMatrix first = painterOf(tester).matrix;

    await pumpQr(tester, const AppQrCode(data: 'hola', semanticLabel: 'Otro', color: Color(0xFF333333)));
    expect(painterOf(tester).matrix, same(first));

    await pumpQr(tester, const AppQrCode(data: 'adiós', semanticLabel: 'QR'));
    final QrMatrix second = painterOf(tester).matrix;
    expect(second, isNot(same(first)));

    await pumpQr(tester, const AppQrCode(data: 'adiós', semanticLabel: 'QR', errorLevel: QrErrorLevel.high));
    expect(painterOf(tester).matrix, isNot(same(second)));
  });

  test('QrPainter repinta cuando cambia algo de lo que dibuja', () {
    final QrMatrix matrix = QrMatrix.encode('hola');
    final QrPainter painter = QrPainter(matrix: matrix);

    expect(painter.shouldRepaint(QrPainter(matrix: matrix)), isFalse);
    expect(painter.shouldRepaint(QrPainter(matrix: QrMatrix.encode('hola'))), isTrue);
    expect(painter.shouldRepaint(QrPainter(matrix: matrix, color: const Color(0xFF111111))), isTrue);
    expect(painter.shouldRepaint(QrPainter(matrix: matrix, backgroundColor: const Color(0xFF111111))), isTrue);
    expect(painter.shouldRepaint(QrPainter(matrix: matrix, quietZone: 2)), isTrue);
  });

  testWidgets('en un lienzo no cuadrado se centra', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 200, height: 116, child: CustomPaint(painter: QrPainter(matrix: QrMatrix.encode('hola'))))),
      ),
    );

    expect(find.byType(CustomPaint), paints..rect(rect: const Rect.fromLTWH(42, 0, 116, 116)));
  });
}
