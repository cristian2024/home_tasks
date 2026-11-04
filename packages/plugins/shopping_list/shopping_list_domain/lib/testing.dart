/// Dobles de prueba y tests de contrato del dominio de la lista de compras.
library;

import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import 'shopping_list_domain.dart';

export 'src/testing/shopping_list_repository_contract.dart';
export 'src/testing/shopping_list_sync_fixtures.dart';

/// [ShoppingListRepository] en memoria, para tests y apps de ejemplo. Cumple
/// `shoppingListRepositoryContract`.
///
/// Con [hlcClock] y [changeLog] además se sincroniza: cada escritura local
/// actualiza sus copias sincronizadas y añade sus registros al log, y como
/// [ShoppingListSyncStore] sirve a `ShoppingListSyncParticipant`. Pasa
/// `shoppingListSyncContract`.
class InMemoryShoppingListRepository implements ShoppingListRepository, ShoppingListSyncStore {
  InMemoryShoppingListRepository({HlcClock? hlcClock, ChangeLog? changeLog, IdGenerator ids = const UuidV4Generator()})
      : _recorder = hlcClock == null ? null : LocalSyncRecorder(hlcClock: hlcClock, ids: ids),
        _changeLog = changeLog;

  final LocalSyncRecorder? _recorder;
  final ChangeLog? _changeLog;
  final Map<String, SyncedEntity> _synced = <String, SyncedEntity>{};

  final Map<String, ShoppingItem> _items = <String, ShoppingItem>{};
  final Map<String, ShoppingCategory> _categories = <String, ShoppingCategory>{};
  final Map<String, ShoppingPurchase> _purchases = <String, ShoppingPurchase>{};

  /// IDs borrados (o que la sincronización no muestra) de cada colección.
  final Map<String, Set<String>> _deleted = <String, Set<String>>{
    for (final String collection in ShoppingListCollections.all) collection: <String>{},
  };
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  bool _seeded = false;

  @override
  Future<void> saveItem(ShoppingItem item) async {
    if (_isDeleted(ShoppingListCollections.items, item.id)) {
      return;
    }
    _items[item.id] = item;
    await _record(<LocalSyncWrite>[_itemWrite(item)]);
    _changed();
  }

  @override
  Future<ShoppingItem?> getItem(String id) async => _items[id];

  @override
  Future<List<ShoppingItem>> getItems() async => _items.values.toList();

  @override
  Stream<List<ShoppingItem>> watchItems() => _watch(() => _items.values.toList());

  @override
  Future<void> deleteItems(List<String> ids, {required DateTime deletedAt}) async {
    final List<LocalSyncWrite> writes = <LocalSyncWrite>[];
    for (final String id in ids) {
      if (_items.remove(id) == null) {
        continue;
      }
      writes.add(_deletion(ShoppingListCollections.items, id, deletedAt));
      for (final ShoppingPurchase purchase in _purchases.values.where((ShoppingPurchase p) => p.itemId == id).toList()) {
        _purchases.remove(purchase.id);
        writes.add(_deletion(ShoppingListCollections.purchases, purchase.id, deletedAt));
      }
    }
    await _record(writes);
    _changed();
  }

  @override
  Future<void> saveCategories(List<ShoppingCategory> categories) async {
    final List<ShoppingCategory> active = <ShoppingCategory>[
      for (final ShoppingCategory category in categories)
        if (!_isDeleted(ShoppingListCollections.categories, category.id)) category,
    ];
    for (final ShoppingCategory category in active) {
      _categories[category.id] = category;
    }
    await _record(active.map(_categoryWrite).toList());
    _changed();
  }

  @override
  Future<List<ShoppingCategory>> getCategories() async => _sortedCategories();

  @override
  Stream<List<ShoppingCategory>> watchCategories() => _watch(_sortedCategories);

  @override
  Future<void> deleteCategory(String id, {required DateTime updatedAt}) async {
    if (_categories.remove(id) == null) {
      return;
    }
    final List<LocalSyncWrite> writes = <LocalSyncWrite>[_deletion(ShoppingListCollections.categories, id, updatedAt)];
    for (final ShoppingItem item in _items.values.toList()) {
      if (item.categoryIds.contains(id)) {
        final ShoppingItem updated = item.copyWith(
          categoryIds: <String>[for (final String categoryId in item.categoryIds) if (categoryId != id) categoryId],
          updatedAt: updatedAt,
        );
        _items[item.id] = updated;
        writes.add(_itemWrite(updated));
      }
    }
    await _record(writes);
    _changed();
  }

  @override
  Future<bool> seedDefaultCategories(List<ShoppingCategory> defaults) async {
    if (_seeded) {
      return false;
    }
    _seeded = true;
    await saveCategories(defaults);
    return true;
  }

  @override
  Future<void> recordPurchase(ShoppingItem item, ShoppingPurchase purchase) async {
    if (_isDeleted(ShoppingListCollections.items, item.id)) {
      return;
    }
    final String? previous = _latestPurchase(purchase.itemId, except: purchase.id)?.id;
    _items[item.id] = item;
    _purchases[purchase.id] = purchase;
    _deleted[ShoppingListCollections.purchases]!.remove(purchase.id);
    await _record(<LocalSyncWrite>[
      _itemWrite(item),
      _write(
        ShoppingListCollections.purchases,
        purchase.id,
        ShoppingListCodec.purchaseFields(purchase, previousPurchase: previous),
      ),
    ]);
    _changed();
  }

