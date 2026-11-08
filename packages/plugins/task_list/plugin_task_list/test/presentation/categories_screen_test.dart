import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_task_list/plugin_task_list.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  List<String?> names(List<TaskCategory> categories) =>
      <String?>[for (final TaskCategory category in categories) category.name ?? category.defaultKey];

  testWidgets('se abre desde el menú y añade una categoría al final', (WidgetTester tester) async {
    await harness.pump(tester);
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();

    expect(find.text('Limpieza'), findsOneWidget);
    await tester.enterText(find.widgetWithText(AppTextField, 'Nueva categoría'), 'Mascotas');
    await tester.tap(find.byTooltip('Añadir categoría'));
    await tester.pumpAndSettle();

    expect(names(await harness.repository.getCategories()).last, 'Mascotas');
  });

  testWidgets('un nombre repetido se avisa', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: TaskListRoutes.categories);

    await tester.enterText(find.widgetWithText(AppTextField, 'Nueva categoría'), 'cocina');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Ya hay una categoría «cocina».'), findsOneWidget);
  });

  testWidgets('renombra, reordena y borra una categoría en uso avisando de cuántas tareas la usan', (
    WidgetTester tester,
  ) async {
    await harness.initialize();
    final TaskCategory cleaning = await harness.category('cleaning');
    final HouseholdTask task = await harness.task('Sacar la basura', categoryIds: <String>[cleaning.id]);
    await harness.pump(tester, initialLocation: TaskListRoutes.categories);

    await tester.tap(find.byTooltip('Renombrar «Limpieza»'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(AppTextField, 'Limpieza'), 'Orden');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Orden'), findsOneWidget);

    await tester.tap(find.byTooltip('Bajar «Orden»'));
    await tester.pumpAndSettle();
    expect(names(await harness.repository.getCategories()).take(2), <String>['kitchen', 'Orden']);

    await tester.tap(find.byTooltip('Borrar «Orden»'));
    await tester.pumpAndSettle();
    expect(find.text('La usa 1 tarea, que conservará sus demás categorías.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar «Orden»'));
    await tester.pumpAndSettle();

    expect(find.text('Orden'), findsNothing);
    expect((await harness.repository.getTask(task.id))!.categoryIds, isEmpty);
  });

  testWidgets('cancelar el borrado no cambia nada', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: TaskListRoutes.categories);

    await tester.tap(find.byTooltip('Borrar «Jardín»'));
    await tester.pumpAndSettle();
    expect(find.text('Ninguna tarea la usa.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(await harness.repository.getCategories(), hasLength(5));
  });

  testWidgets('sin categorías lo dice', (WidgetTester tester) async {
    await harness.initialize();
    for (final TaskCategory category in await harness.repository.getCategories()) {
      await harness.deps.deleteCategory(category.id);
    }
    await harness.pump(tester, initialLocation: TaskListRoutes.categories);

    expect(find.text('No hay categorías. Añade la primera.'), findsOneWidget);
  });
}
