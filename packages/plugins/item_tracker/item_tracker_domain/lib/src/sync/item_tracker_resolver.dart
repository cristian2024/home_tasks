import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import '../entities/household_item.dart';
import '../entities/physical_identifier.dart';
import '../hierarchy/containment_policy.dart';
import 'item_tracker_codec.dart';

/// Un objeto tal como lo lee la app: con su contenedor efectivo y, si está
/// borrado, el momento del borrado.
class ResolvedItem extends Equatable {
  const ResolvedItem(this.item, {this.deletedAt});

  final HouseholdItem item;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => <Object?>[item, deletedAt];
}

/// Un identificador tal como lo lee la app: activo o, si no, con el momento
/// en que dejó de estarlo.
class ResolvedIdentifier extends Equatable {
  const ResolvedIdentifier(this.identifier, {this.deletedAt});

  final PhysicalIdentifier identifier;
  final DateTime? deletedAt;

  bool get isActive => deletedAt == null;

  @override
  List<Object?> get props => <Object?>[identifier, deletedAt];
}

/// Resultado de [ItemTrackerResolver.resolve].
class ItemTrackerView extends Equatable {
  ItemTrackerView({
    required Map<String, ResolvedItem> items,
    required Map<String, ResolvedIdentifier> identifiers,
    required List<SyncConflict> conflicts,
  })  : items = Map<String, ResolvedItem>.unmodifiable(items),
        identifiers = Map<String, ResolvedIdentifier>.unmodifiable(identifiers),
        conflicts = List<SyncConflict>.unmodifiable(conflicts);

  /// Objetos completos, por id.
  final Map<String, ResolvedItem> items;

  /// Identificadores completos, por id.
  final Map<String, ResolvedIdentifier> identifiers;

  /// Conflictos de reglas de negocio, ordenados por id.
  final List<SyncConflict> conflicts;

  @override
  List<Object?> get props => <Object?>[items, identifiers, conflicts];
}

/// Calcula, a partir de las copias sincronizadas, lo que lee la app y los
/// conflictos (spec §10.4.4). Es una función pura del estado: todos los
/// dispositivos llegan al mismo resultado, sin importar en qué orden
/// recibieron los cambios, y sin escribir cambios nuevos.
///
/// - **Contenedor borrado:** el objeto pasa al contenedor del borrado (o al
///   primero de sus antecesores que siga activo) o queda suelto. Conflicto
///   `containerDeleted`.
/// - **Ciclo o exceso de niveles** por movimientos concurrentes: se revierte
///   el movimiento de mayor marca y el objeto queda suelto. Conflicto
///   `moveReverted`.
/// - **El mismo identificador en dos objetos:** se queda el de menor marca de
///   creación, salvo que lo hubieran quitado antes de crear el otro. El otro
///   queda quitado. Conflicto `identifierBoundTwice`.
/// - **Identificador de un objeto borrado:** queda quitado, sin conflicto.
class ItemTrackerResolver {
  const ItemTrackerResolver({this.policy = const ContainmentPolicy()});

  static const String containerDeleted = 'containerDeleted';
  static const String moveReverted = 'moveReverted';
  static const String identifierBoundTwice = 'identifierBoundTwice';

  final ContainmentPolicy policy;

  ItemTrackerView resolve(Iterable<SyncedEntity> items, Iterable<SyncedEntity> identifiers) {
    final _Items tree = _Items(items);
    final List<SyncConflict> conflicts = <SyncConflict>[
      ..._resolveDeletedContainers(tree),
      ..._breakCycles(tree),
      ..._limitDepth(tree),
    ];
    final Map<String, ResolvedIdentifier> resolvedIdentifiers = <String, ResolvedIdentifier>{};
    conflicts.addAll(_resolveIdentifiers(tree, identifiers, resolvedIdentifiers));
    conflicts.sort((SyncConflict a, SyncConflict b) => a.id.compareTo(b.id));
    return ItemTrackerView(
      items: <String, ResolvedItem>{
        for (final String id in tree.ids)
          id: ResolvedItem(
            tree.isDeleted(id) ? tree.items[id]! : tree.items[id]!.copyWith(parentId: () => tree.parent[id]),
            deletedAt: tree.deletedAt(id),
          ),
      },
      identifiers: resolvedIdentifiers,
      conflicts: conflicts,
    );
  }

