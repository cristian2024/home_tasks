
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_task_list/plugin_task_list.dart';
import 'package:plugin_task_list/testing.dart';

import '../helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  /// Las tareas de la pantalla `46`, con hoy viernes 6 de noviembre.
  Future<void> seed() async {
    await harness.initialize();
    final TaskCategory repairs = await harness.category('repairs');
    final TaskCategory cleaning = await harness.category('cleaning');
    final TaskCategory kitchen = await harness.category('kitchen');
    await harness.task('Cambiar el filtro del agua', urgency: Urgency.high, dueDate: DateTime.utc(2026, 11, 3), categoryIds: <String>[repairs.id]);
    await harness.task('Sacar la basura', urgency: Urgency.immediate, dueDate: DateTime.utc(2026, 11, 6), categoryIds: <String>[cleaning.id]);
    await harness.task('Limpiar la nevera', recurrence: Recurrence.between(10, 14), categoryIds: <String>[kitchen.id]);
    await harness.task('Regar las plantas', dueDate: DateTime.utc(2026, 11, 7));
    await harness.task('Arreglar la persiana', categoryIds: <String>[repairs.id]);
  }

  testWidgets('agrupa por fecha con la línea de datos de cada tarea', (WidgetTester tester) async {
    await seed();
    await harness.pump(tester);

    for (final String header in <String>['Atrasadas', 'Hoy', 'Próximas', 'Sin fecha']) {
      expect(find.text(header), findsOneWidget);
    }
    expect(find.text('3 nov · Reparaciones'), findsOneWidget);
    expect(find.text('Limpieza'), findsOneWidget);
    expect(find.text('Cada 10 a 14 días · Cocina'), findsOneWidget);
    expect(find.text('Mañana'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Inmediata'), findsOneWidget);
    expect(find.text('Atrasada'), findsNothing, reason: 'el grupo ya lo dice');
    expect(find.bySemanticsLabel(RegExp('martes, 3 de noviembre de 2026')), findsOneWidget);
  });

  testWidgets('completar deja la tarea marcada en su sitio, avisa y se puede deshacer', (WidgetTester tester) async {
    await seed();
    await harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Marcar «Sacar la basura» como hecha'));
    await tester.pump();

    expect(find.text('«Sacar la basura» hecha'), findsOneWidget);
    expect(find.bySemanticsLabel('Volver «Sacar la basura» a pendiente'), findsOneWidget);
    expect(find.text('Sacar la basura'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect((await harness.repository.getTasks()).where((HouseholdTask task) => task.status == TaskStatus.done), isEmpty);
    expect(find.bySemanticsLabel('Marcar «Sacar la basura» como hecha'), findsOneWidget);
  });

  testWidgets('pasados 5 segundos, la hecha va a «Hechas» y la repetida espera', (WidgetTester tester) async {
    await seed();
    await harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Marcar «Sacar la basura» como hecha'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Hechas · 1'), findsOneWidget);
    expect(find.text('Sacar la basura'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Marcar «Limpiar la nevera» como hecha'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('«Limpiar la nevera» vuelve el 16 nov'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Cada 10 a 14 días · vuelve el 16 nov · Cocina'), findsOneWidget);
    expect(find.text('En espera'), findsOneWidget);
  });

  testWidgets('sin tareas muestra el estado vacío', (WidgetTester tester) async {
    await harness.pump(tester);

    expect(find.text('Aún no hay tareas'), findsOneWidget);
    expect(find.text('Añade lo que haya que hacer en casa.'), findsOneWidget);
    expect(find.byTooltip('Filtros y agrupación'), findsNothing);
  });

  testWidgets('con todo hecho muestra «Todo hecho» y la fila de hechas abre la lista de hechas', (WidgetTester tester) async {
    final HouseholdTask task = await harness.task('Sacar la basura');
    await harness.deps.completeTask(task.id);
    await harness.pump(tester);

    expect(find.text('Todo hecho'), findsOneWidget);
    await tester.tap(find.text('Hechas · 1'));
    await tester.pumpAndSettle();

    expect(find.text('Hechas'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
  });

  testWidgets('filtra, agrupa por categoría y quita los filtros', (WidgetTester tester) async {
    await seed();
    await harness.pump(tester);

    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cerrar filtros y agrupación'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Atrasada'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppChoiceSegment, 'Categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar filtros y agrupación'));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar el filtro del agua'), findsOneWidget);
    expect(find.text('Sacar la basura'), findsNothing);
    expect(find.text('Atrasada'), findsOneWidget, reason: 'agrupado por categoría, el atraso se marca');

    await tester.tap(find.byTooltip('Filtros y agrupación'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Atrasada'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'En espera'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar filtros y agrupación'));
    await tester.pumpAndSettle();
    expect(find.text('Nada coincide con los filtros'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Sacar la basura'), findsOneWidget);
  });

  testWidgets('el menú abre categorías y borra las hechas tras confirmar', (WidgetTester tester) async {
    final HouseholdTask task = await harness.task('Sacar la basura');
    await harness.task('Regar las plantas');
    await harness.deps.completeTask(task.id);
    await harness.pump(tester);

    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    expect(find.text('Exportar'), findsNothing);
    await tester.tap(find.text('Borrar hechas'));
    await tester.pumpAndSettle();
    expect(find.text('¿Borrar 1 tarea hecha?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('Tareas hechas borradas'), findsOneWidget);
    expect(await harness.repository.getTasks(), hasLength(1));

    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    expect(find.text('Borrar hechas'), findsNothing);
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  testWidgets('en hechas, una tarea vuelve a pendiente', (WidgetTester tester) async {
    final HouseholdTask task = await harness.task('Sacar la basura');
    await harness.deps.completeTask(task.id);
    await harness.pump(tester, initialLocation: TaskListRoutes.done);

    await tester.tap(find.bySemanticsLabel('Volver «Sacar la basura» a pendiente'));
    await tester.pumpAndSettle();

    expect((await harness.repository.getTask(task.id))!.status, TaskStatus.pending);
    expect(find.text('No hay tareas hechas.'), findsOneWidget);
  });

  testWidgets('la tarjeta del inicio muestra lo por hacer y lo atrasado', (WidgetTester tester) async {
    await seed();
    await harness.pump(tester, initialLocation: '/');

    expect(find.text('Lista de tareas'), findsOneWidget);
    expect(find.text('5 por hacer'), findsOneWidget);
    expect(find.text('1 atrasada'), findsOneWidget);
    await tester.tap(find.text('5 por hacer'));
    await tester.pumpAndSettle();
    expect(find.text('Atrasadas'), findsOneWidget);
  });

  testWidgets('la tarjeta muestra lo urgente si nada está atrasado', (WidgetTester tester) async {
    await harness.task('Sacar la basura', urgency: Urgency.immediate);
    await harness.pump(tester, initialLocation: '/');

    expect(find.text('1 urgente'), findsOneWidget);
  });

  testWidgets('un error al cargar ofrece reintentar', (WidgetTester tester) async {
    await harness.dispose();
    final _FailingRepository failing = _FailingRepository();
    harness = PluginHarness(repository: failing);
    await harness.pump(tester);

    expect(find.text('No se pudieron cargar las tareas'), findsOneWidget);
    expect(find.text('Añadir tarea'), findsNothing);
    expect(find.byTooltip('Más opciones'), findsNothing);
    failing.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay tareas'), findsOneWidget);
  });

  testWidgets('si la carga tarda, a los 2 s lo dice y no ofrece acciones', (WidgetTester tester) async {
    await harness.dispose();
    harness = PluginHarness(repository: _SlowRepository());
    await harness.initialize();
    await tester.pumpWidget(const SizedBox());
    harness.router = GoRouter(initialLocation: TaskListRoutes.base, routes: harness.plugin.routes);
    await tester.pumpWidget(MaterialApp.router(locale: const Locale('es'), routerConfig: harness.router));
    await tester.pump();

    expect(find.text('Cargando tareas…'), findsNothing);
    expect(find.text('Añadir tarea'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Cargando tareas…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cumple las guías de accesibilidad y no desborda al 200 %', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await seed();
    await harness.pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await harness.pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

class _SlowRepository extends InMemoryTaskListRepository {
  @override
  Stream<List<HouseholdTask>> watchTasks() => const Stream<List<HouseholdTask>>.empty();
}

class _FailingRepository extends InMemoryTaskListRepository {
  bool fail = true;

  @override
  Stream<List<HouseholdTask>> watchTasks() => fail ? Stream<List<HouseholdTask>>.error(StateError('sin base')) : super.watchTasks();
}

