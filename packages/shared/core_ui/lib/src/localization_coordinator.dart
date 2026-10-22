import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/strings.g.dart' as core_ui_i18n;

/// Aplica un código de idioma a las traducciones de un paquete.
typedef LanguageApplier = void Function(String languageCode);

/// Mantiene sincronizado el idioma de todos los paquetes.
///
/// Cada paquete genera sus propias traducciones con slang (una por paquete,
/// bajo su namespace). Al arrancar, cada paquete registra aquí cómo aplicar un
/// idioma; la app solo llama a [setLanguage].
class LocalizationCoordinator {
  LocalizationCoordinator() {
    register('core_ui', (code) => core_ui_i18n.LocaleSettings.setLocaleRawSync(code));
  }

  /// Instancia global de la aplicación.
  static final LocalizationCoordinator instance = LocalizationCoordinator();

  static const String defaultLanguageCode = 'es';
  static const List<String> supportedLanguageCodes = ['es', 'en'];

  static List<Locale> get supportedLocales => [
        for (final code in supportedLanguageCodes) Locale(code),
      ];

  /// Delegados de los textos propios de Flutter (Material, Cupertino y
  /// widgets) para [supportedLocales]. Se pasan a `MaterialApp`.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  final Map<String, LanguageApplier> _appliers = {};
  final ValueNotifier<String> _languageCode = ValueNotifier(defaultLanguageCode);

  /// Idioma actual. Se puede escuchar para reconstruir la UI.
  ValueListenable<String> get languageCode => _languageCode;

  /// Registra un paquete y le aplica el idioma actual. Registrar de nuevo el
  /// mismo [packageName] reemplaza su función.
  void register(String packageName, LanguageApplier apply) {
    _appliers[packageName] = apply;
    apply(_languageCode.value);
  }

  /// Cambia el idioma de todos los paquetes registrados. Un código no
  /// soportado se sustituye por [defaultLanguageCode].
  void setLanguage(String languageCode) {
    final code = supportedLanguageCodes.contains(languageCode) ? languageCode : defaultLanguageCode;
    for (final apply in _appliers.values) {
      apply(code);
    }
    _languageCode.value = code;
  }

  /// Primer idioma soportado de [deviceLocales], o [defaultLanguageCode].
  static String resolveLanguage(Iterable<Locale> deviceLocales) {
    for (final locale in deviceLocales) {
      if (supportedLanguageCodes.contains(locale.languageCode)) {
        return locale.languageCode;
      }
    }
    return defaultLanguageCode;
  }
}
