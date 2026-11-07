import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../domain/use_cases/category_use_cases.dart';
import '../../domain/use_cases/list_queries.dart';

class TaskCategoriesState extends Equatable {
  const TaskCategoriesState({this.loading = true, this.categories = const <TaskCategory>[], this.error});

  final bool loading;
  final List<TaskCategory> categories;
  final Object? error;

  TaskCategoriesState copyWith({bool? loading, List<TaskCategory>? categories, Object? Function()? error}) =>
      TaskCategoriesState(
        loading: loading ?? this.loading,
        categories: categories ?? this.categories,
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => <Object?>[loading, categories, error];
}

/// Crear, renombrar, reordenar y borrar categorías.
class TaskCategoriesCubit extends Cubit<TaskCategoriesState> {
  TaskCategoriesCubit({
    required WatchTaskCategories watchCategories,
    required CreateTaskCategory createCategory,
    required RenameTaskCategory renameCategory,
    required CountTaskCategoryUsage countUsage,
    required DeleteTaskCategory deleteCategory,
    required ReorderTaskCategories reorderCategories,
  })  : _createCategory = createCategory,
        _renameCategory = renameCategory,
        _countUsage = countUsage,
        _deleteCategory = deleteCategory,
        _reorderCategories = reorderCategories,
        super(const TaskCategoriesState()) {
    _subscription = watchCategories().listen(
      (List<TaskCategory> categories) => emit(state.copyWith(loading: false, categories: categories)),
    );
  }

  final CreateTaskCategory _createCategory;
  final RenameTaskCategory _renameCategory;
  final CountTaskCategoryUsage _countUsage;
  final DeleteTaskCategory _deleteCategory;
  final ReorderTaskCategories _reorderCategories;
  late final StreamSubscription<List<TaskCategory>> _subscription;

  /// Devuelve si la creó.
  Future<bool> create(String name) => _run(() => _createCategory(name));

  /// Devuelve si la renombró.
  Future<bool> rename(String categoryId, String name) => _run(() => _renameCategory(categoryId, name));

  Future<int> usage(String categoryId) => _countUsage(categoryId);

  Future<bool> delete(String categoryId) => _run(() => _deleteCategory(categoryId));

  /// Mueve la categoría [index] una posición hacia arriba (`-1`) o abajo (`1`).
  Future<bool> move(int index, int offset) {
    final List<String> ids = <String>[for (final TaskCategory category in state.categories) category.id];
    final int target = index + offset;
    if (target < 0 || target >= ids.length) {
      return Future<bool>.value(false);
    }
    ids.insert(target, ids.removeAt(index));
    return _run(() => _reorderCategories(ids));
  }

  void clearError() => emit(state.copyWith(error: () => null));

  Future<bool> _run(Future<Object?> Function() action) async {
    try {
      await action();
      return true;
    } on Object catch (error) {
      emit(state.copyWith(error: () => error));
      return false;
    }
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