  /// Sube por los contenedores borrados hasta el primero activo.
  List<SyncConflict> _resolveDeletedContainers(_Items tree) {
    final List<SyncConflict> conflicts = <SyncConflict>[];
    for (final String id in tree.activeIds) {
      String? parent = tree.items[id]!.parentId;
      String? removedContainer;
      final Set<String> visited = <String>{id};
      while (parent != null && tree.isDeleted(parent) && visited.add(parent)) {
        removedContainer ??= parent;
        parent = tree.items[parent]!.parentId;
      }
      if (parent != null && tree.isDeleted(parent)) {
        parent = null;
      }
      tree.parent[id] = parent;
      if (removedContainer != null) {
        final Hlc? stamp = tree.raw[removedContainer]!.metadata.hlcOf(ItemTrackerCodec.deletedAt);
        conflicts.add(SyncConflict(
          id: '$conflictPrefix$containerDeleted:$id:$removedContainer',
          collection: ItemTrackerCollections.items,
          kind: containerDeleted,
          entityIds: <String>[id, removedContainer],
          options: <ConflictOption>[ConflictOption(keepOption), ConflictOption(deleteOption)],
          provisionalOptionId: keepOption,
          detectedAt: _wallTime(stamp),
        ));
      }
    }
    return conflicts;
  }

  List<SyncConflict> _breakCycles(_Items tree) {
    final List<SyncConflict> conflicts = <SyncConflict>[];
    for (List<String>? cycle = _findCycle(tree); cycle != null; cycle = _findCycle(tree)) {
      conflicts.add(_revertMove(tree, _latestMove(tree, cycle)));
    }
    return conflicts;
  }

  List<String>? _findCycle(_Items tree) {
    for (final String start in tree.activeIds) {
      final List<String> path = <String>[];
      String? current = start;
      while (current != null && tree.parent.containsKey(current) && !path.contains(current)) {
        path.add(current);
        current = tree.parent[current];
      }
      if (current != null && path.contains(current)) {
        return path.sublist(path.indexOf(current));
      }
    }
    return null;
  }

  List<SyncConflict> _limitDepth(_Items tree) {
    final List<SyncConflict> conflicts = <SyncConflict>[];
    while (true) {
      String? deepest;
      int deepestDepth = policy.maxDepth;
      for (final String id in tree.activeIds) {
        final int depth = tree.chainOf(id).length;
        if (depth > deepestDepth) {
          deepest = id;
          deepestDepth = depth;
        }
      }
      if (deepest == null) {
        return conflicts;
      }
      final List<String> moved = <String>[
        for (final String id in tree.chainOf(deepest))
          if (tree.parent.containsKey(tree.parent[id])) id,
      ];
      conflicts.add(_revertMove(tree, _latestMove(tree, moved)));
    }
  }

  /// El de [ids] cuyo contenedor se cambió con la mayor marca.
  String _latestMove(_Items tree, List<String> ids) =>
      (List<String>.of(ids)..sort((String a, String b) => _compareMoves(tree, a, b))).last;

  /// Por marca del cambio de contenedor y, con la misma marca (la misma
  /// escritura), por id.
  int _compareMoves(_Items tree, String a, String b) {
    final int byStamp = (tree.parentStamp(a) ?? _origin).compareTo(tree.parentStamp(b) ?? _origin);
    return byStamp != 0 ? byStamp : a.compareTo(b);
  }

  SyncConflict _revertMove(_Items tree, String id) {
    final Hlc? stamp = tree.parentStamp(id);
    tree.parent[id] = null;
    return SyncConflict(
      id: '$conflictPrefix$moveReverted:$id:${stamp?.encode()}',
      collection: ItemTrackerCollections.items,
      kind: moveReverted,
      entityIds: <String>[id, tree.items[id]!.parentId ?? id],
      options: <ConflictOption>[ConflictOption(confirmOption)],
      provisionalOptionId: confirmOption,
      detectedAt: _wallTime(stamp),
    );
  }

  List<SyncConflict> _resolveIdentifiers(
    _Items tree,
    Iterable<SyncedEntity> entities,
    Map<String, ResolvedIdentifier> resolved,
  ) {
    final Map<String, List<_Identifier>> byValue = <String, List<_Identifier>>{};
    for (final SyncedEntity entity in entities) {
      final PhysicalIdentifier? identifier = ItemTrackerCodec.identifierOf(entity);
      if (identifier != null) {
        byValue
            .putIfAbsent('${identifier.type.name}:${identifier.rawValue}', () => <_Identifier>[])
            .add(_Identifier(identifier, entity, tree));
      }
    }
    final List<SyncConflict> conflicts = <SyncConflict>[];
    for (final List<_Identifier> group in byValue.values) {
      group.sort(_Identifier.compareByCreation);
      _Identifier? holder;
      for (final _Identifier candidate in group) {
        final Hlc? released = holder?.releasedAt;
        if (released != null && released.isBefore(candidate.created)) {
          holder = null;
        }
        final _Identifier? winner = holder;
        if (winner == null) {
          holder = candidate;
        } else if (candidate.deletedAt == null && winner.identifier.itemId != candidate.identifier.itemId) {
          conflicts.add(_boundTwice(winner, candidate));
        }
        final PhysicalIdentifier identifier = candidate.identifier;
        resolved[identifier.id] = ResolvedIdentifier(
          identifier,
          deletedAt: candidate.deletedAt ?? (winner == null ? null : identifier.boundAt),
        );
      }
    }
    return conflicts;
  }

