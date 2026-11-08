import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_task_list/plugin_task_list.dart';
import 'package:plugin_task_list/testing.dart';
import 'package:task_list_example/src/example_app.dart';

void main() {
  testWidgets('carga los datos de ejemplo y abre la lista', (WidgetTester tester) async {
    // Como el adaptador, pero en memoria, y con un reloj fijo.
    final ServiceLocator locator = ServiceLocator()
      ..registerSingleton<TaskListRepository>(InMemoryTaskListRepository())
      ..registerSingleton<Clock>(FixedClock(DateTime.utc(2026, 11, 6, 12)));
    final LocalizationCoordinator localization = LocalizationCoordinator();
    final TaskListPlugin plugin = TaskListPlugin(locator: locator, localization: localization);
    await plugin.initialize();
    addTearDown(locator.reset);

    await tester.pumpWidget(TaskListExampleApp(plugin: plugin, locator: locator, localization: localization));
    await tester.pumpAndSettle();
    expect(find.text('Nada por hacer'), findsOneWidget);

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('Datos de ejemplo cargados: 7 tareas.'), findsOneWidget);
    expect(find.text('6 por hacer'), findsOneWidget);
    expect(find.text('1 atrasada'), findsOneWidget);

    await tester.tap(find.text('Cargar datos de ejemplo'));
    await tester.pumpAndSettle();
    expect(find.text('Los datos de ejemplo ya estaban cargados.'), findsOneWidget);

    await tester.tap(find.text('Lista de tareas'));
    await tester.pumpAndSettle();
    expect(find.text('Atrasadas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hechas · 1'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Hechas · 1'), findsOneWidget);

    await plugin.dispose();
  });
}
