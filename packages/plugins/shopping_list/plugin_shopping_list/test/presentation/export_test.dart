import 'package:core_share/core_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  tearDown(() => harness.dispose());

  Future<void> pumpWithItems(WidgetTester tester, {bool share = true}) async {
    harness = PluginHarness(share: share);
    await harness.initialize();
    final ShoppingCategory food = await harness.category('food');
    await harness.deps.createItem(name: 'Huevos', quantity: '2 docenas', urgency: Urgency.high, categoryIds: <String>[
      food.id,
    ]);
    await harness.deps.createItem(name: 'Pilas');
    await harness.pump(tester);
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Exportar'));
    await tester.pumpAndSettle();
  }

  const String whatsAppText = '*Lista de compras*\n'
      '\n'
      '*Comida*\n'
      '- *Huevos* — 2 docenas\n'
      '\n'
      '*Sin categoría*\n'
      '- Pilas\n'
      '\n'
      '_Exportada el 28/10/2026_';

  testWidgets('envía la lista por WhatsApp agrupada por categoría', (WidgetTester tester) async {
    await pumpWithItems(tester);
    await openSheet(tester);

    expect(find.text('Qué exportar'), findsNothing);
    await tester.tap(find.text('Enviar por WhatsApp'));
    await tester.pumpAndSettle();

    expect(harness.share.whatsAppMessages, <String>[whatsAppText]);
    expect(find.text('Exportar la lista'), findsNothing);
  });

  testWidgets('sin WhatsApp lo avisa', (WidgetTester tester) async {
    await pumpWithItems(tester);
    harness.share.whatsAppInstalled = false;
    await openSheet(tester);

    await tester.tap(find.text('Enviar por WhatsApp'));
    await tester.pumpAndSettle();

    expect(find.text('WhatsApp no está instalado. Usa «Compartir texto».'), findsOneWidget);
  });

  testWidgets('comparte el texto y el archivo Markdown, y guarda el archivo', (WidgetTester tester) async {
    await pumpWithItems(tester);

    await openSheet(tester);
    await tester.tap(find.text('Compartir texto'));
    await tester.pumpAndSettle();
    expect(harness.share.sharedTexts, <String>[whatsAppText]);

    await openSheet(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Urgencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir archivo .md'));
    await tester.pumpAndSettle();
    final ShareFile file = harness.share.sharedFiles.single;
    expect(file.fileName, 'lista-de-compras.md');
    expect(file.content, startsWith('# Lista de compras\n\n## Alta\n\n- **Huevos** — 2 docenas (Comida)\n'));

    await openSheet(tester);
    await tester.tap(find.text('Guardar archivo .md'));
    await tester.pumpAndSettle();
    expect(harness.share.savedFiles, hasLength(1));
    expect(find.text('Archivo guardado.'), findsOneWidget);

    harness.share.userCancelsSave = true;
    await openSheet(tester);
    await tester.tap(find.text('Guardar archivo .md'));
    await tester.pumpAndSettle();
    expect(harness.share.savedFiles, hasLength(1));
  });

  testWidgets('con filtros ofrece exportar solo lo filtrado', (WidgetTester tester) async {
    await pumpWithItems(tester);
    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Sin categoría'));
    await tester.pumpAndSettle();

    await openSheet(tester);
    expect(find.text('Qué exportar'), findsOneWidget);
    await tester.tap(find.text('Compartir texto'));
    await tester.pumpAndSettle();

    expect(harness.share.sharedTexts.single, isNot(contains('Huevos')));
    expect(harness.share.sharedTexts.single, contains('Pilas'));
  });

  testWidgets('sin nada por comprar desactiva los botones', (WidgetTester tester) async {
    harness = PluginHarness();
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan');
    await harness.deps.markPurchased(bread.id);
    await harness.pump(tester);
    await openSheet(tester);

    expect(find.text('No hay nada por comprar para exportar.'), findsOneWidget);
    await tester.tap(find.text('Enviar por WhatsApp'));
    expect(harness.share.whatsAppMessages, isEmpty);
  });

  testWidgets('un error al compartir se avisa', (WidgetTester tester) async {
    harness = PluginHarness(share: false);
    harness.locator.registerSingleton<ShareService>(_FailingShare());
    await harness.initialize();
    await harness.deps.createItem(name: 'Pan');
    await harness.pump(tester);
    await openSheet(tester);

    await tester.tap(find.text('Compartir texto'));
    await tester.pumpAndSettle();

    expect(find.text('Ocurrió un error inesperado.'), findsOneWidget);
  });

  testWidgets('sin ShareService no se ofrece exportar', (WidgetTester tester) async {
    await pumpWithItems(tester, share: false);

    expect(find.byTooltip('Exportar'), findsNothing);
  });
}

class _FailingShare implements ShareService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.error(StateError('falló'));
}
