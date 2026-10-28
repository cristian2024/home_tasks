import 'dart:ui';

import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';
import 'package:storage_isar/storage_isar.dart';

import 'src/example_app.dart';
import 'src/injected_translations.dart';

/// Arranque equivalente al de `apps/app`, con un solo plugin: servicios base
/// en el scope raíz, el adaptador de almacenamiento elegido (abre la base y
/// registra el repositorio del plugin), textos inyectados desde los assets,
/// idioma del dispositivo e inicialización del plugin.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ServiceLocator locator = ServiceLocator.instance
    ..registerSingleton<EventBus>(EventBus(), dispose: (EventBus bus) => bus.dispose())
    ..registerSingleton<IdGenerator>(const UuidV4Generator())
    ..registerSingleton<Clock>(const SystemClock());
  await const IsarStorage(features: <IsarFeature>[ItemTrackerIsar()]).register(locator);
  final ItemTrackerPlugin plugin = ItemTrackerPlugin(locator: locator);

  final LocalizationCoordinator localization = LocalizationCoordinator.instance;
  await injectTranslations(localization, bundle: rootBundle, packages: injectedTranslationPackages);
  localization.setLanguage(LocalizationCoordinator.resolveLanguage(PlatformDispatcher.instance.locales));
  await plugin.initialize();

  runApp(ItemTrackerExampleApp(plugin: plugin, locator: locator, localization: localization));
}
