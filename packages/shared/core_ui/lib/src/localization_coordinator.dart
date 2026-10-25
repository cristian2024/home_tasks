import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/strings.g.dart' as core_ui_i18n;

/// Aplica un código de idioma a las traducciones de un paquete.
typedef LanguageApplier = void Function(String languageCode);

/// Traduce una clave del paquete (p. ej. `itemTracker.title`) en el idioma
/// actual, o devuelve `null` si no la conoce.
typedef KeyTranslator = String? Function(String key);

/// Reemplaza textos del paquete en un idioma. [overrides] tiene la misma
/// estructura que sus JSON de slang; un mapa vacío quita los reemplazos de
/// ese idioma.
typedef TranslationOverrider = void Function(String languageCode, Map<String, Object?> overrides);

/// Mantiene sincronizado el idioma de todos los paquetes.
///
/// Cada paquete genera sus propias traducciones con slang (una por paquete,
/// bajo su namespace). Al arrancar, cada paquete registra aquí cómo aplicar un
/// idioma y, opcionalmente, cómo traducir sus claves; la app solo llama a
/// [setLanguage] y resuelve claves de otros paquetes con [translate] (p. ej.
/// `HomePlugin.nameKey` en el catálogo).
///
/// Quien consume los paquetes inyecta todos sus textos con
/// [overrideTranslations] (normalmente desde assets, con
/// `injectTranslations`). Los JSON de cada paquete son el contrato de claves
/// y el respaldo de las que no se inyecten.
class LocalizationCoordinator {
  LocalizationCoordinator() {
    register(
      'core_ui',
      (String code) => core_ui_i18n.LocaleSettings.setLocaleRawSync(code),
      translate: (String key) => _asString(core_ui_i18n.commonStrings[key]),
      override: (String code, Map<String, Object?> overrides) =>
          core_ui_i18n.LocaleSettings.instance.overrideTranslationsFromMapSync(
            locale: core_ui_i18n.AppLocaleUtils.parse(code),
            isFlatMap: false,
            map: overrides,
          ),
    );
  }

  /// Instancia global de la aplicación.
  static final LocalizationCoordinator instance = LocalizationCoordinator();

  static const String defaultLanguageCode = 'es';
  static const List<String> supportedLanguageCodes = <String>['es', 'en'];

  static List<Locale> get supportedLocales => <Locale>[
    for (final String code in supportedLanguageCodes) Locale(code),
  ];

  /// Delegados de los textos propios de Flutter (Material, Cupertino y
  /// widgets) para [supportedLocales]. Se pasan a `MaterialApp`.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  final Map<String, LanguageApplier> _appliers = <String, LanguageApplier>{};
  final Map<String, KeyTranslator> _translators = <String, KeyTranslator>{};
  final Map<String, TranslationOverrider> _overriders = <String, TranslationOverrider>{};
  final Map<String, Map<String, Map<String, Object?>>> _overrides = <String, Map<String, Map<String, Object?>>>{};
  final ValueNotifier<String> _languageCode = ValueNotifier<String>(
    defaultLanguageCode,
  );

  /// Idioma actual. Se puede escuchar para reconstruir la UI.
  ValueListenable<String> get languageCode => _languageCode;

  /// Registra un paquete y le aplica el idioma actual y los reemplazos que la
  /// app ya haya indicado para él. Registrar de nuevo el mismo [packageName]
  /// reemplaza sus funciones.
  void register(
    String packageName,
    LanguageApplier apply, {
    KeyTranslator? translate,
    TranslationOverrider? override,
  }) {
    _appliers[packageName] = apply;
    if (translate == null) {
      _translators.remove(packageName);
    } else {
      _translators[packageName] = translate;
    }
    if (override == null) {
      _overriders.remove(packageName);
    } else {
      _overriders[packageName] = override;
      final Map<String, Map<String, Object?>> pending =
          _overrides[packageName] ?? const <String, Map<String, Object?>>{};
      for (final MapEntry<String, Map<String, Object?>> entry in pending.entries) {
        override(entry.key, entry.value);
      }
    }
    apply(_languageCode.value);
  }

  /// Reemplaza textos de [packageName] en [languageCode]: tienen prioridad
  /// sobre los JSON del paquete. [overrides] sigue la estructura de esos JSON;
  /// las claves que no lleva salen del paquete. Sustituye los reemplazos
  /// anteriores de ese paquete e idioma; con un mapa vacío se quitan.
  ///
  /// Se puede llamar antes de que el paquete se registre: se aplican al
  /// registrarlo. Solo admite idiomas de [supportedLanguageCodes].
  void overrideTranslations(String packageName, String languageCode, Map<String, Object?> overrides) {
    if (!supportedLanguageCodes.contains(languageCode)) {
      throw ArgumentError.value(languageCode, 'languageCode', 'Idioma no soportado');
    }
    (_overrides[packageName] ??= <String, Map<String, Object?>>{})[languageCode] = overrides;
    _overriders[packageName]?.call(languageCode, overrides);
  }

  /// Traduce [key] con el primer paquete que la conozca; si ninguno la
  /// conoce, devuelve la propia clave.
  String translate(String key) {
    for (final KeyTranslator translator in _translators.values) {
      final String? value = translator(key);
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
    final String code = supportedLanguageCodes.contains(languageCode)
        ? languageCode
        : defaultLanguageCode;
    for (final LanguageApplier apply in _appliers.values) {
      apply(code);
    }
    _languageCode.value = code;
  }

  /// Primer idioma soportado de [deviceLocales], o [defaultLanguageCode].
  static String resolveLanguage(Iterable<Locale> deviceLocales) {
    for (final Locale locale in deviceLocales) {
      if (supportedLanguageCodes.contains(locale.languageCode)) {
        return locale.languageCode;
      }
    }
    return defaultLanguageCode;
  }
}
