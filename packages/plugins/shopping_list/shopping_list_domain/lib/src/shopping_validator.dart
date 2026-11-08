import 'package:categories/categories.dart';

import 'errors/shopping_list_exception.dart';

/// Reglas de validación de los textos de la lista. Devuelven el valor
/// normalizado (sin espacios sobrantes) o lanzan
/// [ShoppingValidationException].
abstract final class ShoppingValidator {
  static const int maxNameLength = 120;
  static const int maxNotesLength = 2000;
  static const int maxQuantityLength = 40;
  static const int maxCategoryNameLength = ListCategories.maxNameLength;

  static String name(String value) => _required(value.trim(), ShoppingValidationField.name, maxNameLength);

  static String notes(String value) => _optional(value.trim(), ShoppingValidationField.notes, maxNotesLength);

  static String quantity(String value) =>
      _optional(value.trim(), ShoppingValidationField.quantity, maxQuantityLength);

  static String categoryName(String value) {
    final String name = value.trim();
    return switch (ListCategories.problemWith(name)) {
      null => name,
      CategoryNameProblem.empty => throw const ShoppingValidationException(
          ShoppingValidationField.categoryName,
          ShoppingValidationReason.empty,
        ),
      CategoryNameProblem.tooLong => throw const ShoppingValidationException(
          ShoppingValidationField.categoryName,
          ShoppingValidationReason.tooLong,
        ),
    };
  }

  /// Forma con que se comparan nombres (de items o de categorías): sin
  /// mayúsculas ni espacios de sobra.
  static String normalize(String value) => ListCategories.normalize(value);

  static String _required(String value, ShoppingValidationField field, int maxLength) {
    if (value.isEmpty) {
      throw ShoppingValidationException(field, ShoppingValidationReason.empty);
    }
    return _optional(value, field, maxLength);
  }

  static String _optional(String value, ShoppingValidationField field, int maxLength) {
    if (value.length > maxLength) {
      throw ShoppingValidationException(field, ShoppingValidationReason.tooLong);
    }
    return value;
  }
}
