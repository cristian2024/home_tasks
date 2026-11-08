import 'package:categories/categories.dart';

import 'errors/task_list_exception.dart';

/// Reglas de validación de los textos de la lista. Devuelven el valor
/// normalizado (sin espacios sobrantes) o lanzan [TaskValidationException].
abstract final class TaskValidator {
  static const int maxTitleLength = 100;
  static const int maxCategoryNameLength = ListCategories.maxNameLength;

  static String title(String value) {
    final String title = value.trim();
    if (title.isEmpty) {
      throw const TaskValidationException(TaskValidationField.title, TaskValidationReason.empty);
    }
    if (title.length > maxTitleLength) {
      throw const TaskValidationException(TaskValidationField.title, TaskValidationReason.tooLong);
    }
    return title;
  }

  static String categoryName(String value) {
    final String name = value.trim();
    return switch (ListCategories.problemWith(name)) {
      null => name,
      CategoryNameProblem.empty =>
        throw const TaskValidationException(TaskValidationField.categoryName, TaskValidationReason.empty),
      CategoryNameProblem.tooLong =>
        throw const TaskValidationException(TaskValidationField.categoryName, TaskValidationReason.tooLong),
    };
  }
}
