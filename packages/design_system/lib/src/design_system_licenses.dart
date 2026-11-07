import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Añade las licencias de las fuentes a la lista de licencias de la app.
void registerDesignSystemLicenses() => LicenseRegistry.addLicense(() async* {
      for (final (String font, String file) in const <(String, String)>[
        ('Inter', 'OFL.txt'),
        ('Lucide', 'LICENSE-Lucide.txt'),
      ]) {
        final String text = await rootBundle.loadString('packages/design_system/assets/fonts/$file');
        yield LicenseEntryWithLineBreaks(<String>['design_system', font], text);
      }
    });
