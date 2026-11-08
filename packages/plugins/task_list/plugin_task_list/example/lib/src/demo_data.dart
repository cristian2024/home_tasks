import 'package:core_utils/core_utils.dart';
import 'package:plugin_task_list/plugin_task_list.dart';

/// Tareas de ejemplo para recorrer la lista a mano: una de cada grupo
/// (atrasada, hoy, próxima, sin fecha), una que se repite y una hecha.
class DemoData {
  const DemoData(this._dependencies, this._repository, this._clock);

  final TaskListDependencies _dependencies;

  /// Para leer lo que ya hay: tareas y categorías (las por defecto se eligen
  /// por su clave).
  final TaskListRepository _repository;

  /// Las fechas se calculan desde hoy, para que caigan siempre en su grupo.
  final Clock _clock;

  /// Crea las tareas que falten (por título). Devuelve cuántas creó.
  Future<int> load() async {
    final List<TaskCategory> categories = await _repository.getCategories();
    final Set<String> existing = <String>{
      for (final HouseholdTask task in await _repository.getTasks()) ListCategories.normalize(task.title),
    };
    final DateTime today = _clock.today();
    List<String> ids(List<String> keys) => <String>[
          for (final TaskCategory category in categories)
            if (keys.contains(category.defaultKey)) category.id,
        ];
    int created = 0;
    Future<HouseholdTask?> create(
      String title, {
      Urgency urgency = Urgency.normal,
      List<String> categoryKeys = const <String>[],
      int? dueInDays,
      Recurrence? recurrence,
    }) async {
      if (existing.contains(ListCategories.normalize(title))) {
        return null;
      }
      created++;
      return _dependencies.createTask(
        title: title,
        urgency: urgency,
        categoryIds: ids(categoryKeys),
        dueDate: dueInDays == null ? null : CalendarDay.of(today.add(Duration(days: dueInDays))),
        recurrence: recurrence,
      );
    }

    await create('Cambiar el filtro del agua', urgency: Urgency.high, categoryKeys: <String>['repairs'], dueInDays: -3);
    await create('Sacar la basura', urgency: Urgency.immediate, categoryKeys: <String>['cleaning'], dueInDays: 0);
    await create('Limpiar la nevera', categoryKeys: <String>['kitchen', 'cleaning'], recurrence: Recurrence.between(10, 14));
    await create('Regar las plantas', categoryKeys: <String>['garden'], dueInDays: 1);
    await create('Pagar la luz', urgency: Urgency.high, categoryKeys: <String>['bills'], dueInDays: 5);
    await create('Arreglar la persiana', urgency: Urgency.low, categoryKeys: <String>['repairs']);
    final HouseholdTask? done = await create('Poner una lavadora', categoryKeys: <String>['cleaning']);
    if (done != null) {
      await _dependencies.completeTask(done.id);
    }
    return created;
  }
}
