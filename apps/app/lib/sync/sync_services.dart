import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:sync_engine/sync_engine.dart';

/// Lo que la app usa del motor de sincronización. Lo registra `SyncModule`;
/// sin él (p. ej. una composición sin sincronización), la app funciona igual
/// y Configuración no muestra la sección.
class SyncServices {
  const SyncServices({required this.households, required this.controller, required this.inbox, required this.state});

  /// Los servicios registrados en [locator], o `null` si no se compuso la
  /// sincronización.
  static SyncServices? of(ServiceLocator locator) {
    if (!locator.isRegistered<SyncController>()) {
      return null;
    }
    return SyncServices(
      households: locator.get<HouseholdService>(),
      controller: locator.get<SyncController>(),
      inbox: locator.get<ConflictInbox>(),
      state: locator.get<SyncStateRepository>(),
    );
  }

  final HouseholdService households;
  final SyncController controller;
  final ConflictInbox inbox;
  final SyncStateRepository state;
}
