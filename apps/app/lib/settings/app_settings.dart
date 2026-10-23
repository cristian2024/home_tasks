import 'package:equatable/equatable.dart';

/// Tema elegido por el usuario. [system] sigue al del dispositivo.
enum AppThemePreference { system, light, dark }

/// Preferencias de la app (no de los plugins).
class AppSettings extends Equatable {
  const AppSettings({this.theme = AppThemePreference.system, this.languageCode});

  final AppThemePreference theme;

  /// Idioma fijado por el usuario; `null` sigue al idioma del sistema.
  final String? languageCode;

  AppSettings copyWith({AppThemePreference? theme, String? Function()? languageCode}) => AppSettings(
        theme: theme ?? this.theme,
        languageCode: languageCode == null ? this.languageCode : languageCode(),
      );

  @override
  List<Object?> get props => <Object?>[theme, languageCode];
}
