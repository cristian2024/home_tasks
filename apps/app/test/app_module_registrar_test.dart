import 'package:core_contracts/src/home_plugin.dart';
import 'package:core_contracts/src/plugin_registry.dart';
import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/app_module_registrar.dart';

void main() {
  test('AC-01: el registro de la app incluye item_tracker con sus traducciones', () {
    final LocalizationCoordinator localization = LocalizationCoordinator();
    final PluginRegistry registry = createPluginRegistry(locator: ServiceLocator(), localization: localization);

    final HomePlugin? plugin = registry.getPlugin('item_tracker');
    expect(plugin, isNotNull);
    expect(registry.allPlugins.map((HomePlugin p) => p.id), <String>['item_tracker']);
    // Sin inicializar el plugin, el catálogo ya puede mostrar su nombre.
    expect(localization.translate(plugin!.nameKey), 'Seguimiento de Objetos');
  });
}
