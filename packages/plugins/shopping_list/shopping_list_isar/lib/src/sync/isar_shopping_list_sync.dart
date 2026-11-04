import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';
import 'package:storage_isar/adapter.dart';
import 'package:sync_isar/sync_isar.dart';

import '../mappers/shopping_data_mapper.dart';
import '../mappers/synced_entity_mapper.dart';
import '../models/isar_shopping_category.dart';
import '../models/isar_shopping_item.dart';
import '../models/isar_shopping_list_synced.dart';
import '../models/isar_shopping_purchase.dart';

/// Escritura local de una entidad: su colección, su id y sus campos
/// sincronizados después de escribir.
typedef ShoppingSyncWrite = ({String collection, String id, Map<String, Object?> fields});

/// La sincronización de la lista de compras sobre Isar: copias
/// sincronizadas, registro de las escrituras locales y migración de los datos
/// anteriores.
///
/// Solo actúa si la app compuso la sincronización: si en el locator hay un
/// `HlcClock` (lo registra `SyncModule`) y un [IsarChangeLogWriter] (lo
/// registra `SyncIsar`). Los pide al usarlos, porque se registran después
/// de abrir la base.
class IsarShoppingListSync {
  IsarShoppingListSync(this._isar, this._services, {IdGenerator ids = const UuidV4Generator()}) : _ids = ids;

  final Isar _isar;
  final ServiceLocator? _services;
  final IdGenerator _ids;

  IsarCollection<IsarShoppingListSynced> get _synced => _isar.isarShoppingListSynceds;

  static ShoppingSyncWrite item(IsarShoppingItem model) => (
        collection: ShoppingListCollections.items,
        id: model.id,
        fields: ShoppingListCodec.itemFields(ShoppingDataMapper.fromIsarItem(model)),
      );

  static ShoppingSyncWrite category(IsarShoppingCategory model) => (
        collection: ShoppingListCollections.categories,
        id: model.id,
        fields: ShoppingListCodec.categoryFields(ShoppingDataMapper.fromIsarCategory(model)),
      );

  static ShoppingSyncWrite purchase(IsarShoppingPurchase model, {required String? previousPurchase}) => (
        collection: ShoppingListCollections.purchases,
        id: model.id,
        fields: ShoppingListCodec.purchaseFields(
          ShoppingDataMapper.fromIsarPurchase(model),
          previousPurchase: previousPurchase,
        ),
      );

  static ShoppingSyncWrite deletion(String collection, String id, DateTime at) =>
      (collection: collection, id: id, fields: ShoppingListCodec.deletion(at));

  /// Al empezar una transacción de escritura, antes de escribir nada:
  /// migra lo guardado antes si aún no se hizo.
  Future<void> prepare() async {
    final _SyncContext? context = _context();
    if (context != null) {
      await _migrate(context);
    }
  }

  /// Al final de la transacción de escritura: actualiza las copias de lo
  /// escrito y registra sus cambios en el log, todo en esa transacción.
  Future<void> record(List<ShoppingSyncWrite> writes) async {
    final _SyncContext? context = _context();
    if (context == null) {
      return;
    }
    final List<LocalSyncWrite> localWrites = <LocalSyncWrite>[
      for (final ShoppingSyncWrite write in writes)
        LocalSyncWrite(
          collection: write.collection,
          id: write.id,
          fields: write.fields,
          current: await _current(write.collection, write.id),
        ),
    ];
    final LocalSyncChanges changes =
        context.recorder.record(localWrites, nextSeq: await context.writer.nextSeq(context.recorder.deviceId));
    await _putSynced(changes.entities);
    await context.writer.append(changes.records);
  }

  /// Copias de [collection], tras migrar los datos anteriores si hace falta.
  Future<List<SyncedEntity>> syncedEntities(String collection) async {
    await _isar.writeTxn(prepare);
    final List<IsarShoppingListSynced> rows = await _synced.where().collectionEqualToAnyEntityId(collection).findAll();
    return rows.map(SyncedEntityMapper.fromIsar).toList();
  }

