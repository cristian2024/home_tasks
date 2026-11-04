import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import '../entities/shopping_item.dart';
import '../entities/shopping_purchase.dart';
import '../repositories/shopping_list_repository.dart';
import 'shopping_list_codec.dart';
import 'shopping_list_resolver.dart';
import 'shopping_list_sync_store.dart';

/// La lista de compras en la sincronización (spec §10.4.5). Trabaja sobre los
/// contratos del repositorio, así que sirve con cualquier implementación.
///
/// - [applyRemote] fusiona los cambios en las copias sincronizadas, calcula
///   con [ShoppingListResolver] lo que debe leer la app y lo guarda con
///   [ShoppingListSyncStore.commitSync]. Devuelve los conflictos actuales.
/// - [resolveConflict] aplica la opción elegida con escrituras normales del
///   repositorio, que se registran y se sincronizan.
class ShoppingListSyncParticipant implements SyncParticipant {
  ShoppingListSyncParticipant({
    required ShoppingListSyncStore store,
    required ShoppingListRepository repository,
    ShoppingListResolver resolver = const ShoppingListResolver(),
    Clock clock = const SystemClock(),
  })  : _store = store,
        _repository = repository,
        _resolver = resolver,
        _clock = clock;

  final ShoppingListSyncStore _store;
  final ShoppingListRepository _repository;
  final ShoppingListResolver _resolver;
  final Clock _clock;

  @override
  Set<String> get collections => ShoppingListCollections.all;

  @override
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records) async {
    final Map<String, Map<String, SyncedEntity>> copies = <String, Map<String, SyncedEntity>>{
      for (final String collection in ShoppingListCollections.all) collection: await _load(collection),
    };
    final ShoppingSyncView before = _resolve(copies);
    final Map<String, SyncedEntity> changed = <String, SyncedEntity>{};
    for (final ChangeRecord record in records) {
      final Map<String, SyncedEntity> entities = copies[record.collection]!;
      final SyncedEntity current =
          entities[record.entityId] ?? SyncedEntity(collection: record.collection, id: record.entityId);
      final SyncedEntity merged = current.merge(record);
      if (merged != current) {
        entities[record.entityId] = merged;
        changed['${record.collection}|${record.entityId}'] = merged;
      }
    }
    final ShoppingSyncView after = _resolve(copies);
    final ShoppingListSyncCommit commit = ShoppingListSyncCommit(
      entities: changed.values.toList(),
      items: _changes(before.items, after.items),
      categories: _changes(before.categories, after.categories),
      purchases: _changes(before.purchases, after.purchases),
    );
    if (!commit.isEmpty) {
      await _store.commitSync(commit);
    }
    return after.conflicts;
  }

  /// Con una compra, se borra la que no cuenta. Con dos, se vuelve a
  /// registrar como posterior a la que contaba, así deja de ser concurrente,
  /// y el item toma la fecha de la más reciente.
  @override
  Future<void> resolveConflict(SyncConflict conflict, String optionId) async {
    final [String itemId, _, String otherId] = conflict.entityIds;
    final ShoppingItem? item = await _repository.getItem(itemId);
    if (item == null) {
      return;
    }
    final DateTime now = _clock.nowUtc();
    if (optionId == ShoppingListResolver.oneOption) {
      await _repository.undoPurchase(item.copyWith(updatedAt: now), otherId, deletedAt: now);
      return;
    }
    final SyncedEntity? copy = (await _load(ShoppingListCollections.purchases))[otherId];
    final ShoppingPurchase? other = copy == null ? null : ShoppingListCodec.purchaseOf(copy);
    if (other == null) {
      return;
    }
    final DateTime? last = item.lastPurchasedAt;
    await _repository.recordPurchase(
      item.copyWith(
        lastPurchasedAt: () => last == null || other.purchasedAt.isAfter(last) ? other.purchasedAt : last,
        updatedAt: now,
      ),
      other,
    );
  }

  ShoppingSyncView _resolve(Map<String, Map<String, SyncedEntity>> copies) => _resolver.resolve(
        copies[ShoppingListCollections.items]!.values,
        copies[ShoppingListCollections.categories]!.values,
        copies[ShoppingListCollections.purchases]!.values,
      );

  static List<ShoppingResolved<T>> _changes<T>(
    Map<String, ShoppingResolved<T>> before,
    Map<String, ShoppingResolved<T>> after,
  ) =>
      <ShoppingResolved<T>>[
        for (final MapEntry<String, ShoppingResolved<T>>(:String key, :ShoppingResolved<T> value) in after.entries)
          if (before[key] != value) value,
      ];

  Future<Map<String, SyncedEntity>> _load(String collection) async => <String, SyncedEntity>{
        for (final SyncedEntity entity in await _store.syncedEntities(collection)) entity.id: entity,
      };
}
