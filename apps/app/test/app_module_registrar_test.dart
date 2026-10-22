import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/app_module_registrar.dart';

void main() {
  test('AC-01: el registro de la app incluye item_tracker con sus traducciones', () {
    final localization = LocalizationCoordinator();
    final registry = createPluginRegistry(locator: ServiceLocator(), localization: localization);

    final plugin = registry.getPlugin('item_tracker');
    expect(plugin, isNotNull);
    expect(registry.allPlugins.map((p) => p.id), ['item_tracker']);
    // Sin inicializar el plugin, el catálogo ya puede mostrar su nombre.
    expect(localization.translate(plugin!.nameKey), 'Seguimiento de Objetos');
  });
}
