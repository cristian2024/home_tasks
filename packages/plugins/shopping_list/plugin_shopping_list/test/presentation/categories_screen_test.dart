import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  List<String?> names(List<ShoppingCategory> categories) =>
      <String?>[for (final ShoppingCategory category in categories) category.name ?? category.defaultKey];

  testWidgets('se abre desde la lista y añade una categoría al final', (WidgetTester tester) async {
    await harness.pump(tester);
    await tester.tap(find.byTooltip('Categorías'));
    await tester.pumpAndSettle();

    expect(find.text('Comida'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nueva categoría'), 'Mascotas');
    await tester.tap(find.text('Añadir categoría'));
    await tester.pumpAndSettle();

    expect(names(await harness.repository.getCategories()).last, 'Mascotas');
    expect(find.widgetWithText(TextField, 'Mascotas'), findsNothing);
  });

  testWidgets('un nombre repetido se avisa', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: ShoppingListRoutes.categories);

    await tester.enterText(find.widgetWithText(TextField, 'Nueva categoría'), 'comida');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Ya hay una categoría «comida».'), findsOneWidget);
  });

  testWidgets('renombra, reordena y borra una categoría en uso avisando de cuántos items la usan', (
    WidgetTester tester,
  ) async {
    await harness.initialize();
    final ShoppingCategory food = await harness.category('food');
    final ShoppingItem eggs = await harness.deps.createItem(name: 'Huevos', categoryIds: <String>[food.id]);
    await harness.pump(tester, initialLocation: ShoppingListRoutes.categories);

    await tester.tap(find.byTooltip('Renombrar «Comida»'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Comida'), 'Comestibles');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Comestibles'), findsOneWidget);

    await tester.tap(find.byTooltip('Bajar «Comestibles»'));
    await tester.pumpAndSettle();
    expect(names(await harness.repository.getCategories()).take(2), <String>['hygiene', 'Comestibles']);

    await tester.tap(find.byTooltip('Borrar «Comestibles»'));
    await tester.pumpAndSettle();
    expect(find.text('La usa 1 item, que conservará sus demás categorías.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar «Comestibles»'));
    await tester.pumpAndSettle();

    expect(find.text('Comestibles'), findsNothing);
    expect((await harness.repository.getItem(eggs.id))!.categoryIds, isEmpty);
  });

  testWidgets('cancelar el renombrado o el borrado no cambia nada', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: ShoppingListRoutes.categories);

    await tester.tap(find.byTooltip('Renombrar «Aseo»'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Borrar «Aseo»'));
    await tester.pumpAndSettle();
    expect(find.text('Ningún item la usa.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(await harness.repository.getCategories(), hasLength(5));
  });

  testWidgets('sin categorías lo dice', (WidgetTester tester) async {
    await harness.initialize();
    for (final ShoppingCategory category in await harness.repository.getCategories()) {
      await harness.deps.deleteCategory(category.id);
    }
    await harness.pump(tester, initialLocation: ShoppingListRoutes.categories);

    expect(find.text('No hay categorías. Añade la primera.'), findsOneWidget);
  });
}
