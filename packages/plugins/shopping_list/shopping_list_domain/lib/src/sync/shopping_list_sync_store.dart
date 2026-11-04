import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import '../entities/shopping_category.dart';
import '../entities/shopping_item.dart';
import '../entities/shopping_purchase.dart';
import 'shopping_list_resolver.dart';

/// Lo que el participante escribe tras aplicar cambios recibidos: las copias
/// sincronizadas que cambiaron y lo que la app debe leer desde entonces.
class ShoppingListSyncCommit extends Equatable {
  ShoppingListSyncCommit({
    List<SyncedEntity> entities = const <SyncedEntity>[],
    List<ShoppingResolved<ShoppingItem>> items = const <ShoppingResolved<ShoppingItem>>[],
    List<ShoppingResolved<ShoppingCategory>> categories = const <ShoppingResolved<ShoppingCategory>>[],
    List<ShoppingResolved<ShoppingPurchase>> purchases = const <ShoppingResolved<ShoppingPurchase>>[],
  })  : entities = List<SyncedEntity>.unmodifiable(entities),
        items = List<ShoppingResolved<ShoppingItem>>.unmodifiable(items),
        categories = List<ShoppingResolved<ShoppingCategory>>.unmodifiable(categories),
        purchases = List<ShoppingResolved<ShoppingPurchase>>.unmodifiable(purchases);

  final List<SyncedEntity> entities;
  final List<ShoppingResolved<ShoppingItem>> items;
  final List<ShoppingResolved<ShoppingCategory>> categories;
  final List<ShoppingResolved<ShoppingPurchase>> purchases;

  bool get isEmpty => entities.isEmpty && items.isEmpty && categories.isEmpty && purchases.isEmpty;

  @override
  List<Object?> get props => <Object?>[entities, items, categories, purchases];
}

/// Almacén de las copias sincronizadas de la lista de compras. Lo implementa
/// cada repositorio junto a `ShoppingListRepository`.
///
/// Las escrituras locales del repositorio actualizan las copias y registran
/// sus cambios en la misma transacción. Las de [commitSync] no registran
/// nada: vienen de otro dispositivo.
abstract interface class ShoppingListSyncStore {
  /// Copias sincronizadas de [collection], también las borradas y las
  /// incompletas.
  Future<List<SyncedEntity>> syncedEntities(String collection);

  /// Guarda [commit] de forma atómica, sin registrar cambios: reemplaza las
  /// copias de `entities` y deja items, categorías y compras como los leerá
  /// la app, activos o borrados.
  Future<void> commitSync(ShoppingListSyncCommit commit);
}
