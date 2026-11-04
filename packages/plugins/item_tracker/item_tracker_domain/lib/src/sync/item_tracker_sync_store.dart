import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import '../entities/item_event.dart';
import 'item_tracker_resolver.dart';

/// Lo que el participante escribe tras aplicar cambios recibidos: las copias
/// sincronizadas que cambiaron y lo que la app debe leer desde entonces.
class ItemTrackerSyncCommit extends Equatable {
  ItemTrackerSyncCommit({
    List<SyncedEntity> entities = const <SyncedEntity>[],
    List<ResolvedItem> items = const <ResolvedItem>[],
    List<ResolvedIdentifier> identifiers = const <ResolvedIdentifier>[],
    List<ItemEvent> events = const <ItemEvent>[],
  })  : entities = List<SyncedEntity>.unmodifiable(entities),
        items = List<ResolvedItem>.unmodifiable(items),
        identifiers = List<ResolvedIdentifier>.unmodifiable(identifiers),
        events = List<ItemEvent>.unmodifiable(events);

  final List<SyncedEntity> entities;
  final List<ResolvedItem> items;
  final List<ResolvedIdentifier> identifiers;
  final List<ItemEvent> events;

  bool get isEmpty => entities.isEmpty && items.isEmpty && identifiers.isEmpty && events.isEmpty;

  @override
  List<Object?> get props => <Object?>[entities, items, identifiers, events];
}

/// Almacén de las copias sincronizadas de item_tracker. Lo implementa cada
/// repositorio junto a `HouseholdItemRepository`.
///
/// Las escrituras locales del repositorio actualizan las copias y registran
/// sus cambios en la misma transacción. Las de [commitSync] no registran
/// nada: vienen de otro dispositivo.
abstract interface class ItemTrackerSyncStore {
  /// Copias sincronizadas de [collection] (objetos o identificadores),
  /// también las borradas y las incompletas.
  Future<List<SyncedEntity>> syncedEntities(String collection);

  /// Guarda [commit] de forma atómica, sin registrar cambios:
  /// - reemplaza las copias de `entities`;
  /// - deja `items` e `identifiers` como los leerá la app, activos o
  ///   borrados. Quita los identificadores que dejan de estar activos antes
  ///   de activar otros, para no chocar con la unicidad;
  /// - guarda `events` (por id; los repetidos se ignoran).
  Future<void> commitSync(ItemTrackerSyncCommit commit);
}
