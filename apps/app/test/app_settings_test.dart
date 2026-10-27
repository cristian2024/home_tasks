import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/settings/app_settings.dart';
import 'package:home_utility_app/settings/app_settings_controller.dart';
import 'package:home_utility_app/settings/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/in_memory_app_settings_repository.dart';

void main() {
  group('SharedPreferencesAppSettingsRepository', () {
    const SharedPreferencesAppSettingsRepository repository = SharedPreferencesAppSettingsRepository();

    test('sin nada guardado devuelve los valores por defecto', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      expect(await repository.load(), const AppSettings());
    });

    test('guarda y lee el tema y el idioma; con idioma nulo borra la clave', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await repository.save(const AppSettings(theme: AppThemePreference.dark, languageCode: 'en'));
      expect(await repository.load(), const AppSettings(theme: AppThemePreference.dark, languageCode: 'en'));

      await repository.save(const AppSettings(theme: AppThemePreference.light));
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(SharedPreferencesAppSettingsRepository.languageKey), isFalse);
      expect(await repository.load(), const AppSettings(theme: AppThemePreference.light));
    });

    test('guarda y lee la vista del inicio', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await repository.save(const AppSettings(homeLayout: HomeLayout.grid));
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(SharedPreferencesAppSettingsRepository.homeLayoutKey), 'grid');
      expect(await repository.load(), const AppSettings(homeLayout: HomeLayout.grid));
    });

    test('un valor que ya no se reconoce se lee como el valor por defecto', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAppSettingsRepository.themeKey: 'sepia',
        SharedPreferencesAppSettingsRepository.languageKey: '',
        SharedPreferencesAppSettingsRepository.homeLayoutKey: 'mosaico',
      });

      expect(await repository.load(), const AppSettings());
    });
  });

  group('AppSettingsController', () {
    late InMemoryAppSettingsRepository repository;
    late LocalizationCoordinator localization;

    setUp(() {
      repository = InMemoryAppSettingsRepository();
      localization = LocalizationCoordinator();
    });

    AppSettingsController build({AppSettings initial = const AppSettings(), String system = 'es'}) {
      final AppSettingsController controller = AppSettingsController(
        repository: repository,
        localization: localization,
        initial: initial,
        systemLanguageCode: system,
      );
      addTearDown(controller.close);
      return controller;
    }

    test('al crearse aplica el idioma guardado o, si no hay, el del sistema', () {
      build(system: 'en');
      expect(localization.languageCode.value, 'en');

      build(initial: const AppSettings(languageCode: 'es'), system: 'en');
      expect(localization.languageCode.value, 'es');
    });

    test('guarda cada cambio una sola vez', () async {
      final AppSettingsController controller = build();

      await controller.setTheme(AppThemePreference.dark);
      await controller.setTheme(AppThemePreference.dark);

      expect(controller.state.theme, AppThemePreference.dark);
      expect(repository.saved.theme, AppThemePreference.dark);
      expect(repository.saves, 1);
    });

    test('cambiar la vista del inicio la guarda sin tocar el resto', () async {
      final AppSettingsController controller = build(initial: const AppSettings(theme: AppThemePreference.dark));

      await controller.setHomeLayout(HomeLayout.grid);
      await controller.setHomeLayout(HomeLayout.grid);

      expect(repository.saved, const AppSettings(theme: AppThemePreference.dark, homeLayout: HomeLayout.grid));
      expect(repository.saves, 1);
    });

    test('los cambios de idioma del sistema solo se aplican sin idioma fijado', () async {
      final AppSettingsController controller = build();

      controller.systemLocalesChanged(const <Locale>[Locale('en', 'US')]);
      expect(localization.languageCode.value, 'en');

      await controller.setLanguage('es');
      controller.systemLocalesChanged(const <Locale>[Locale('en', 'GB')]);
      expect(localization.languageCode.value, 'es');

      await controller.setLanguage(null);
      expect(localization.languageCode.value, 'en');
      expect(repository.saved.languageCode, isNull);
    });
  });
}
