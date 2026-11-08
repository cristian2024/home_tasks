import 'dart:ui';

import 'package:core_di/core_di.dart';
import 'package:core_events/core_events.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plugin_task_list/plugin_task_list.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:task_list_isar/task_list_isar.dart';

import 'src/example_app.dart';
import 'src/injected_translations.dart';

/// Arranque equivalente al de `apps/app`, con un solo plugin: servicios base
/// en el scope raíz, el adaptador elegido (base de datos), textos inyectados
/// desde los assets, idioma del dispositivo e inicialización del plugin.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ServiceLocator locator = ServiceLocator.instance
    ..registerSingleton<EventBus>(EventBus(), dispose: (EventBus bus) => bus.dispose())
    ..registerSingleton<IdGenerator>(const UuidV4Generator())
    ..registerSingleton<Clock>(const SystemClock());
  for (final DependencyModule adapter in <DependencyModule>[
    const IsarStorage(features: <IsarFeature>[TaskListIsar()]),
  ]) {
    await adapter.register(locator);
  }
  final TaskListPlugin plugin = TaskListPlugin(locator: locator);

  final LocalizationCoordinator localization = LocalizationCoordinator.instance;
  await injectTranslations(localization, bundle: rootBundle, packages: injectedTranslationPackages);
  localization.setLanguage(LocalizationCoordinator.resolveLanguage(PlatformDispatcher.instance.locales));
  await plugin.initialize();

  runApp(TaskListExampleApp(plugin: plugin, locator: locator, localization: localization));
}
