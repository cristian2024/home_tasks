import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';
import 'package:recurrence/recurrence.dart';

import '../entities/shopping_category.dart';
import '../entities/shopping_item.dart';
import '../entities/shopping_purchase.dart';
import 'shopping_list_codec.dart';

/// Un item, una categoría o una compra tal como lo lee la app: activo o, si
/// no, con el momento desde el que no se muestra.
class ShoppingResolved<T> extends Equatable {
  const ShoppingResolved(this.entity, {this.deletedAt});

  final T entity;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => <Object?>[entity, deletedAt];
}

/// Resultado de [ShoppingListResolver.resolve].
class ShoppingSyncView extends Equatable {
  ShoppingSyncView({
    required Map<String, ShoppingResolved<ShoppingItem>> items,
    required Map<String, ShoppingResolved<ShoppingCategory>> categories,
    required Map<String, ShoppingResolved<ShoppingPurchase>> purchases,
    required List<SyncConflict> conflicts,
  })  : items = Map<String, ShoppingResolved<ShoppingItem>>.unmodifiable(items),
        categories = Map<String, ShoppingResolved<ShoppingCategory>>.unmodifiable(categories),
        purchases = Map<String, ShoppingResolved<ShoppingPurchase>>.unmodifiable(purchases),
        conflicts = List<SyncConflict>.unmodifiable(conflicts);

  /// Entidades completas, por id.
  final Map<String, ShoppingResolved<ShoppingItem>> items;
  final Map<String, ShoppingResolved<ShoppingCategory>> categories;
  final Map<String, ShoppingResolved<ShoppingPurchase>> purchases;

  /// Conflictos de reglas de negocio, ordenados por id.
  final List<SyncConflict> conflicts;

  @override
  List<Object?> get props => <Object?>[items, categories, purchases, conflicts];
}

/// Calcula, a partir de las copias sincronizadas, lo que lee la app y los
/// conflictos (spec §10.4.4). Es una función pura del estado: todos los
/// dispositivos llegan al mismo resultado, sin importar en qué orden
/// recibieron los cambios, y sin escribir cambios nuevos.
///
/// - **Categorías por defecto repetidas** (las sembró cada dispositivo): de
///   las que tienen la misma `defaultKey` queda la de id menor. Las demás no
///   se muestran y sus items pasan a la que queda. Sin conflicto.
/// - **Categoría borrada** mientras otro la añade a un item: la referencia se
///   ignora. Sin conflicto.
/// - **Compras de un item borrado:** no se muestran.
/// - **Compra doble:** dos compras activas del mismo item hechas sobre la
///   misma compra anterior (ninguna sabía de la otra), y, si el item se
///   repite, a menos de `minDays` días una de otra. Cuenta la de menor marca;
///   la otra no se muestra y, si fue la que puso `lastPurchasedAt` en el
///   item, el item toma la fecha de la que cuenta. Conflicto
///   `doublePurchase`.
class ShoppingListResolver {
  const ShoppingListResolver();

  static const String doublePurchase = 'doublePurchase';

  /// Prefijo de los ids de conflicto de la lista de compras.
  static const String conflictPrefix = 'shopping_list.';

  /// Opciones de `doublePurchase`: contar solo una compra o las dos.
  static const String oneOption = 'one';
  static const String twoOption = 'two';

  ShoppingSyncView resolve(
    Iterable<SyncedEntity> items,
    Iterable<SyncedEntity> categories,
    Iterable<SyncedEntity> purchases,
  ) {
    final Map<String, String> aliases = <String, String>{};
    final Map<String, ShoppingResolved<ShoppingCategory>> resolvedCategories = _categories(categories, aliases);
    final Map<String, (ShoppingItem, SyncedEntity)> completeItems = <String, (ShoppingItem, SyncedEntity)>{
      for (final SyncedEntity entity in items)
        if (ShoppingListCodec.itemOf(entity) case final ShoppingItem item) entity.id: (item, entity),
    };
    final Map<String, DateTime> lastPurchases = <String, DateTime>{};
    final List<SyncConflict> conflicts = <SyncConflict>[];
    final Map<String, ShoppingResolved<ShoppingPurchase>> resolvedPurchases =
        _purchases(purchases, completeItems, lastPurchases, conflicts);
    conflicts.sort((SyncConflict a, SyncConflict b) => a.id.compareTo(b.id));
    return ShoppingSyncView(
      items: <String, ShoppingResolved<ShoppingItem>>{
        for (final MapEntry<String, (ShoppingItem, SyncedEntity)>(:String key, value: (ShoppingItem item, SyncedEntity entity))
            in completeItems.entries)
          key: ShoppingResolved<ShoppingItem>(
            item.copyWith(
              categoryIds: _categoryIds(item, aliases, resolvedCategories),
              lastPurchasedAt: lastPurchases.containsKey(key) ? () => lastPurchases[key] : null,
            ),
            deletedAt: ShoppingListCodec.deletedAtOf(entity),
          ),
      },
      categories: resolvedCategories,
      purchases: resolvedPurchases,
      conflicts: conflicts,
    );
  }

