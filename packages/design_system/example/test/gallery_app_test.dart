import 'package:design_system_example/src/gallery_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la galería cambia de idioma, tema y escala sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const GalleryApp());
    // La galería contiene otros Scrollable (campos de texto, estados).
    final Finder galleryList = find.byType(Scrollable).first;

    await tester.tap(find.text('Tema oscuro'));
    await tester.drag(find.byType(Slider), const Offset(1000, 0));
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Escala de texto: 200 %'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Tema oscuro'))).brightness, Brightness.dark);

    // Los textos comunes vienen de core_ui y ya están en inglés.
    // Hay indicadores de carga animados: pumpAndSettle no terminaría.
    await tester.scrollUntilVisible(find.text('Botones'), 300, scrollable: galleryList);
    await tester.pump();
    expect(find.text('Save'), findsWidgets);
    expect(find.text('Guardar'), findsNothing);

    // Recorre toda la galería al 200 % en tema oscuro sin desbordes.
    await tester.scrollUntilVisible(find.text('Estados'), 300, scrollable: galleryList);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Arrastrar hacia arriba caería sobre el scroll interno de AppStatusView.
    tester.state<ScrollableState>(galleryList).position.jumpTo(0);
    await tester.pump();
    await tester.tap(find.text('ES'));
    await tester.pump();
    expect(find.text('Escala de texto: 200 %'), findsOneWidget);
  });
}
