import 'dart:ui';

import 'package:core_spaces/core_spaces.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';

import 'app_module_registrar.dart';
import 'bootstrap.dart';
import 'i18n/strings.g.dart';
import 'settings/app_settings.dart';
import 'settings/app_settings_repository.dart';
import 'spaces/device_environment.dart';
import 'spaces/space_bootstrap.dart';
import 'spaces/space_root.dart';
import 'spaces/space_switcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String systemLanguageCode = LocalizationCoordinator.resolveLanguage(PlatformDispatcher.instance.locales);
  final DeviceEnvironment device =
      await bootstrapDevice(adapters: deviceAdapters, spaceStorage: await appSpaceStorage());
  // El nombre del primer espacio va en el idioma de la app, antes de arrancarla.
  final AppSettings settings = await const SharedPreferencesAppSettingsRepository().load();
  LocaleSettings.setLocaleRawSync(settings.languageCode ?? systemLanguageCode);

  Future<AppEnvironment> open(DataSpace space, {String? deviceName}) => bootstrapApp(
        systemLanguageCode: systemLanguageCode,
        device: device,
        space: space,
        adapters: appAdaptersFor(space: space, deviceName: deviceName),
      );

  final SpaceSwitcher switcher = await bootstrapSpaces(
    device: device,
    open: open,
    defaultName: appStrings.app.spaces.defaultName,
    newSpaceName: (int number) => appStrings.app.spaces.newSpaceName(n: number),
  );
  runApp(SpaceRoot(switcher: switcher));
}
