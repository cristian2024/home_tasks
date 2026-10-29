import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  testWidgets('la tarjeta del inicio cuenta lo que hay por comprar y lo urgente, y abre la lista', (
    WidgetTester tester,
  ) async {
    await harness.pump(tester, initialLocation: '/');
    expect(find.text('No hay nada por comprar'), findsOneWidget);

    await harness.deps.createItem(name: 'Huevos', urgency: Urgency.immediate);
    await harness.deps.createItem(name: 'Pan');
    await tester.pumpAndSettle();
    expect(find.text('2 cosas por comprar'), findsOneWidget);
    expect(find.text('1 urgente'), findsOneWidget);

    await tester.tap(find.text('Lista de compras'));
    await tester.pumpAndSettle();
    expect(find.text('Huevos'), findsOneWidget);
  });

  testWidgets('una lista vacía lo dice', (WidgetTester tester) async {
    await harness.pump(tester);

    expect(find.text('La lista está vacía'), findsOneWidget);
  });

  testWidgets('agrupa por categoría, cada item una vez, con sus badges', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingCategory food = await harness.category('food');
    final ShoppingCategory home = await harness.category('home');
    await harness.deps.createItem(
      name: 'Huevos',
      quantity: '2 docenas',
      urgency: Urgency.immediate,
      categoryIds: <String>[food.id, home.id],
      recurrence: Recurrence.between(8, 15),
    );
    await harness.deps.createItem(name: 'Pilas');
    await harness.pump(tester);

    expect(find.text('Comida'), findsWidgets);
    expect(find.text('Sin categoría'), findsWidgets);
    expect(find.text('Huevos'), findsOneWidget);
    expect(find.text('2 docenas · Cada 8 a 15 días'), findsOneWidget);
    expect(find.widgetWithText(AppBadge, 'Inmediata'), findsOneWidget);
    expect(find.widgetWithText(AppBadge, 'Hogar'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Urgencia'));
    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBadge, 'Comida'), findsOneWidget);
  });

  testWidgets('marcar como comprado publica el evento y se puede deshacer', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan');
    await harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Marcar «Pan» como comprado'));
    await tester.pumpAndSettle();

    expect(find.text('«Pan» comprado'), findsOneWidget);
    expect((await harness.repository.getItem(bread.id))!.status, ShoppingItemStatus.purchased);
    expect(harness.eventBus.publishedOf<ShoppingItemPurchased>().single.itemName, 'Pan');

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect((await harness.repository.getItem(bread.id))!.status, ShoppingItemStatus.pending);
    expect(await harness.repository.getPurchases(bread.id), isEmpty);
  });

  testWidgets('un item comprado vuelve a pendiente y los comprados se pueden borrar', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan');
    final ShoppingItem milk = await harness.deps.createItem(name: 'Leche');
    await harness.deps.markPurchased(bread.id);
    await harness.deps.markPurchased(milk.id);
    await harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Volver «Pan» a pendiente'));
    await tester.pumpAndSettle();
    expect((await harness.repository.getItem(bread.id))!.status, ShoppingItemStatus.pending);

    await tester.tap(find.byTooltip('Borrar comprados'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar comprados'));
    await tester.pumpAndSettle();
    expect(await harness.repository.getItem(milk.id), isNull);
    expect(find.byTooltip('Borrar comprados'), findsNothing);
  });

  testWidgets('filtra por categoría, urgencia y estado, y quita los filtros', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingCategory food = await harness.category('food');
    await harness.deps.createItem(name: 'Huevos', categoryIds: <String>[food.id], urgency: Urgency.high);
    await harness.deps.createItem(name: 'Pilas');
    await harness.pump(tester);
    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Sin categoría'));
    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    expect(find.text('Hay filtros activos.'), findsOneWidget);
    expect(find.text('Huevos'), findsNothing);
    expect(find.text('Pilas'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Sin categoría'));
    await tester.tap(find.widgetWithText(FilterChip, 'Comida'));
    await tester.pumpAndSettle();
    expect(find.text('Pilas'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Baja'));
    await tester.pumpAndSettle();
    expect(find.text('Nada coincide con los filtros'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Comprado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar filtros').first);
    await tester.pumpAndSettle();
    expect(find.text('Hay filtros activos.'), findsNothing);
    expect(find.text('Huevos'), findsOneWidget);
    expect(find.text('Pilas'), findsOneWidget);
  });

  testWidgets('la lista cumple las guías de accesibilidad', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan', urgency: Urgency.immediate);
    await harness.deps.createItem(name: 'Huevos', recurrence: Recurrence.fixed(7), urgency: Urgency.high);
    await harness.deps.markPurchased(bread.id);
    await harness.pump(tester);
    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
