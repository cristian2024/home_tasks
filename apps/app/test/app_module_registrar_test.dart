import 'package:core_contracts/src/home_plugin.dart';
import 'package:core_contracts/src/plugin_registry.dart';
import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_mobile_scanner/hardware_mobile_scanner.dart';
import 'package:hardware_nfc_manager/hardware_nfc_manager.dart';
import 'package:hardware_permission_handler/hardware_permission_handler.dart';
import 'package:home_utility_app/app_module_registrar.dart';

void main() {
  test('AC-01: el registro de la app incluye item_tracker y la lista de compras con sus traducciones', () {
    final LocalizationCoordinator localization = LocalizationCoordinator();
    final PluginRegistry registry = createPluginRegistry(locator: ServiceLocator(), localization: localization);

    final HomePlugin? plugin = registry.getPlugin('item_tracker');
    expect(plugin, isNotNull);
    expect(registry.allPlugins.map((HomePlugin p) => p.id), <String>['item_tracker', 'shopping_list']);
    // Sin inicializar los plugins, el catálogo ya puede mostrar su nombre.
    expect(localization.translate(plugin!.nameKey), 'Seguimiento de Objetos');
    expect(localization.translate(registry.getPlugin('shopping_list')!.nameKey), 'Lista de compras');
  });

  test('los adaptadores de hardware registran la cámara, el NFC y los permisos', () async {
    final ServiceLocator locator = ServiceLocator();
    addTearDown(locator.reset);
    // Sin IsarStorage: abriría la base de datos.
    final List<DependencyModule> hardware = appAdapters
        .where(
          (DependencyModule adapter) =>
              adapter is MobileScannerHardware || adapter is NfcManagerHardware || adapter is PermissionHandlerHardware,
        )
        .toList();
    expect(hardware, hasLength(3));
    for (final DependencyModule adapter in hardware) {
      await adapter.register(locator);
    }

    expect(locator.isRegistered<CameraIdentifierScanner>(), isTrue);
    expect(locator.isRegistered<NfcIdentifierScanner>(), isTrue);
    expect(locator.isRegistered<HardwarePermissions>(), isTrue);
  });
}
