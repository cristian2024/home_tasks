import 'dart:ui';

import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import 'src/example_app.dart';

/// Arranque equivalente al que hará `apps/app` en la Fase 4, con un solo
/// plugin: servicios base en el scope raíz, base de datos con los esquemas
/// del plugin, idioma del dispositivo e inicialización del plugin.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final locator = ServiceLocator.instance;
  final plugin = ItemTrackerPlugin(locator: locator);
  final directory = await getApplicationDocumentsDirectory();
  final isar = await LocalDatabase.open(directory: directory.path, contributors: [plugin]);
  locator
    ..registerSingleton<Isar>(isar)
    ..registerSingleton<EventBus>(EventBus(), dispose: (bus) => bus.dispose())
    ..registerSingleton<IdGenerator>(const UuidV4Generator())
    ..registerSingleton<Clock>(const SystemClock());

  final localization = LocalizationCoordinator.instance;
  localization.setLanguage(LocalizationCoordinator.resolveLanguage(PlatformDispatcher.instance.locales));
  await plugin.initialize();

  runApp(ItemTrackerExampleApp(plugin: plugin, locator: locator, localization: localization));
}
