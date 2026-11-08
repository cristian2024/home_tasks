import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_task_list/plugin_task_list.dart';

import 'helpers/presentation_fixtures.dart';

void main() {
  late PluginHarness harness;

  setUp(() => harness = PluginHarness());
  tearDown(() => harness.dispose());

  test('datos del plugin', () async {
    final TaskListPlugin plugin = harness.plugin;

    expect(plugin.id, 'task_list');
    expect(plugin.version, '0.1.0');
    expect(plugin.nameKey, 'taskList.title');
    expect(plugin.descriptionKey, 'taskList.description');
    expect(plugin.entryRoute, TaskListRoutes.base);
    expect(await plugin.isAvailable(), isTrue);
    expect(plugin.routes, hasLength(5));
  });

  test('al iniciar crea las categorías por defecto y registra sus dependencias en su scope', () async {
    await harness.initialize();

    expect(await harness.repository.getCategories(), hasLength(5));
    expect(harness.locator.isRegistered<TaskListDependencies>(), isTrue);
    expect(harness.localization.translate('taskList.title'), 'Lista de tareas');

    await harness.plugin.dispose();
    expect(harness.locator.isRegistered<TaskListDependencies>(), isFalse);
    await harness.plugin.initialize();
  });

  test('las rutas codifican el id', () {
    expect(TaskListRoutes.edit('a b'), '/task-list/task/a%20b/edit');
  });
}