  @override
  Future<void> undoPurchase(ShoppingItem item, String purchaseId, {required DateTime deletedAt}) async {
    final bool known = _purchases.remove(purchaseId) != null || _isDeleted(ShoppingListCollections.purchases, purchaseId);
    final bool itemActive = !_isDeleted(ShoppingListCollections.items, item.id);
    if (itemActive) {
      _items[item.id] = item;
    }
    if (known) {
      _deleted[ShoppingListCollections.purchases]!.add(purchaseId);
    }
    await _record(<LocalSyncWrite>[
      if (itemActive) _itemWrite(item),
      if (known) _deletion(ShoppingListCollections.purchases, purchaseId, deletedAt),
    ]);
    _changed();
  }

  @override
  Future<List<ShoppingPurchase>> getPurchases(String itemId) async => _purchases.values
      .where((ShoppingPurchase purchase) => purchase.itemId == itemId)
      .toList()
    ..sort(_newestFirst);

  @override
  Future<List<SyncedEntity>> syncedEntities(String collection) async => <SyncedEntity>[
        for (final SyncedEntity entity in _synced.values)
          if (entity.collection == collection) entity,
      ];

  @override
  Future<void> commitSync(ShoppingListSyncCommit commit) async {
    for (final SyncedEntity entity in commit.entities) {
      _synced['${entity.collection}|${entity.id}'] = entity;
    }
    _apply(ShoppingListCollections.items, commit.items, _items, (ShoppingItem item) => item.id);
    _apply(ShoppingListCollections.categories, commit.categories, _categories, (ShoppingCategory c) => c.id);
    _apply(ShoppingListCollections.purchases, commit.purchases, _purchases, (ShoppingPurchase p) => p.id);
    _changed();
  }

  /// Libera los streams abiertos.
  Future<void> close() => _changes.close();

  void _apply<T>(String collection, List<ShoppingResolved<T>> resolved, Map<String, T> active, String Function(T) idOf) {
    for (final ShoppingResolved<T> entry in resolved) {
      final String id = idOf(entry.entity);
      if (entry.isDeleted) {
        active.remove(id);
        _deleted[collection]!.add(id);
      } else {
        active[id] = entry.entity;
        _deleted[collection]!.remove(id);
      }
    }
  }

  bool _isDeleted(String collection, String id) => _deleted[collection]!.contains(id);

  ShoppingPurchase? _latestPurchase(String itemId, {required String except}) => (_purchases.values
          .where((ShoppingPurchase purchase) => purchase.itemId == itemId && purchase.id != except)
          .toList()
        ..sort(_newestFirst))
      .firstOrNull;

  static int _newestFirst(ShoppingPurchase a, ShoppingPurchase b) {
    final int byDate = b.purchasedAt.compareTo(a.purchasedAt);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  }

  List<ShoppingCategory> _sortedCategories() => ShoppingListView.sortCategories(_categories.values.toList());

  LocalSyncWrite _itemWrite(ShoppingItem item) =>
      _write(ShoppingListCollections.items, item.id, ShoppingListCodec.itemFields(item));

  LocalSyncWrite _categoryWrite(ShoppingCategory category) =>
      _write(ShoppingListCollections.categories, category.id, ShoppingListCodec.categoryFields(category));

  LocalSyncWrite _deletion(String collection, String id, DateTime deletedAt) {
    _deleted[collection]!.add(id);
    return _write(collection, id, ShoppingListCodec.deletion(deletedAt));
  }

  LocalSyncWrite _write(String collection, String id, Map<String, Object?> fields) =>
      LocalSyncWrite(collection: collection, id: id, fields: fields, current: _synced['$collection|$id']);

  /// Con sincronización, actualiza las copias y añade los registros al log.
  Future<void> _record(List<LocalSyncWrite> writes) async {
    final LocalSyncRecorder? recorder = _recorder;
    final ChangeLog? log = _changeLog;
    if (recorder == null || log == null) {
      return;
    }
    final LocalSyncChanges changes = recorder.record(writes, nextSeq: (await log.vector())[recorder.deviceId] + 1);
    for (final SyncedEntity entity in changes.entities) {
      _synced['${entity.collection}|${entity.id}'] = entity;
    }
    await log.append(changes.records);
  }

  void _changed() => _changes.add(null);

  /// Emite [read] al suscribirse y con cada cambio. El valor inicial se emite
  /// en `onListen`, así que no se pierde una escritura hecha justo después de
  /// suscribirse.
  Stream<T> _watch<T>(T Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? changes;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        changes = _changes.stream.listen((_) => controller.add(read()));
      },
      // No devuelve el futuro de cancel(): `first` lo esperaría y, con el
      // reloj simulado de testWidgets, no se completa.
      onCancel: () {
        unawaited(changes?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }
}
