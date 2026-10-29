import 'dart:ui';

import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:share_native/share_native.dart';
import 'package:shopping_list_isar/shopping_list_isar.dart';
import 'package:storage_isar/storage_isar.dart';

import 'src/example_app.dart';
import 'src/injected_translations.dart';

/// Arranque equivalente al de `apps/app`, con un solo plugin: servicios base
/// en el scope raíz, los adaptadores elegidos (base de datos y compartir),
/// textos inyectados desde los assets, idioma del dispositivo e
/// inicialización del plugin.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ServiceLocator locator = ServiceLocator.instance
    ..registerSingleton<EventBus>(EventBus(), dispose: (EventBus bus) => bus.dispose())
    ..registerSingleton<IdGenerator>(const UuidV4Generator())
    ..registerSingleton<Clock>(const SystemClock());
  for (final DependencyModule adapter in <DependencyModule>[
    const IsarStorage(features: <IsarFeature>[ShoppingListIsar()]),
    const NativeShare(),
  ]) {
    await adapter.register(locator);
  }
  final ShoppingListPlugin plugin = ShoppingListPlugin(locator: locator);

  final LocalizationCoordinator localization = LocalizationCoordinator.instance;
  await injectTranslations(localization, bundle: rootBundle, packages: injectedTranslationPackages);
  localization.setLanguage(LocalizationCoordinator.resolveLanguage(PlatformDispatcher.instance.locales));
  await plugin.initialize();

  runApp(ShoppingListExampleApp(plugin: plugin, locator: locator, localization: localization));
}