  /// Las categorías completas. Apunta en [aliases] las repetidas por
  /// `defaultKey` y la que queda en su lugar.
  Map<String, ShoppingResolved<ShoppingCategory>> _categories(
    Iterable<SyncedEntity> entities,
    Map<String, String> aliases,
  ) {
    final List<(ShoppingCategory, SyncedEntity)> complete = <(ShoppingCategory, SyncedEntity)>[
      for (final SyncedEntity entity in entities)
        if (ShoppingListCodec.categoryOf(entity) case final ShoppingCategory category) (category, entity),
    ]..sort(((ShoppingCategory, SyncedEntity) a, (ShoppingCategory, SyncedEntity) b) => a.$1.id.compareTo(b.$1.id));
    final Map<String, String> kept = <String, String>{};
    final Map<String, ShoppingResolved<ShoppingCategory>> resolved = <String, ShoppingResolved<ShoppingCategory>>{};
    for (final (ShoppingCategory category, SyncedEntity entity) in complete) {
      final String? defaultKey = category.defaultKey;
      final String canonical = defaultKey == null ? category.id : kept.putIfAbsent(defaultKey, () => category.id);
      if (canonical != category.id) {
        aliases[category.id] = canonical;
      }
      resolved[category.id] = ShoppingResolved<ShoppingCategory>(
        category,
        deletedAt: ShoppingListCodec.deletedAtOf(entity) ??
            (canonical == category.id ? null : _wallTime(entity.metadata.createdHlc)),
      );
    }
    return resolved;
  }

  /// Categorías del item, ordenadas: las repetidas pasan a la que queda y las
  /// borradas se quitan. Las que aún no llegaron se conservan.
  static List<String> _categoryIds(
    ShoppingItem item,
    Map<String, String> aliases,
    Map<String, ShoppingResolved<ShoppingCategory>> categories,
  ) =>
      <String>{
        for (final String id in item.categoryIds)
          if (aliases[id] ?? id case final String effective when categories[effective]?.isDeleted != true) effective,
      }.toList()
        ..sort();

  Map<String, ShoppingResolved<ShoppingPurchase>> _purchases(
    Iterable<SyncedEntity> entities,
    Map<String, (ShoppingItem, SyncedEntity)> items,
    Map<String, DateTime> lastPurchases,
    List<SyncConflict> conflicts,
  ) {
    final Map<String, ShoppingResolved<ShoppingPurchase>> resolved = <String, ShoppingResolved<ShoppingPurchase>>{};
    final Map<String, List<_Purchase>> siblings = <String, List<_Purchase>>{};
    for (final SyncedEntity entity in entities) {
      final ShoppingPurchase? purchase = ShoppingListCodec.purchaseOf(entity);
      if (purchase == null) {
        continue;
      }
      final SyncedEntity? item = items[purchase.itemId]?.$2;
      final DateTime? deletedAt =
          ShoppingListCodec.deletedAtOf(entity) ?? (item == null ? null : ShoppingListCodec.deletedAtOf(item));
      resolved[purchase.id] = ShoppingResolved<ShoppingPurchase>(purchase, deletedAt: deletedAt);
      if (deletedAt == null && item != null) {
        siblings
            .putIfAbsent('${purchase.itemId}|${ShoppingListCodec.previousPurchaseOf(entity)}', () => <_Purchase>[])
            .add(_Purchase(purchase, entity));
      }
    }
    for (final List<_Purchase> group in siblings.values.where((List<_Purchase> group) => group.length > 1)) {
      group.sort(_Purchase.compareByCreation);
      final _Purchase kept = group.first;
      final (ShoppingItem item, SyncedEntity itemEntity) = items[kept.purchase.itemId]!;
      for (final _Purchase other in group.skip(1)) {
        if (!_sameWindow(item.recurrence, kept.purchase, other.purchase)) {
          continue;
        }
        resolved[other.purchase.id] = ShoppingResolved<ShoppingPurchase>(other.purchase, deletedAt: other.purchase.purchasedAt);
        if (itemEntity.metadata.hlcOf(ShoppingListCodec.lastPurchasedAt) == other.created) {
          lastPurchases[item.id] = kept.purchase.purchasedAt;
        }
        conflicts.add(SyncConflict(
          id: '$conflictPrefix$doublePurchase:${other.purchase.id}',
          collection: ShoppingListCollections.purchases,
          kind: doublePurchase,
          entityIds: <String>[item.id, kept.purchase.id, other.purchase.id],
          options: <ConflictOption>[
            ConflictOption(oneOption, details: <String, String>{'name': item.name}),
            ConflictOption(twoOption, details: <String, String>{'name': item.name}),
          ],
          provisionalOptionId: oneOption,
          detectedAt: _wallTime(other.created),
        ));
      }
    }
    return resolved;
  }

  /// Si [b] cae en la misma ventana que [a]: siempre en un item que no se
  /// repite; en uno que se repite, a menos de `minDays` días.
  static bool _sameWindow(Recurrence? recurrence, ShoppingPurchase a, ShoppingPurchase b) =>
      recurrence == null || a.purchasedAt.difference(b.purchasedAt).abs() < Duration(days: recurrence.minDays);

  static DateTime _wallTime(Hlc? hlc) => DateTime.fromMillisecondsSinceEpoch(hlc?.wallTime ?? 0, isUtc: true);
}

/// Una compra activa con la marca con que se registró.
class _Purchase {
  _Purchase(this.purchase, SyncedEntity entity) : created = entity.metadata.createdHlc ?? _origin;

  static final Hlc _origin = Hlc(wallTime: 0, counter: 0, deviceId: '-');

  final ShoppingPurchase purchase;
  final Hlc created;

  static int compareByCreation(_Purchase a, _Purchase b) {
    final int byHlc = a.created.compareTo(b.created);
    return byHlc != 0 ? byHlc : a.purchase.id.compareTo(b.purchase.id);
  }
}
