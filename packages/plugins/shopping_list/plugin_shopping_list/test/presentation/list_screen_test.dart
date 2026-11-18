import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:shopping_list_contract/shopping_list_contract.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  Future<void> openFilters(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
  }

  /// La fila de [name], que se lee como un solo botón.
  Finder row(String name) => find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}(,|\\.)'));

  void performDelete(WidgetTester tester, String name) {
    final SemanticsNode node = tester.getSemantics(row(name));
    final int actionId = CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: 'Borrar «$name»'));
    tester.renderObject(find.byType(AppCheckTile).first).owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.customAction,
          actionId,
        );
  }

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

  testWidgets('una lista vacía lo dice, sin filtros y con el menú', (WidgetTester tester) async {
    await harness.pump(tester);

    expect(find.text('La lista está vacía'), findsOneWidget);
    expect(find.byTooltip('Filtros y agrupación'), findsNothing);
    expect(find.byTooltip('Más opciones'), findsOneWidget);
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
    expect(find.text('2 docenas · Cada 8 a 15 días'), findsOneWidget);
    expect(find.widgetWithText(AppBadge, 'Inmediata'), findsOneWidget);
    expect(find.widgetWithText(AppBadge, 'Hogar'), findsOneWidget);

    await openFilters(tester);
    await tester.ensureVisible(find.widgetWithText(AppChoiceSegment, 'Urgencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppChoiceSegment, 'Urgencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo · 2'));
    await tester.pumpAndSettle();
    expect(find.text('Listo · 2'), findsNothing);
    expect(find.widgetWithText(AppBadge, 'Comida'), findsOneWidget);
  });

  testWidgets('cada fila se lee como un botón que abre editar y tiene un lápiz', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await harness.initialize();
    await harness.deps.createItem(name: 'Leche', quantity: '2 litros', urgency: Urgency.immediate);
    await harness.pump(tester);

    expect(find.bySemanticsLabel('Leche, 2 litros, Inmediata. Editar'), findsOneWidget);
    await tester.tap(find.byTooltip('Editar «Leche»'));
    await tester.pumpAndSettle();
    expect(find.text('Editar ítem'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('marcar como comprado quita la fila, publica el evento y se puede deshacer', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan');
    await harness.deps.createItem(name: 'Sal');
    await harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Marcar «Pan» como comprado'));
    await tester.pumpAndSettle();

    expect(find.text('«Pan» comprado'), findsOneWidget);
    expect(find.text('Pan'), findsNothing);
    expect(find.text('Comprados · 1'), findsOneWidget);
    expect((await harness.repository.getItem(bread.id))!.status, ShoppingItemStatus.purchased);
    expect(harness.eventBus.publishedOf<ShoppingItemPurchased>().single.itemName, 'Pan');

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('Pan'), findsOneWidget);
    expect((await harness.repository.getItem(bread.id))!.status, ShoppingItemStatus.pending);
    expect(await harness.repository.getPurchases(bread.id), isEmpty);
  });

  testWidgets('el aviso de compra se cierra solo a los 5 segundos', (WidgetTester tester) async {
    await harness.initialize();
    await harness.deps.createItem(name: 'Pan');
    await harness.deps.createItem(name: 'Sal');
    await harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Marcar «Pan» como comprado'));
    await tester.pumpAndSettle();
    expect(find.text('«Pan» comprado'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('«Pan» comprado'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('«Pan» comprado'), findsNothing);
  });

  testWidgets('con todo comprado lo dice y lleva a los comprados', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan');
    await harness.deps.markPurchased(bread.id);
    await harness.pump(tester);

    expect(find.text('Todo comprado'), findsOneWidget);
    expect(find.text('La lista está vacía'), findsNothing);
    await tester.tap(find.text('Ver comprados'));
    await tester.pumpAndSettle();
    expect(find.text('Comprados'), findsOneWidget);
    expect(find.text('Pan'), findsOneWidget);
  });

  testWidgets('Comprados: fecha de compra, volver a pendiente con deshacer y borrar todos', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan');
    final ShoppingItem milk = await harness.deps.createItem(name: 'Leche');
    await harness.deps.createItem(name: 'Sal');
    await harness.deps.markPurchased(bread.id);
    await harness.deps.markPurchased(milk.id);
    await harness.pump(tester);

    await tester.tap(find.text('Comprados · 2'));
    await tester.pumpAndSettle();
    expect(find.text('Hoy'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Pan, Comprado hoy'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Volver «Pan» a pendiente'));
    await tester.pumpAndSettle();
    expect((await harness.repository.getItem(bread.id))!.status, ShoppingItemStatus.pending);
    expect(find.text('«Pan» vuelve a pendiente'), findsOneWidget);
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect((await harness.repository.getItem(bread.id))!.status, ShoppingItemStatus.purchased);

    await tester.tap(find.text('Borrar comprados'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar comprados').last);
    await tester.pumpAndSettle();
    expect(await harness.repository.getItem(bread.id), isNull);
    expect(await harness.repository.getItem(milk.id), isNull);
    expect(find.text('No hay nada comprado.'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('En espera: cuándo vuelve y comprar antes de tiempo', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingItem coffee = await harness.deps.createItem(name: 'Café', recurrence: Recurrence.fixed(7));
    await harness.deps.createItem(name: 'Sal');
    await harness.deps.markPurchased(coffee.id);
    await harness.pump(tester);

    expect(find.text('Café'), findsNothing);
    await tester.tap(find.text('En espera · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Cada 7 días · vuelve el 4 nov'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Marcar «Café» como comprado'));
    await tester.pumpAndSettle();
    expect(find.text('«Café» comprado'), findsOneWidget);
    expect(await harness.repository.getPurchases(coffee.id), hasLength(2));
  });

  group('filtros', () {
    testWidgets('por defecto, pendiente y atrasado; «Restablecer» solo si cambian', (WidgetTester tester) async {
      await harness.initialize();
      final ShoppingItem bread = await harness.deps.createItem(name: 'Pan');
      await harness.deps.createItem(name: 'Sal');
      await harness.deps.markPurchased(bread.id);
      await harness.pump(tester);
      await openFilters(tester);

      AppButton reset() => tester.widget<AppButton>(find.widgetWithText(AppButton, 'Restablecer'));
      expect(reset().onPressed, isNull);
      expect(find.text('Pan'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Comprado'));
      await tester.pumpAndSettle();
      expect(find.text('Pan'), findsOneWidget);
      expect(find.text('Listo · 2'), findsOneWidget);
      expect(reset().onPressed, isNotNull);

      await tester.tap(find.text('Restablecer'));
      await tester.pumpAndSettle();
      expect(find.text('Pan'), findsNothing);
      expect(reset().onPressed, isNull);
    });

    testWidgets('muestra 4 categorías y despliega el resto', (WidgetTester tester) async {
      await harness.initialize();
      await harness.deps.createItem(name: 'Sal');
      await harness.pump(tester);
      await openFilters(tester);

      expect(find.widgetWithText(FilterChip, 'Sin categoría'), findsNothing);
      await tester.tap(find.text('2 más'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Sin categoría'), findsOneWidget);
    });

    testWidgets('sin coincidencias lo dice y «Quitar filtros» vuelve al filtro por defecto', (WidgetTester tester) async {
      await harness.initialize();
      final ShoppingCategory food = await harness.category('food');
      await harness.deps.createItem(name: 'Huevos', categoryIds: <String>[food.id], urgency: Urgency.high);
      await harness.deps.createItem(name: 'Pilas');
      await harness.pump(tester);
      await openFilters(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Comida'));
      await tester.pumpAndSettle();
      expect(find.text('Pilas'), findsNothing);
      await tester.tap(find.widgetWithText(FilterChip, 'Baja'));
      await tester.pumpAndSettle();
      expect(find.text('Nada coincide con los filtros'), findsOneWidget);

      await tester.tap(find.text('Quitar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Huevos'), findsOneWidget);
      expect(find.text('Pilas'), findsOneWidget);
    });
  });

  group('borrar', () {
    testWidgets('deslizando a la izquierda, sin diálogo y con deshacer', (WidgetTester tester) async {
      await harness.initialize();
      final ShoppingItem bread = await harness.deps.createItem(name: 'Pan', quantity: '1 barra');
      await harness.pump(tester);

      await tester.drag(find.text('Pan'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(await harness.repository.getItem(bread.id), isNull);
      expect(find.text('Se borró «Pan»'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      final ShoppingItem restored = (await harness.repository.getItems()).single;
      expect(restored.name, 'Pan');
      expect(restored.quantity, '1 barra');
      expect(find.text('Pan'), findsOneWidget);
    });

    testWidgets('con la acción del lector de pantalla', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await harness.initialize();
      await harness.deps.createItem(name: 'Pan');
      await harness.pump(tester);

      performDelete(tester, 'Pan');
      await tester.pumpAndSettle();
      expect(await harness.repository.getItems(), isEmpty);
      expect(find.text('Se borró «Pan»'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('desde editar, la primera vez sugiere deslizar', (WidgetTester tester) async {
      await harness.initialize();
      await harness.deps.createItem(name: 'Pan');
      await harness.deps.createItem(name: 'Sal');
      await harness.pump(tester);

      Future<void> deleteFromForm(String name) async {
        await tester.tap(find.byTooltip('Editar «$name»'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Borrar ítem'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Borrar ítem'));
        await tester.pumpAndSettle();
      }

      await deleteFromForm('Pan');
      expect(find.text('Se borró «Pan». La próxima vez puedes deslizar la fila a la izquierda.'), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(find.text('Pan'), findsOneWidget);

      await deleteFromForm('Sal');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Se borró «Sal»'), findsOneWidget);
    });
  });

  group('crear desde la lista', () {
    Finder field() => find.descendant(of: find.byType(AppComposeBar<String>), matching: find.byType(TextField));

    testWidgets('Intro crea, vacía el campo y lo deja abierto', (WidgetTester tester) async {
      await harness.pump(tester);
      await tester.tap(find.text('Añadir ítem'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre del ítem nuevo'), findsOneWidget);
      expect(find.text('Añadir ítem'), findsNothing);

      await tester.enterText(field(), 'Pan');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      final ShoppingItem bread = (await harness.repository.getItems()).single;
      expect(bread.name, 'Pan');
      expect(bread.urgency, Urgency.normal);
      expect(bread.categoryIds, isEmpty);
      expect(bread.recurrence, isNull);
      expect(tester.widget<TextField>(field()).controller!.text, isEmpty);
      expect(find.byType(AppComposeBar<String>), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar el campo'));
      await tester.pumpAndSettle();
      expect(find.text('Añadir ítem'), findsOneWidget);
    });

    testWidgets('la categoría elegida se usa y se recuerda', (WidgetTester tester) async {
      await harness.initialize();
      final ShoppingCategory food = await harness.category('food');
      await harness.pump(tester);
      await tester.tap(find.text('Añadir ítem'));
      await tester.pumpAndSettle();
      expect(find.text('Se añadirá a'), findsOneWidget);

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Comida'));
      await tester.pumpAndSettle();
      await tester.enterText(field(), 'Pan');
      await tester.tap(find.byTooltip('Añadir'));
      await tester.pumpAndSettle();
      expect((await harness.repository.getItems()).single.categoryIds, <String>[food.id]);

      await tester.tap(find.byTooltip('Cerrar el campo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir ítem'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Comida'), findsOneWidget);
    });

    testWidgets('con un filtro de una sola categoría, va a esa', (WidgetTester tester) async {
      await harness.initialize();
      final ShoppingCategory cleaning = await harness.category('cleaning');
      await harness.deps.createItem(name: 'Sal');
      await harness.pump(tester);
      await openFilters(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Limpieza'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cerrar filtros y agrupación'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Añadir ítem'));
      await tester.pumpAndSettle();
      await tester.enterText(field(), 'Lejía');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      final ShoppingItem bleach =
          (await harness.repository.getItems()).firstWhere((ShoppingItem item) => item.name == 'Lejía');
      expect(bleach.categoryIds, <String>[cleaning.id]);
      expect(find.text('Lejía'), findsOneWidget);
    });

    testWidgets('sin nombre muestra el error y no crea nada', (WidgetTester tester) async {
      await harness.pump(tester);
      await tester.tap(find.text('Añadir ítem'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Añadir'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un nombre para añadir el ítem.'), findsOneWidget);
      expect(await harness.repository.getItems(), isEmpty);
    });
  });

  testWidgets('la lista cumple las guías de accesibilidad', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await harness.initialize();
    final ShoppingItem bread = await harness.deps.createItem(name: 'Pan', urgency: Urgency.immediate);
    await harness.deps.createItem(name: 'Huevos', recurrence: Recurrence.fixed(7), urgency: Urgency.high);
    await harness.deps.markPurchased(bread.id);
    await harness.pump(tester);
    await openFilters(tester);
    // Con el filtro por defecto, «Restablecer» va desactivado, y lo desactivado
    // no tiene que cumplir el contraste (WCAG 1.4.3).
    await tester.tap(find.widgetWithText(FilterChip, 'Comprado'));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
