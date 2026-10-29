import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../models/isar_shopping_category.dart';
import '../models/isar_shopping_item.dart';
import '../models/isar_shopping_purchase.dart';

/// Conversión bidireccional entre entidades de dominio y colecciones Isar.
///
/// Isar devuelve las fechas en hora local: al leer se convierten siempre a
/// UTC.
abstract final class ShoppingDataMapper {
  static IsarShoppingItem toIsarItem(ShoppingItem item) => IsarShoppingItem()
    ..id = item.id
    ..name = item.name
    ..notes = item.notes
    ..quantity = item.quantity
    ..urgency = item.urgency
    ..status = item.status
    ..categoryIds = item.categoryIds.toList()
    ..recurrenceMinDays = item.recurrence?.minDays
    ..recurrenceMaxDays = item.recurrence?.maxDays
    ..lastPurchasedAt = item.lastPurchasedAt?.toUtc()
    ..createdAt = item.createdAt.toUtc()
    ..updatedAt = item.updatedAt.toUtc();

  static ShoppingItem fromIsarItem(IsarShoppingItem model) {
    final int? minDays = model.recurrenceMinDays;
    final int? maxDays = model.recurrenceMaxDays;
    return ShoppingItem(
      id: model.id,
      name: model.name,
      notes: model.notes,
      quantity: model.quantity,
      urgency: model.urgency,
      status: model.status,
      categoryIds: List<String>.unmodifiable(model.categoryIds),
      recurrence: minDays == null || maxDays == null ? null : Recurrence.between(minDays, maxDays),
      lastPurchasedAt: model.lastPurchasedAt?.toUtc(),
      createdAt: model.createdAt.toUtc(),
      updatedAt: model.updatedAt.toUtc(),
    );
  }

  static IsarShoppingCategory toIsarCategory(ShoppingCategory category) => IsarShoppingCategory()
    ..id = category.id
    ..name = category.name
    ..defaultKey = category.defaultKey
    ..sortOrder = category.sortOrder;

  static ShoppingCategory fromIsarCategory(IsarShoppingCategory model) => ShoppingCategory(
        id: model.id,
        name: model.name,
        defaultKey: model.defaultKey,
        sortOrder: model.sortOrder,
      );

  static IsarShoppingPurchase toIsarPurchase(ShoppingPurchase purchase) => IsarShoppingPurchase()
    ..id = purchase.id
    ..itemId = purchase.itemId
    ..purchasedAt = purchase.purchasedAt.toUtc();

  static ShoppingPurchase fromIsarPurchase(IsarShoppingPurchase model) =>
      ShoppingPurchase(id: model.id, itemId: model.itemId, purchasedAt: model.purchasedAt.toUtc());
}
