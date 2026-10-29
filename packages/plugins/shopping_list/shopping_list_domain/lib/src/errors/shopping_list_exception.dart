/// Errores de negocio de la lista de compras. Es `sealed` para que la
/// presentación los trate todos de forma exhaustiva.
sealed class ShoppingListException implements Exception {
  const ShoppingListException();
}

final class ShoppingItemNotFoundException extends ShoppingListException {
  const ShoppingItemNotFoundException(this.itemId);

  final String itemId;

  @override
  String toString() => 'ShoppingItemNotFoundException($itemId)';
}

final class ShoppingCategoryNotFoundException extends ShoppingListException {
  const ShoppingCategoryNotFoundException(this.categoryId);

  final String categoryId;

  @override
  String toString() => 'ShoppingCategoryNotFoundException($categoryId)';
}

/// Ya hay una categoría con ese nombre (sin distinguir mayúsculas).
final class ShoppingCategoryNameTakenException extends ShoppingListException {
  const ShoppingCategoryNameTakenException(this.name);

  final String name;

  @override
  String toString() => 'ShoppingCategoryNameTakenException($name)';
}

enum ShoppingValidationField { name, notes, quantity, categoryName }

enum ShoppingValidationReason { empty, tooLong }

final class ShoppingValidationException extends ShoppingListException {
  const ShoppingValidationException(this.field, this.reason);

  final ShoppingValidationField field;
  final ShoppingValidationReason reason;

  @override
  String toString() => 'ShoppingValidationException(${field.name}, ${reason.name})';
}
