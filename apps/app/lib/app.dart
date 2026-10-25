import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bootstrap.dart';
import 'i18n/strings.g.dart';
import 'navigation/app_router.dart';
import 'settings/app_settings.dart';
import 'settings/app_settings_controller.dart';

class HomeUtilityApp extends StatefulWidget {
  const HomeUtilityApp({
    super.key,
    required this.environment,
    this.initialLocation = AppRoutes.home,
  });

  final AppEnvironment environment;
  final String initialLocation;

  @override
  State<HomeUtilityApp> createState() => _HomeUtilityAppState();
}

class _HomeUtilityAppState extends State<HomeUtilityApp>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter _router = buildAppRouter(
    registry: widget.environment.registry,
    controller: widget.environment.plugins,
    messengerKey: _messengerKey,
    initialLocation: widget.initialLocation,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(HomeUtilityApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      identical(oldWidget.environment, widget.environment),
      'El router se crea con el primer entorno: para cambiarlo (p. ej. al '
      'simular un reinicio en un test) usa una key distinta.',
    );
  }

  /// Sigue al idioma del sistema si el usuario lo cambia con la app abierta
  /// (solo si no fijó uno en Configuración).
  @override
  void didChangeLocales(List<Locale>? locales) {
    if (locales != null) {
      widget.environment.settings.systemLocalesChanged(locales);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationCoordinator localization = widget.environment.localization;
    return RepositoryProvider<LocalizationCoordinator>.value(
      value: localization,
      child: BlocProvider<AppSettingsController>.value(
        value: widget.environment.settings,
        // Las páginas (ver `withLanguageRebuild`) dependen de este scope.
        child: LanguageScope(
          languageCode: localization.languageCode,
          child: ValueListenableBuilder<String>(
            valueListenable: localization.languageCode,
            builder: (BuildContext context, String languageCode, _) => MaterialApp.router(
              onGenerateTitle: (_) => appStrings.app.title,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: switch (context
                  .watch<AppSettingsController>()
                  .state
                  .theme) {
                AppThemePreference.system => ThemeMode.system,
                AppThemePreference.light => ThemeMode.light,
                AppThemePreference.dark => ThemeMode.dark,
              },
              locale: Locale(languageCode),
              supportedLocales: LocalizationCoordinator.supportedLocales,
              localizationsDelegates:
                  LocalizationCoordinator.localizationsDelegates,
              scaffoldMessengerKey: _messengerKey,
              routerConfig: _router,
            ),
          ),
        ),
      ),
    );
  }
}
