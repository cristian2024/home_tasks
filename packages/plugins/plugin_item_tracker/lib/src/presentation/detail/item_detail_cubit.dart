import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/household_item.dart';
import '../../domain/entities/item_event.dart';
import '../../domain/entities/physical_identifier.dart';
import '../../domain/use_cases/item_queries.dart';

enum ItemDetailStatus { loading, loaded, missing }

class ItemDetailState extends Equatable {
  const ItemDetailState({
    this.status = ItemDetailStatus.loading,
    this.item,
    this.identifiers = const [],
    this.events = const [],
  });

  final ItemDetailStatus status;
  final HouseholdItem? item;
  final List<PhysicalIdentifier> identifiers;
  final List<ItemEvent> events;

  @override
  List<Object?> get props => [status, item, identifiers, events];
}

/// Detalle reactivo de un objeto: datos, identificadores e historial (Cubit:
/// flujo de solo lectura, §11.1).
class ItemDetailCubit extends Cubit<ItemDetailState> {
  ItemDetailCubit(
    String itemId, {
    required WatchItem watchItem,
    required WatchItemIdentifiers watchItemIdentifiers,
    required WatchItemEvents watchItemEvents,
  }) : super(const ItemDetailState()) {
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
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;
  bool _itemLoaded = false;
  HouseholdItem? _item;
  List<PhysicalIdentifier> _identifiers = const [];
  List<ItemEvent> _events = const [];

  void _emitCombined() {
    emit(
      ItemDetailState(
        status: !_itemLoaded
            ? ItemDetailStatus.loading
            : (_item == null ? ItemDetailStatus.missing : ItemDetailStatus.loaded),
        item: _item,
        identifiers: _identifiers,
        events: _events,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
