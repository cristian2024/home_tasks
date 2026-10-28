import 'dart:ui';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppEnvironment environment = await bootstrapApp(
    systemLanguageCode: LocalizationCoordinator.resolveLanguage(
      PlatformDispatcher.instance.locales,
    ),
  );
  runApp(HomeUtilityApp(environment: environment));
}
