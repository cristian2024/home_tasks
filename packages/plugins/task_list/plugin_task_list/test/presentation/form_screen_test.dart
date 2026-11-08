import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_task_list/plugin_task_list.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  Finder field(String label) => find.widgetWithText(AppTextField, label);

  Future<void> openDateSheet(WidgetTester tester) async {
    await tester.tap(find.byType(AppPickerField));
    await tester.pumpAndSettle();
  }

  /// Abre el formulario desde la lista, para que guardar tenga adónde volver.
  Future<void> openForm(WidgetTester tester, {String location = TaskListRoutes.create}) async {
    await harness.pump(tester);
    unawaited(harness.router.push<String>(location));
    await tester.pumpAndSettle();
  }

  /// Desplaza el formulario hasta [text], que la lista aún no ha construido.
  Future<void> scrollTo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(find.text(text), 200, scrollable: find.byType(Scrollable).first);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Guardar').last);
    await tester.pumpAndSettle();
  }

  testWidgets('crea una tarea con fecha, urgencia y categoría y vuelve a la lista', (WidgetTester tester) async {
    await harness.pump(tester);
    await tester.tap(find.text('Añadir tarea'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva tarea'), findsOneWidget);

    await tester.enterText(field('Título'), 'Sacar la basura');
    await openDateSheet(tester);
    expect(find.text('Sábado'), findsNothing, reason: 'hoy es viernes: el sábado es mañana');
    await tester.tap(find.widgetWithText(FilterChip, 'Mañana'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(find.text('Mañana'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppChoiceSegment, 'Alta'));
    await tester.tap(find.widgetWithText(FilterChip, 'Limpieza'));
    await tester.pumpAndSettle();
    await save(tester);

    final HouseholdTask task = (await harness.repository.getTasks()).single;
    final TaskCategory cleaning = await harness.category('cleaning');
    expect(task.title, 'Sacar la basura');
    expect(task.dueDate, DateTime.utc(2026, 11, 7));
    expect(task.urgency, Urgency.high);
    expect(task.categoryIds, <String>[cleaning.id]);
    expect(find.text('Lista de tareas'), findsOneWidget);
  });

  testWidgets('el título empieza en una línea y el contador dice cuánto queda', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: TaskListRoutes.create);
    final double emptyHeight = tester.getSize(find.byType(TextField).first).height;

    await tester.enterText(field('Título'), 'a' * 84);
    await tester.pump();

    expect(find.text('84 de 100'), findsOneWidget);
    expect(tester.getSize(find.byType(TextField).first).height, greaterThan(emptyHeight));
  });

  testWidgets('sin título lo explica y no guarda', (WidgetTester tester) async {
    await harness.pump(tester, initialLocation: TaskListRoutes.create);

    await save(tester);

    expect(find.text('Escribe un título para guardar la tarea.'), findsOneWidget);
    expect(await harness.repository.getTasks(), isEmpty);
  });

  testWidgets('la fecha se escribe, se valida y se quita', (WidgetTester tester) async {
    harness.clock.advance(const Duration(days: 3));
    await harness.pump(tester, initialLocation: TaskListRoutes.create);
    await tester.enterText(field('Título'), 'Pagar la luz');

    await openDateSheet(tester);
    expect(find.text('Sábado'), findsOneWidget, reason: 'el lunes, el sábado es otra fecha');
    await tester.enterText(field('Escribir la fecha'), '31/02/2026');
    await save(tester);
    expect(find.text('Esa fecha no existe. Escríbela como 12/11/2026.'), findsOneWidget);
    await tester.enterText(field('Escribir la fecha'), '12/11/2026');
    await save(tester);
    expect(find.text('12 nov'), findsOneWidget);

    await openDateSheet(tester);
    await tester.tap(find.text('Quitar fecha'));
    await tester.pumpAndSettle();
    expect(find.text('Sin fecha'), findsOneWidget);
  });

  testWidgets('al repetirse no pide fecha y valida los días', (WidgetTester tester) async {
    await openForm(tester);
    await tester.enterText(field('Título'), 'Limpiar la nevera');

    await tester.tap(find.widgetWithText(AppChoiceSegment, 'Entre X e Y'));
    await tester.pumpAndSettle();
    expect(find.byType(AppPickerField), findsNothing);

    await tester.enterText(field('Mínimo de días'), '14');
    await tester.enterText(field('Máximo de días'), '10');
    await save(tester);
    expect(find.text('El mínimo no puede ser mayor que el máximo.'), findsOneWidget);

    await tester.enterText(field('Mínimo de días'), '10');
    await tester.enterText(field('Máximo de días'), '14');
    await save(tester);
    expect((await harness.repository.getTasks()).single.recurrence, Recurrence.between(10, 14));
  });

  testWidgets('cada N días rechaza un número fuera de rango', (WidgetTester tester) async {
    await openForm(tester);
    await tester.enterText(field('Título'), 'Regar las plantas');

    await tester.tap(find.widgetWithText(AppChoiceSegment, 'Cada N días'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Cada cuántos días'), '0');
    await save(tester);
    expect(find.text('Escribe un número de días entre 1 y 365.'), findsOneWidget);

    await tester.enterText(field('Cada cuántos días'), '3');
    await save(tester);
    expect((await harness.repository.getTasks()).single.recurrence, Recurrence.fixed(3));
  });

  testWidgets('tocar una tarea la abre para editar y guarda los cambios', (WidgetTester tester) async {
    final HouseholdTask task = await harness.task('Regar plantas', dueDate: DateTime.utc(2026, 11, 7));
    await harness.pump(tester);

    await tester.tap(find.text('Regar plantas'));
    await tester.pumpAndSettle();
    expect(find.text('Editar tarea'), findsOneWidget);
    expect(find.text('Mañana'), findsOneWidget);
    await tester.enterText(field('Regar plantas'), 'Regar las plantas');
    await save(tester);

    final HouseholdTask saved = (await harness.repository.getTask(task.id))!;
    expect(saved.title, 'Regar las plantas');
    expect(saved.dueDate, DateTime.utc(2026, 11, 7));
    expect(find.text('Regar las plantas'), findsOneWidget);
  });

  testWidgets('al editar muestra la última vez y borra tras confirmar', (WidgetTester tester) async {
    final HouseholdTask task = await harness.task('Limpiar la nevera', recurrence: Recurrence.between(10, 14));
    await harness.deps.completeTask(task.id);
    await openForm(tester, location: TaskListRoutes.edit(task.id));

    expect(find.text('Editar tarea'), findsOneWidget);
    expect(field('Limpiar la nevera'), findsOneWidget);
    await scrollTo(tester, 'Borrar tarea');
    expect(find.text('Hecha por última vez el 6 nov.'), findsOneWidget);

    await tester.tap(find.text('Borrar tarea'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar «Limpiar la nevera»?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(await harness.repository.getTasks(), isEmpty);
  });

  testWidgets('cumple las guías de accesibilidad y no desborda al 200 %', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await harness.pump(tester, initialLocation: TaskListRoutes.create);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await harness.pump(tester, initialLocation: TaskListRoutes.create, textScale: 2);
    await scrollTo(tester, 'Entre X e Y');
    await tester.ensureVisible(find.text('Entre X e Y'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entre X e Y'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
