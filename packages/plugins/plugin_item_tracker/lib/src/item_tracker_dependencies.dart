import 'package:core_hardware/core_hardware.dart';

import 'domain/use_cases/add_item_event.dart';
import 'domain/use_cases/bind_identifier.dart';
import 'domain/use_cases/create_item.dart';
import 'domain/use_cases/find_item_by_identifier.dart';
import 'domain/use_cases/item_queries.dart';
import 'domain/use_cases/update_item.dart';

typedef CameraScannerFactory = CameraIdentifierScanner Function();
typedef NfcScannerFactory = NfcIdentifierScanner Function();

/// Todo lo que necesitan las pantallas del plugin. El plugin lo registra en
/// su scope de `core_di` durante `initialize()`.
class ItemTrackerDependencies {
  const ItemTrackerDependencies({
    required this.createItem,
    required this.updateItem,
    required this.bindIdentifier,
    required this.addItemEvent,
    required this.findItemByIdentifier,
    required this.getItem,
    required this.watchItem,
    required this.watchItems,
    required this.searchItems,
    required this.watchItemIdentifiers,
    required this.watchItemEvents,
    required this.cameraScannerFactory,
    required this.nfcScannerFactory,
    required this.permissions,
  });

  final CreateItem createItem;
  final UpdateItem updateItem;
  final BindIdentifier bindIdentifier;
  final AddItemEvent addItemEvent;
  final FindItemByIdentifier findItemByIdentifier;
  final GetItem getItem;
  final WatchItem watchItem;
  final WatchItems watchItems;
  final SearchItems searchItems;
  final WatchItemIdentifiers watchItemIdentifiers;
  final WatchItemEvents watchItemEvents;
  final CameraScannerFactory cameraScannerFactory;
  final NfcScannerFactory nfcScannerFactory;
  final HardwarePermissions permissions;
}
