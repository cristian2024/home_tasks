import 'package:equatable/equatable.dart';

/// Tema elegido por el usuario. [system] sigue al del dispositivo.
enum AppThemePreference { system, light, dark }

/// Cómo muestra el inicio los plugins activos: tarjetas en lista o accesos
/// rápidos en grilla. No cambia qué plugins hay ni su orden.
enum HomeLayout { list, grid }

/// Preferencias de la app (no de los plugins).
class AppSettings extends Equatable {
  const AppSettings({this.theme = AppThemePreference.system, this.languageCode, this.homeLayout = HomeLayout.list});

  final AppThemePreference theme;

  /// Idioma fijado por el usuario; `null` sigue al idioma del sistema.
  final String? languageCode;

  final HomeLayout homeLayout;

  AppSettings copyWith({AppThemePreference? theme, String? Function()? languageCode, HomeLayout? homeLayout}) =>
      AppSettings(
        theme: theme ?? this.theme,
        languageCode: languageCode == null ? this.languageCode : languageCode(),
        homeLayout: homeLayout ?? this.homeLayout,
      );

  @override
  List<Object?> get props => <Object?>[theme, languageCode, homeLayout];
}
