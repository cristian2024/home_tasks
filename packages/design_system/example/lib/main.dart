import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/gallery_app.dart';
import 'src/injected_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await injectTranslations(
    LocalizationCoordinator.instance,
    bundle: rootBundle,
    packages: injectedTranslationPackages,
  );
  runApp(const GalleryApp());
}