  SyncConflict _boundTwice(_Identifier holder, _Identifier loser) => SyncConflict(
        id: '$conflictPrefix$identifierBoundTwice:${loser.identifier.id}',
        collection: ItemTrackerCollections.identifiers,
        kind: identifierBoundTwice,
        entityIds: <String>[holder.identifier.itemId, loser.identifier.itemId],
        options: <ConflictOption>[_keep(holder.identifier), _keep(loser.identifier)],
        provisionalOptionId: keepPrefix + holder.identifier.id,
        detectedAt: _wallTime(loser.created),
      );

  static ConflictOption _keep(PhysicalIdentifier identifier) => ConflictOption(
        keepPrefix + identifier.id,
        details: <String, String>{
          'itemId': identifier.itemId,
          'rawValue': identifier.rawValue,
          'type': identifier.type.name,
        },
      );

  static final Hlc _origin = Hlc(wallTime: 0, counter: 0, deviceId: '-');

  static DateTime _wallTime(Hlc? hlc) => DateTime.fromMillisecondsSinceEpoch(hlc?.wallTime ?? 0, isUtc: true);

  /// Prefijo de los ids de conflicto de item_tracker.
  static const String conflictPrefix = 'item_tracker.';

  /// Opciones: dejar el objeto donde quedó, borrarlo o confirmar la reversión.
  static const String keepOption = 'keep';
  static const String deleteOption = 'delete';
  static const String confirmOption = 'confirm';

  /// Opción de `identifierBoundTwice`: quedarse con el identificador de id
  /// `keep:<id>`.
  static const String keepPrefix = 'keep:';
}

/// Los objetos completos y sus contenedores efectivos, que la resolución va
/// ajustando.
class _Items {
  _Items(Iterable<SyncedEntity> entities) {
    for (final SyncedEntity entity in entities) {
      final HouseholdItem? item = ItemTrackerCodec.itemOf(entity);
      if (item != null) {
        raw[entity.id] = entity;
        items[entity.id] = item;
      }
    }
    ids = items.keys.toList()..sort();
    activeIds = <String>[
      for (final String id in ids)
        if (!isDeleted(id)) id,
    ];
  }

  final Map<String, SyncedEntity> raw = <String, SyncedEntity>{};
  final Map<String, HouseholdItem> items = <String, HouseholdItem>{};

  /// Contenedor efectivo de cada objeto activo.
  final Map<String, String?> parent = <String, String?>{};
  late final List<String> ids;
  late final List<String> activeIds;

  DateTime? deletedAt(String id) => ItemTrackerCodec.deletedAtOf(raw[id]!);

  bool isDeleted(String id) => raw[id] != null && deletedAt(id) != null;

  Hlc? deletedStamp(String id) => isDeleted(id) ? raw[id]!.metadata.hlcOf(ItemTrackerCodec.deletedAt) : null;

  Hlc? parentStamp(String id) => raw[id]!.metadata.hlcOf(ItemTrackerCodec.parentId);

  /// [id] y sus contenedores efectivos conocidos, de dentro hacia fuera.
  List<String> chainOf(String id) {
    final List<String> chain = <String>[];
    for (String? current = id; current != null && parent.containsKey(current); current = parent[current]) {
      chain.add(current);
    }
    return chain;
  }
}

/// Un identificador completo con lo que necesita la regla de unicidad.
class _Identifier {
  _Identifier(this.identifier, SyncedEntity entity, _Items tree)
      : created = entity.metadata.createdHlc ?? ItemTrackerResolver._origin,
        deletedAt = ItemTrackerCodec.deletedAtOf(entity) ?? _itemDeletedAt(tree, identifier.itemId),
        releasedAt = _earliest(
          ItemTrackerCodec.deletedAtOf(entity) == null ? null : entity.metadata.hlcOf(ItemTrackerCodec.deletedAt),
          tree.deletedStamp(identifier.itemId),
        );

  final PhysicalIdentifier identifier;

  /// Marca con que se asoció.
  final Hlc created;

  /// Momento en que se quitó, él o su objeto.
  final DateTime? deletedAt;

  /// Marca desde la que el valor queda libre para otro.
  final Hlc? releasedAt;

  static int compareByCreation(_Identifier a, _Identifier b) {
    final int byHlc = a.created.compareTo(b.created);
    return byHlc != 0 ? byHlc : a.identifier.id.compareTo(b.identifier.id);
  }

  static DateTime? _itemDeletedAt(_Items tree, String itemId) => tree.isDeleted(itemId) ? tree.deletedAt(itemId) : null;

  static Hlc? _earliest(Hlc? a, Hlc? b) => a == null || (b != null && b.isBefore(a)) ? b : a;
}
