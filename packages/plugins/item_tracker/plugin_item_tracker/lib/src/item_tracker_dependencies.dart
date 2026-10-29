import 'package:core_hardware/core_hardware.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import 'domain/use_cases/add_item_event.dart';
import 'domain/use_cases/bind_identifier.dart';
import 'domain/use_cases/create_item.dart';
import 'domain/use_cases/delete_item.dart';
import 'domain/use_cases/find_item_by_identifier.dart';
import 'domain/use_cases/item_queries.dart';
import 'domain/use_cases/move_item.dart';
import 'domain/use_cases/unbind_identifier.dart';
import 'domain/use_cases/update_item.dart';

typedef CameraScannerFactory = CameraIdentifierScanner Function();
typedef NfcScannerFactory = NfcIdentifierScanner Function();

/// Todo lo que necesitan las pantallas del plugin. El plugin lo registra en
/// su scope de `core_di` durante `initialize()`.
class ItemTrackerDependencies {
  const ItemTrackerDependencies({
    required this.createItem,
    required this.updateItem,
    required this.moveItem,
    required this.deleteItem,
    required this.bindIdentifier,
    required this.unbindIdentifier,
    required this.addItemEvent,
    required this.findItemByIdentifier,
    required this.getItem,
    required this.watchItem,
    required this.watchItems,
    required this.watchItemTree,
    required this.searchItems,
    required this.watchItemIdentifiers,
    required this.watchItemEvents,
    required this.cameraScannerFactory,
    required this.nfcScannerFactory,
    required this.permissions,
    required this.containmentPolicy,
  });

  final CreateItem createItem;
  final UpdateItem updateItem;
  final MoveItem moveItem;
  final DeleteItem deleteItem;
  final BindIdentifier bindIdentifier;
  final UnbindIdentifier unbindIdentifier;
  final AddItemEvent addItemEvent;
  final FindItemByIdentifier findItemByIdentifier;
  final GetItem getItem;
  final WatchItem watchItem;
  final WatchItems watchItems;
  final WatchItemTree watchItemTree;
  final SearchItems searchItems;
  final WatchItemIdentifiers watchItemIdentifiers;
  final WatchItemEvents watchItemEvents;
  final CameraScannerFactory cameraScannerFactory;
  final NfcScannerFactory nfcScannerFactory;
  final HardwarePermissions permissions;
  final ContainmentPolicy containmentPolicy;
}
