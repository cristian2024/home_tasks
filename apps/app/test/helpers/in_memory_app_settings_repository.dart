import 'package:home_utility_app/settings/app_settings.dart';
import 'package:home_utility_app/settings/app_settings_repository.dart';

/// Preferencias en memoria. Compartir una instancia entre dos arranques
/// simula que se conservan tras reiniciar la app.
class InMemoryAppSettingsRepository implements AppSettingsRepository {
  InMemoryAppSettingsRepository([this.saved = const AppSettings()]);

  AppSettings saved;
  int saves = 0;

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
    saves++;
  }
}
