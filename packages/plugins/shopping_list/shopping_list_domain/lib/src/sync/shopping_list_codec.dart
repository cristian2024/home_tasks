import 'package:core_sync/core_sync.dart';
import 'package:recurrence/recurrence.dart';
import 'package:urgency/urgency.dart';

import '../entities/shopping_category.dart';
import '../entities/shopping_item.dart';
import '../entities/shopping_purchase.dart';

/// Colecciones de la lista de compras en la sincronización.
abstract final class ShoppingListCollections {
  static const String items = 'shopping_list.items';
  static const String categories = 'shopping_list.categories';
  static const String purchases = 'shopping_list.purchases';

  static const Set<String> all = <String>{items, categories, purchases};
}

/// Conversión entre las entidades de la lista de compras y sus campos
/// sincronizados.
///
/// Las fechas viajan en ISO 8601 (UTC) y los enums por su nombre.
/// `categoryIds` es un conjunto: se fusiona elemento a elemento. Los campos
/// de una escritura normal no llevan `deletedAt`, así que nunca deshacen un
/// borrado; el borrado se escribe con [deletion].
abstract final class ShoppingListCodec {
  static const String deletedAt = 'deletedAt';
  static const String categoryIds = 'categoryIds';
  static const String lastPurchasedAt = 'lastPurchasedAt';

  /// Compra anterior del mismo item que conocía el dispositivo al comprar.
  /// Dos compras con la misma son concurrentes.
  static const String previousPurchaseId = 'previousPurchaseId';

  static Map<String, Object?> itemFields(ShoppingItem item) {
    final Recurrence? recurrence = item.recurrence;
    return <String, Object?>{
      'name': item.name,
      'notes': item.notes,
      'quantity': item.quantity,
      'urgency': item.urgency.name,
      'status': item.status.name,
      categoryIds: item.categoryIds.toSet(),
      'recurrence': recurrence == null
          ? null
          : <String, Object?>{'minDays': recurrence.minDays, 'maxDays': recurrence.maxDays},
      lastPurchasedAt: _dateOrNull(item.lastPurchasedAt),
      'createdAt': _date(item.createdAt),
      'updatedAt': _date(item.updatedAt),
    };
  }

  /// El item, o `null` si a [entity] aún le falta algún campo obligatorio.
  /// Una recurrencia inválida se lee como ninguna.
  static ShoppingItem? itemOf(SyncedEntity entity) {
    final Map<String, Object?> fields = entity.fields;
    final Object? name = fields['name'];
    final Urgency? urgency = _enumOf(Urgency.values, fields['urgency']);
    final ShoppingItemStatus? status = _enumOf(ShoppingItemStatus.values, fields['status']);
    final Object? createdAt = fields['createdAt'];
    if (name is! String || urgency == null || status == null || createdAt is! String) {
      return null;
    }
    final Object? updatedAt = fields['updatedAt'];
    final Object? purchasedAt = fields[lastPurchasedAt];
    final Object? categories = fields[categoryIds];
    return ShoppingItem(
      id: entity.id,
      name: name,
      notes: fields['notes'] as String? ?? '',
      quantity: fields['quantity'] as String? ?? '',
      urgency: urgency,
      status: status,
      categoryIds: categories is List ? List<String>.unmodifiable(categories.whereType<String>()) : const <String>[],
      recurrence: _recurrenceOf(fields['recurrence']),
      lastPurchasedAt: purchasedAt is String ? DateTime.parse(purchasedAt) : null,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt is String ? DateTime.parse(updatedAt) : DateTime.parse(createdAt),
    );
  }

  static Map<String, Object?> categoryFields(ShoppingCategory category) => <String, Object?>{
        'name': category.name,
        'defaultKey': category.defaultKey,
        'sortOrder': category.sortOrder,
      };

  /// La categoría, o `null` si a [entity] le falta el orden o no tiene ni
  /// nombre ni clave por defecto.
  static ShoppingCategory? categoryOf(SyncedEntity entity) {
    final Map<String, Object?> fields = entity.fields;
    final Object? sortOrder = fields['sortOrder'];
    final Object? name = fields['name'];
    final Object? defaultKey = fields['defaultKey'];
    if (sortOrder is! int || (name is! String && defaultKey is! String)) {
      return null;
    }
    return ShoppingCategory(
      id: entity.id,
      sortOrder: sortOrder,
      name: name is String ? name : null,
      defaultKey: defaultKey is String ? defaultKey : null,
    );
  }

  /// Campos de una compra nueva. [previousPurchase] es la última compra
  /// activa del item que había en el dispositivo, o `null`.
  static Map<String, Object?> purchaseFields(ShoppingPurchase purchase, {required String? previousPurchase}) =>
      <String, Object?>{
        'itemId': purchase.itemId,
        'purchasedAt': _date(purchase.purchasedAt),
        previousPurchaseId: previousPurchase,
      };

  /// La compra, o `null` si a [entity] le falta algún campo.
  static ShoppingPurchase? purchaseOf(SyncedEntity entity) {
    final Object? itemId = entity.fields['itemId'];
    final Object? purchasedAt = entity.fields['purchasedAt'];
    if (itemId is! String || purchasedAt is! String) {
      return null;
    }
    return ShoppingPurchase(id: entity.id, itemId: itemId, purchasedAt: DateTime.parse(purchasedAt));
  }

  static String? previousPurchaseOf(SyncedEntity entity) => entity.fields[previousPurchaseId] as String?;

  /// Campos que borran una entidad en [at].
  static Map<String, Object?> deletion(DateTime at) => <String, Object?>{deletedAt: _date(at)};

  /// Momento del borrado guardado en [entity], o `null` si no está borrada.
  static DateTime? deletedAtOf(SyncedEntity entity) {
    final Object? value = entity.fields[deletedAt];
    return value is String ? DateTime.parse(value) : null;
  }

  static String _date(DateTime value) => value.toUtc().toIso8601String();

  static String? _dateOrNull(DateTime? value) => value == null ? null : _date(value);

  static T? _enumOf<T extends Enum>(List<T> values, Object? name) =>
      values.where((T value) => value.name == name).firstOrNull;

  static Recurrence? _recurrenceOf(Object? value) {
    if (value is! Map || value['minDays'] is! int || value['maxDays'] is! int) {
      return null;
    }
    try {
      return Recurrence.between(value['minDays'] as int, value['maxDays'] as int);
    } on ArgumentError {
      return null;
    }
  }
}
