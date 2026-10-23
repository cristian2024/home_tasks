import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:core_ui/core_ui.dart';

import 'app_settings.dart';
import 'app_settings_repository.dart';

/// Preferencias de la app en uso (Cubit, §11.1). Aplica el idioma a
/// [LocalizationCoordinator] y guarda cada cambio; el tema lo lee
/// `HomeUtilityApp` del estado.
class AppSettingsController extends Cubit<AppSettings> {
  /// Aplica ya el idioma de [initial]: con `languageCode` nulo, el del sistema
  /// ([systemLanguageCode]).
  AppSettingsController({
    required AppSettingsRepository repository,
    required LocalizationCoordinator localization,
    required AppSettings initial,
    required String systemLanguageCode,
  })  : _repository = repository,
        _localization = localization,
        _systemLanguageCode = systemLanguageCode,
        super(initial) {
    _applyLanguage();
  }

  final AppSettingsRepository _repository;
  final LocalizationCoordinator _localization;
  String _systemLanguageCode;

  Future<void> setTheme(AppThemePreference theme) => _update(state.copyWith(theme: theme));

  /// Fija el idioma, o vuelve al del sistema con `null`.
  Future<void> setLanguage(String? languageCode) async {
    await _update(state.copyWith(languageCode: () => languageCode));
    _applyLanguage();
  }

  /// El idioma del dispositivo cambió con la app abierta: se aplica solo si
  /// el usuario no fijó uno.
  void systemLocalesChanged(List<Locale> locales) {
    _systemLanguageCode = LocalizationCoordinator.resolveLanguage(locales);
    _applyLanguage();
  }

  Future<void> _update(AppSettings settings) async {
    if (settings == state) {
      return;
    }
    emit(settings);
    await _repository.save(settings);
  }

  void _applyLanguage() => _localization.setLanguage(state.languageCode ?? _systemLanguageCode);
}
