import 'package:core_di/core_di.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

void main() {
  late LocalizationCoordinator localization;
  late ItemTrackerPlugin plugin;

  setUp(() {
    localization = LocalizationCoordinator();
    plugin = ItemTrackerPlugin(locator: ServiceLocator(), localization: localization);
  });

  tearDown(() {
    localization
      ..overrideTranslations(ItemTrackerPlugin.pluginId, 'es', <String, Object?>{})
      ..overrideTranslations(ItemTrackerPlugin.pluginId, 'en', <String, Object?>{})
      ..setLanguage('es');
  });

  test('los textos que reemplaza la app tienen prioridad sobre los del plugin', () {
    plugin.registerLocalization();
    localization.overrideTranslations(ItemTrackerPlugin.pluginId, 'es', <String, Object?>{
      'item_tracker': <String, Object?>{'title': 'Mis cosas'},
    });

    expect(localization.translate(plugin.nameKey), 'Mis cosas');
    expect(localization.translate('itemTracker.description'), startsWith('Identifica tus objetos'));

    localization.setLanguage('en');
    expect(localization.translate(plugin.nameKey), 'Item Tracker');
  });

  test('los reemplazos indicados antes de registrar el plugin se aplican al registrarlo', () {
    localization.overrideTranslations(ItemTrackerPlugin.pluginId, 'en', <String, Object?>{
      'item_tracker': <String, Object?>{'title': 'My stuff'},
    });
    plugin.registerLocalization();
    localization.setLanguage('en');

    expect(localization.translate(plugin.nameKey), 'My stuff');
  });
}
