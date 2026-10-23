import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/household_item.dart';
import '../../domain/entities/item_event.dart';
import '../../domain/entities/physical_identifier.dart';
import '../../domain/hierarchy/containment_policy.dart';
import '../../domain/hierarchy/item_tree.dart';
import '../../domain/use_cases/item_queries.dart';
import '../../domain/use_cases/move_item.dart';
import '../../domain/use_cases/unbind_identifier.dart';

enum ItemDetailStatus { loading, loaded, missing }

class ItemDetailState extends Equatable {
  const ItemDetailState({
    this.status = ItemDetailStatus.loading,
    this.item,
    this.identifiers = const [],
    this.events = const [],
    this.path = const [],
    this.children = const [],
    this.depth = 1,
    this.maxDepth = ContainmentPolicy.defaultMaxDepth,
  });

  final ItemDetailStatus status;
  final HouseholdItem? item;
  final List<PhysicalIdentifier> identifiers;
  final List<ItemEvent> events;

  /// Contenedores del objeto, del más externo al más interno.
  final List<HouseholdItem> path;

  /// Contenido directo, ordenado por nombre.
  final List<HouseholdItem> children;

  /// Nivel del objeto (1 si no está dentro de nada) y máximo permitido.
  final int depth;
  final int maxDepth;

  /// Se puede crear o meter un objeto suelto dentro de este.
  bool get canHoldMore => depth < maxDepth;

  /// Contiene objetos por debajo del nivel máximo (se bajó el límite).
  bool get isOverflowing => depth >= maxDepth && children.isNotEmpty;

  @override
  List<Object?> get props => [status, item, identifiers, events, path, children, depth, maxDepth];
}

/// Detalle reactivo de un objeto: datos, ubicación, contenido,
/// identificadores e historial (Cubit, §11.1). Las escrituras (quitar un
/// identificador, sacarlo del contenedor) se reflejan a través de los mismos
/// streams.
class ItemDetailCubit extends Cubit<ItemDetailState> {
  ItemDetailCubit(
    this.itemId, {
    required WatchItem watchItem,
    required WatchItemIdentifiers watchItemIdentifiers,
    required WatchItemEvents watchItemEvents,
    required WatchItemTree watchItemTree,
    required UnbindIdentifier unbindIdentifier,
    required MoveItem moveItem,
    required ContainmentPolicy containmentPolicy,
  })  : _unbindIdentifier = unbindIdentifier,
        _moveItem = moveItem,
        _policy = containmentPolicy,
        super(ItemDetailState(maxDepth: containmentPolicy.maxDepth)) {
    _subscriptions = [
      watchItem(itemId).listen((item) {
        _itemLoaded = true;
        _item = item;
        _emitCombined();
      }),
      watchItemIdentifiers(itemId).listen((identifiers) {
        _identifiers = identifiers;
        _emitCombined();
      }),
      watchItemEvents(itemId).listen((events) {
        _events = events;
        _emitCombined();
      }),
      watchItemTree().listen((tree) {
        _tree = tree;
        _emitCombined();
      }),
    ];
  }

  final String itemId;
  final UnbindIdentifier _unbindIdentifier;
  final MoveItem _moveItem;
  final ContainmentPolicy _policy;
  late final List<StreamSubscription<Object?>> _subscriptions;
  bool _itemLoaded = false;
  HouseholdItem? _item;
  List<PhysicalIdentifier> _identifiers = const [];
  List<ItemEvent> _events = const [];
  ItemTree? _tree;

  void _emitCombined() {
    emit(
      ItemDetailState(
        status: !_itemLoaded
            ? ItemDetailStatus.loading
            : (_item == null ? ItemDetailStatus.missing : ItemDetailStatus.loaded),
        item: _item,
        identifiers: _identifiers,
        events: _events,
        path: _tree?.pathOf(itemId) ?? const [],
        children: _tree?.childrenOf(itemId) ?? const [],
        depth: _tree?.depthOf(itemId) ?? 1,
        maxDepth: _policy.maxDepth,
      ),
    );
  }

  /// Quita el identificador del objeto. Devuelve el error, o `null` si se
  /// quitó.
  Future<Object?> removeIdentifier(PhysicalIdentifier identifier) async {
    try {
      await _unbindIdentifier(itemId, identifierId: identifier.id);
      return null;
    } catch (error) {
      return error;
    }
  }

  /// Saca el objeto de su contenedor. Devuelve el error, o `null` si salió.
  Future<Object?> moveOut() async {
    try {
      await _moveItem(itemId, parentId: null);
      return null;
    } catch (error) {
      return error;
    }
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
