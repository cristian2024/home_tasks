import 'dart:io';
import 'dart:ui';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory directory = await getApplicationDocumentsDirectory();
  final AppEnvironment environment = await bootstrapApp(
    databaseDirectory: directory.path,
    systemLanguageCode: LocalizationCoordinator.resolveLanguage(
      PlatformDispatcher.instance.locales,
    ),
  );
  runApp(HomeUtilityApp(environment: environment));
}
