import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> scrollTo(WidgetTester tester, Finder finder, {bool up = false}) async {
    await tester.scrollUntilVisible(finder, up ? -200 : 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  testWidgets('crea un item con categorías, urgencia y recurrencia, y vuelve a la lista', (WidgetTester tester) async {
    await harness.pump(tester);
    await tester.tap(find.text('Añadir item'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo item'), findsOneWidget);

    await tester.enterText(field('Nombre'), 'Huevos');
    await tester.enterText(field('Cantidad'), '2 docenas');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Alta'));
    await tester.tap(find.widgetWithText(FilterChip, 'Comida'));
    await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Entre X e Y días'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Entre X e Y días'));
    await tester.pumpAndSettle();
    await scrollTo(tester, field('Máximo de días'));
    await tester.enterText(field('Mínimo de días'), '8');
    await tester.enterText(field('Máximo de días'), '15');
    await scrollTo(tester, find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final ShoppingItem item = (await harness.repository.getItems()).single;
    expect(item.name, 'Huevos');
    expect(item.quantity, '2 docenas');
    expect(item.urgency, Urgency.high);
    expect(item.categoryIds, <String>[(await harness.category('food')).id]);
    expect(item.recurrence, Recurrence.between(8, 15));
    expect(find.text('Lista de compras'), findsOneWidget);
  });

  testWidgets('avisa de un nombre vacío, de días inválidos y de un mínimo mayor que el máximo', (
    WidgetTester tester,
  ) async {
    await harness.pump(tester, initialLocation: ShoppingListRoutes.create);

    await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Cada N días'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cada N días'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un número de días entre 1 y 365.'), findsOneWidget);

    await tester.enterText(field('Cada cuántos días'), '7');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await scrollTo(tester, field('Nombre'), up: true);
    expect(find.text('Este campo es obligatorio.'), findsOneWidget);

    await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Entre X e Y días'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Entre X e Y días'));
    await tester.pumpAndSettle();
    await scrollTo(tester, field('Máximo de días'));
    await tester.enterText(field('Mínimo de días'), '9');
    await tester.enterText(field('Máximo de días'), '3');
    await scrollTo(tester, find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await scrollTo(tester, field('Mínimo de días'), up: true);
    expect(find.text('El mínimo no puede ser mayor que el máximo.'), findsOneWidget);
    expect(await harness.repository.getItems(), isEmpty);
  });

  testWidgets('edita un item existente y lo borra', (WidgetTester tester) async {
    await harness.initialize();
    final ShoppingItem item = await harness.deps.createItem(
      name: 'Huevos',
      quantity: '2',
      recurrence: Recurrence.fixed(7),
      categoryIds: <String>[(await harness.category('food')).id],
    );
    await harness.pump(tester);
    await tester.tap(find.text('Huevos'));
    await tester.pumpAndSettle();

    expect(find.text('Editar item'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    await tester.enterText(field('Nombre'), 'Huevos camperos');
    await scrollTo(tester, find.text('Guardar'));
    expect(find.text('7'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect((await harness.repository.getItem(item.id))!.name, 'Huevos camperos');

    await tester.tap(find.text('Huevos camperos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Borrar item'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar «Huevos camperos»?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar item'));
    await tester.pumpAndSettle();
    expect(await harness.repository.getItems(), isEmpty);
    expect(find.text('La lista está vacía'), findsOneWidget);
  });

  testWidgets('un item que ya no existe muestra el error', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: ShoppingListRoutes.edit('nada'));

    expect(find.text('El item ya no existe.'), findsOneWidget);
  });

  testWidgets('sin categorías lo dice', (WidgetTester tester) async {
    await harness.initialize();
    for (final ShoppingCategory category in await harness.repository.getCategories()) {
      await harness.deps.deleteCategory(category.id);
    }
    await harness.pump(tester, initialLocation: ShoppingListRoutes.create);

    expect(find.text('Aún no hay categorías.'), findsOneWidget);
    expect(find.byType(AppFilterChips<String>), findsNothing);
  });
}
