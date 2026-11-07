import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_list_domain/task_list_domain.dart';

import 'src/domain/use_cases/category_use_cases.dart';
import 'src/domain/use_cases/completion_use_cases.dart';
import 'src/domain/use_cases/list_queries.dart';
import 'src/domain/use_cases/task_use_cases.dart';
import 'src/i18n/strings.g.dart' as i18n;
import 'src/presentation/categories/task_categories_cubit.dart';
import 'src/presentation/categories/task_categories_screen.dart';
import 'src/presentation/common/task_list_l10n.dart';
import 'src/presentation/dashboard/task_list_dashboard_tile.dart';
import 'src/presentation/done/done_tasks_screen.dart';
import 'src/presentation/form/task_form_cubit.dart';
import 'src/presentation/form/task_form_screen.dart';
import 'src/presentation/list/task_list_cubit.dart';
import 'src/presentation/list/task_list_screen.dart';
import 'src/presentation/task_list_routes.dart';
import 'src/task_list_dependencies.dart';

/// Plugin de lista de tareas.
///
/// Dependencias que toma del `ServiceLocator` de la app (scope base):
/// - `TaskListRepository` (obligatorio), que registra el adaptador de
///   almacenamiento que elige la app (p. ej. `TaskListIsar`). En tests,
///   `InMemoryTaskListRepository` de `package:plugin_task_list/testing.dart`.
/// - `IdGenerator` y `Clock` (opcionales: si faltan usa los suyos).
///
/// Su pantalla principal es la lista ([entryRoute]). Aún no publica eventos
/// ni capacidades.
class TaskListPlugin implements HomePlugin, HomePluginEntryRoute {
  TaskListPlugin({required ServiceLocator locator, LocalizationCoordinator? localization})
      : _locator = locator,
        _localization = localization ?? LocalizationCoordinator.instance;

  static const String pluginId = 'task_list';

  final ServiceLocator _locator;
  final LocalizationCoordinator _localization;

  TaskListDependencies get _dependencies => _locator.get<TaskListDependencies>();

  @override
  String get id => pluginId;

  @override
  String get nameKey => 'taskList.title';

  @override
  String get descriptionKey => 'taskList.description';

  @override
  IconData get icon => AppIcons.listChecks;

  @override
  String get version => '0.1.0';

  /// La lista: desde la grilla del inicio se abre directamente.
  @override
  String get entryRoute => TaskListRoutes.base;

  @override
  Future<bool> isAvailable() async => true;

  /// Registra el idioma y las traducciones del plugin. La app lo llama al
  /// registrar el plugin, aunque esté desactivado, para que el catálogo pueda
  /// mostrar su nombre ([nameKey]). Es idempotente.
  void registerLocalization() {
    _localization.register(
      pluginId,
      (String code) => i18n.LocaleSettings.setLocaleRawSync(code),
      translate: (String key) {
        final Object? value = i18n.taskListStrings[key];
        return value is String ? value : null;
      },
      override: (String code, Map<String, Object?> overrides) =>
          i18n.LocaleSettings.instance.overrideTranslationsFromMapSync(
            locale: i18n.AppLocaleUtils.parse(code),
            isFlatMap: false,
            map: overrides,
          ),
    );
  }

  @override
  Future<void> initialize() async {
    registerLocalization();
    await _locator.pushScope(
      pluginId,
      init: (ServiceLocator locator) async {
        final TaskListRepository repository = locator.get<TaskListRepository>();
        final IdGenerator ids =
            locator.isRegistered<IdGenerator>() ? locator.get<IdGenerator>() : const UuidV4Generator();
        final Clock clock = locator.isRegistered<Clock>() ? locator.get<Clock>() : const SystemClock();
        await EnsureDefaultTaskCategories(repository, ids)();
        locator.registerSingleton(
          TaskListDependencies(
            createTask: CreateTask(repository, ids, clock),
            updateTask: UpdateTask(repository, clock),
            getTask: GetTask(repository),
            deleteTasks: DeleteTasks(repository, clock),
            completeTask: CompleteTask(repository, clock),
            undoCompletion: UndoTaskCompletion(repository, clock),
            reopenTask: ReopenTask(repository, clock),
            clearDone: ClearDoneTasks(repository, clock),
            createCategory: CreateTaskCategory(repository, ids, categoryName),
            renameCategory: RenameTaskCategory(repository, categoryName),
            countCategoryUsage: CountTaskCategoryUsage(repository),
            deleteCategory: DeleteTaskCategory(repository, clock),
            reorderCategories: ReorderTaskCategories(repository),
            watchList: WatchTaskList(repository, clock),
            watchCategories: WatchTaskCategories(repository),
            today: clock.today,
          ),
        );
      },
    );
  }

  @override
  Future<void> dispose() => _locator.dropScope(pluginId);

  @override
  Widget buildDashboardTile(BuildContext context) => TaskListDashboardTile(watchList: _dependencies.watchList);

  @override
  List<RouteBase> get routes => <RouteBase>[
        GoRoute(
          path: TaskListRoutes.base,
          builder: (BuildContext context, GoRouterState state) => BlocProvider<TaskListCubit>(
            create: (_) => _listCubit(),
            child: const TaskListScreen(),
          ),
        ),
        GoRoute(
          path: TaskListRoutes.done,
          builder: (BuildContext context, GoRouterState state) => BlocProvider<TaskListCubit>(
            create: (_) => _listCubit(),
            child: const DoneTasksScreen(),
          ),
        ),
        GoRoute(
          path: TaskListRoutes.create,
          builder: (BuildContext context, GoRouterState state) => _taskForm(null),
        ),
        GoRoute(
          path: TaskListRoutes.editPattern,
          builder: (BuildContext context, GoRouterState state) => _taskForm(state.pathParameters['id']),
        ),
        GoRoute(
          path: TaskListRoutes.categories,
          builder: (BuildContext context, GoRouterState state) {
            final TaskListDependencies deps = _dependencies;
            return BlocProvider<TaskCategoriesCubit>(
              create: (_) => TaskCategoriesCubit(
                watchCategories: deps.watchCategories,
                createCategory: deps.createCategory,
                renameCategory: deps.renameCategory,
                countUsage: deps.countCategoryUsage,
                deleteCategory: deps.deleteCategory,
                reorderCategories: deps.reorderCategories,
              ),
              child: const TaskCategoriesScreen(),
            );
          },
        ),
      ];

  TaskListCubit _listCubit() {
    final TaskListDependencies deps = _dependencies;
    return TaskListCubit(
      watchList: deps.watchList,
      completeTask: deps.completeTask,
      undoCompletion: deps.undoCompletion,
      reopenTask: deps.reopenTask,
      clearDone: deps.clearDone,
    );
  }

  Widget _taskForm(String? taskId) {
    final TaskListDependencies deps = _dependencies;
    return BlocProvider<TaskFormCubit>(
      create: (_) => TaskFormCubit(
        taskId: taskId,
        getTask: deps.getTask,
        watchCategories: deps.watchCategories,
        createTask: deps.createTask,
        updateTask: deps.updateTask,
        deleteTasks: deps.deleteTasks,
      ),
      child: TaskFormScreen(today: deps.today),
    );
  }
}
