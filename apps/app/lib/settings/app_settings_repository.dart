import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// Guarda las preferencias de la app.
abstract interface class AppSettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

/// Preferencias en `shared_preferences`, separadas de la base de datos de los
/// plugins. Un valor guardado que ya no se reconoce se lee como el valor por
/// defecto.
class SharedPreferencesAppSettingsRepository implements AppSettingsRepository {
  const SharedPreferencesAppSettingsRepository();

  static const String themeKey = 'app.theme';
  static const String languageKey = 'app.language';

  @override
  Future<AppSettings> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? languageCode = preferences.getString(languageKey);
    return AppSettings(
      theme: AppThemePreference.values.asNameMap()[preferences.getString(themeKey)] ?? AppThemePreference.system,
      languageCode: languageCode == null || languageCode.isEmpty ? null : languageCode,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? languageCode = settings.languageCode;
    await preferences.setString(themeKey, settings.theme.name);
    if (languageCode == null) {
      await preferences.remove(languageKey);
    } else {
      await preferences.setString(languageKey, languageCode);
    }
  }
}