  /// Guarda lo que deja la sincronización, en una transacción y sin
  /// registrar nada.
  Future<void> commit(ShoppingListSyncCommit commit) => _isar.writeTxn(() async {
        await _putSynced(commit.entities);
        await _isar.isarShoppingItems.putAllById(commit.items.map(SyncedEntityMapper.toIsarItem).toList());
        await _isar.isarShoppingCategorys.putAllById(commit.categories.map(SyncedEntityMapper.toIsarCategory).toList());
        await _isar.isarShoppingPurchases.putAllById(commit.purchases.map(SyncedEntityMapper.toIsarPurchase).toList());
      });

  _SyncContext? _context() {
    final ServiceLocator? services = _services;
    if (services == null || !services.isRegistered<HlcClock>() || !services.isRegistered<IsarChangeLogWriter>()) {
      return null;
    }
    return _SyncContext(
      LocalSyncRecorder(hlcClock: services.get<HlcClock>(), ids: _ids),
      services.get<HlcClock>(),
      services.get<IsarChangeLogWriter>(),
    );
  }

  Future<SyncedEntity?> _current(String collection, String id) async {
    final IsarShoppingListSynced? current = await _synced.getByCollectionEntityId(collection, id);
    return current == null ? null : SyncedEntityMapper.fromIsar(current);
  }

  Future<void> _putSynced(List<SyncedEntity> entities) =>
      _synced.putAllByCollectionEntityId(entities.map(SyncedEntityMapper.toIsar).toList());

  /// Una sola vez (spec §10.4.8): da a lo que ya estaba guardado su copia
  /// sincronizada, con marcas derivadas de sus fechas y este dispositivo como
  /// origen, y registra sus cambios para que viajen al unirse a un hogar.
  ///
  /// Lo borrado se migra borrado, con la marca de su borrado. Las categorías
  /// no tienen fecha: reciben la marca más antigua. Las compras de cada item
  /// se encadenan por fecha, para que el historial no parezca de compras
  /// concurrentes.
  Future<void> _migrate(_SyncContext context) async {
    if (await _synced.getByCollectionEntityId(IsarShoppingListSynced.migrationMarker, '') != null) {
      return;
    }
    final String deviceId = context.hlcClock.deviceId;
    int seq = await context.writer.nextSeq(deviceId);
    final List<ChangeRecord> records = <ChangeRecord>[];
    final List<SyncedEntity> entities = <SyncedEntity>[
      SyncedEntity(collection: IsarShoppingListSynced.migrationMarker, id: ''),
    ];
    void add(ShoppingSyncWrite write, DateTime? at, DateTime? deletedAt) {
      final Hlc hlc = Hlc(wallTime: (deletedAt ?? at)?.millisecondsSinceEpoch ?? 0, counter: 0, deviceId: deviceId);
      final List<FieldChange> changes = FieldDiff.between(null, <String, Object?>{
        ...write.fields,
        if (deletedAt != null) ...ShoppingListCodec.deletion(deletedAt),
      });
      records.add(ChangeRecord(
        opId: _ids.newId(),
        deviceId: deviceId,
        seq: seq++,
        collection: write.collection,
        entityId: write.id,
        hlc: hlc,
        changes: changes,
      ));
      entities.add(SyncedEntity(collection: write.collection, id: write.id).apply(changes, hlc));
    }

    for (final IsarShoppingCategory model in await _isar.isarShoppingCategorys.where().findAll()) {
      add(category(model), null, model.deletedAt);
    }
    for (final IsarShoppingItem model in await _isar.isarShoppingItems.where().findAll()) {
      add(item(model), model.updatedAt, model.deletedAt);
    }
    final List<IsarShoppingPurchase> purchases =
        await _isar.isarShoppingPurchases.where().sortByItemId().thenByPurchasedAt().thenById().findAll();
    for (int i = 0; i < purchases.length; i++) {
      final IsarShoppingPurchase model = purchases[i];
      final IsarShoppingPurchase? previous = i == 0 ? null : purchases[i - 1];
      add(
        purchase(model, previousPurchase: previous?.itemId == model.itemId ? previous!.id : null),
        model.purchasedAt,
        model.deletedAt,
      );
    }
    await _putSynced(entities);
    await context.writer.append(records);
  }
}

class _SyncContext {
  _SyncContext(this.recorder, this.hlcClock, this.writer);

  final LocalSyncRecorder recorder;
  final HlcClock hlcClock;
  final IsarChangeLogWriter writer;
}
