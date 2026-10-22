import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/strings.g.dart' as core_ui_i18n;

/// Aplica un código de idioma a las traducciones de un paquete.
typedef LanguageApplier = void Function(String languageCode);

/// Traduce una clave del paquete (p. ej. `itemTracker.title`) en el idioma
/// actual, o devuelve `null` si no la conoce.
typedef KeyTranslator = String? Function(String key);

/// Mantiene sincronizado el idioma de todos los paquetes.
///
/// Cada paquete genera sus propias traducciones con slang (una por paquete,
/// bajo su namespace). Al arrancar, cada paquete registra aquí cómo aplicar un
/// idioma y, opcionalmente, cómo traducir sus claves; la app solo llama a
/// [setLanguage] y resuelve claves de otros paquetes con [translate] (p. ej.
/// `HomePlugin.nameKey` en el catálogo).
class LocalizationCoordinator {
  LocalizationCoordinator() {
    register(
      'core_ui',
      (code) => core_ui_i18n.LocaleSettings.setLocaleRawSync(code),
      translate: (key) => _asString(core_ui_i18n.commonStrings[key]),
    );
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
  final Map<String, KeyTranslator> _translators = {};
  final ValueNotifier<String> _languageCode = ValueNotifier(
    defaultLanguageCode,
  );

  /// Idioma actual. Se puede escuchar para reconstruir la UI.
  ValueListenable<String> get languageCode => _languageCode;

  /// Registra un paquete y le aplica el idioma actual. Registrar de nuevo el
  /// mismo [packageName] reemplaza sus funciones.
  void register(
    String packageName,
    LanguageApplier apply, {
    KeyTranslator? translate,
  }) {
    _appliers[packageName] = apply;
    if (translate == null) {
      _translators.remove(packageName);
    } else {
      _translators[packageName] = translate;
    }
    apply(_languageCode.value);
  }

  /// Traduce [key] con el primer paquete que la conozca; si ninguno la
  /// conoce, devuelve la propia clave.
  String translate(String key) {
    for (final translator in _translators.values) {
      final value = translator(key);
      if (value != null) {
        return value;
      }
    }
    return key;
  }

  /// Las claves de slang que apuntan a textos con parámetros o a secciones
  /// no son `String`: no se pueden traducir sin argumentos.
  static String? _asString(Object? value) => value is String ? value : null;

  /// Cambia el idioma de todos los paquetes registrados. Un código no
  /// soportado se sustituye por [defaultLanguageCode].
  void setLanguage(String languageCode) {
    final code = supportedLanguageCodes.contains(languageCode)
        ? languageCode
        : defaultLanguageCode;
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
