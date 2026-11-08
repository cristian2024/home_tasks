import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_task_list/plugin_task_list.dart';

import '../helpers/domain_fixtures.dart';

void main() {
  late TestUseCases cases;

  setUp(() async {
    cases = TestUseCases();
    await cases.ensureDefaults();
  });

  List<String> names(List<TaskCategory> categories) => categories.map(testCategoryName).toList();

  test('crea las categorías por defecto una sola vez', () async {
    expect(names(await cases.repository.getCategories()), <String>['cleaning', 'kitchen', 'garden', 'bills', 'repairs']);
    expect(await cases.ensureDefaults(), isFalse);
  });

  test('crea una categoría al final y rechaza un nombre ocupado', () async {
    final TaskCategory pets = await cases.createCategory(' Mascotas ');

    expect(pets.sortOrder, 5);
    expect(names(await cases.repository.getCategories()).last, 'Mascotas');
    expect(() => cases.createCategory('mascotas'), throwsA(isA<TaskCategoryNameTakenException>()));
    expect(() => cases.createCategory(''), throwsA(isA<TaskValidationException>()));
  });

  test('renombra, y con el mismo nombre no escribe', () async {
    final TaskCategory garden = (await cases.repository.getCategories())[2];

    expect((await cases.renameCategory(garden.id, 'Patio')).name, 'Patio');
    expect(await cases.renameCategory(garden.id, 'Patio'), garden.copyWith(name: 'Patio'));
    expect(() => cases.renameCategory(garden.id, 'cleaning'), throwsA(isA<TaskCategoryNameTakenException>()));
    expect(() => cases.renameCategory('nada', 'x'), throwsA(isA<TaskCategoryNotFoundException>()));
  });

  test('cuenta su uso y al borrarla la quita de las tareas', () async {
    final TaskCategory cleaning = (await cases.repository.getCategories()).first;
    final HouseholdTask task = await cases.createTask(title: 'Sacar la basura', categoryIds: <String>[cleaning.id]);

    expect(await cases.countUsage(cleaning.id), 1);
    await cases.deleteCategory(cleaning.id);

    expect((await cases.repository.getTask(task.id))!.categoryIds, isEmpty);
    expect(() => cases.deleteCategory(cleaning.id), throwsA(isA<TaskCategoryNotFoundException>()));
  });

  test('reordena con todos los IDs', () async {
    final List<String> ids = <String>[for (final TaskCategory c in await cases.repository.getCategories()) c.id];

    await cases.reorder(ids.reversed.toList());

    expect(names(await cases.repository.getCategories()), <String>['repairs', 'bills', 'garden', 'kitchen', 'cleaning']);
    expect(() => cases.reorder(<String>[ids.first]), throwsArgumentError);
  });

  test('la lista combina tareas y categorías con el día de hoy', () async {
    await cases.createTask(title: 'Sacar la basura', dueDate: DateTime.utc(2026, 11, 6));

    final TaskListSnapshot snapshot = await cases.watchList().first;

    expect(snapshot.today, CalendarDay.localDayOf(t0));
    expect(snapshot.categories, hasLength(5));
    expect(snapshot.summary.toDo, 1);
    expect(await cases.watchCategories().first, hasLength(5));
    expect(snapshot, snapshot);
  });
}
