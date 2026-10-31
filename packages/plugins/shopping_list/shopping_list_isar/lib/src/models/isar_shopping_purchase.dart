import 'package:storage_isar/adapter.dart';

part 'isar_shopping_purchase.g.dart';

@collection
class IsarShoppingPurchase {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id; // UUID v4

  @Index(composite: <CompositeIndex>[CompositeIndex('purchasedAt')])
  late String itemId;

  late DateTime purchasedAt;

  /// Borrado lógico (compra deshecha, item borrado o compra que no cuenta):
  /// `null` si está activa.
  DateTime? deletedAt;
}
