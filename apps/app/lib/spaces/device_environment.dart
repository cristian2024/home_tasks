import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_spaces/core_spaces.dart';

/// Servicios del dispositivo, que no dependen del espacio de datos y
/// sobreviven a los cambios de espacio: la lista de espacios, sus bases y los
/// accesos rápidos del icono (una pulsación que llega durante un cambio se
/// guarda hasta que la app nueva escucha).
class DeviceEnvironment {
  DeviceEnvironment({required this.locator, required this.spaceStorage});

  /// Locator propio, aparte del de cada espacio (que se vacía al cambiar).
  final ServiceLocator locator;

  final DataSpaceStorage spaceStorage;

  DataSpaceDirectory get spaces => locator.get<DataSpaceDirectory>();

  /// Accesos rápidos, o `null` si ningún adaptador los registró.
  AppShortcutService? get shortcuts =>
      locator.isRegistered<AppShortcutService>() ? locator.get<AppShortcutService>() : null;

  Future<void> dispose() => locator.reset();
}

/// Compone los servicios del dispositivo con [adapters] (que deben registrar
/// `DataSpaceDirectory`) y [spaceStorage].
Future<DeviceEnvironment> bootstrapDevice({
  required List<DependencyModule> adapters,
  required DataSpaceStorage spaceStorage,
  ServiceLocator? locator,
}) async {
  final ServiceLocator services = locator ?? ServiceLocator();
  for (final DependencyModule adapter in adapters) {
    await adapter.register(services);
  }
  return DeviceEnvironment(locator: services, spaceStorage: spaceStorage);
}
