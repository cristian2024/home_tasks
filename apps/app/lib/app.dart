import 'dart:async';

import 'package:core_spaces/core_spaces.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_engine/sync_engine.dart';

import 'bootstrap.dart';
import 'i18n/strings.g.dart';
import 'navigation/app_router.dart';
import 'settings/app_settings.dart';
import 'settings/app_settings_controller.dart';
import 'spaces/space_switcher.dart';

class HomeUtilityApp extends StatefulWidget {
  const HomeUtilityApp({
    super.key,
    required this.environment,
    this.initialLocation = AppRoutes.home,
    this.spaces,
    this.notice,
  });

  final AppEnvironment environment;
  final String initialLocation;

  /// Espacios de datos, o `null` sin ellos (Configuración no los muestra).
  final SpaceSwitcher? spaces;

  /// Aviso del cambio de espacio que abrió este entorno.
  final SpaceNotice? notice;

  @override
  State<HomeUtilityApp> createState() => _HomeUtilityAppState();
}

class _HomeUtilityAppState extends State<HomeUtilityApp>
    with WidgetsBindingObserver {
  AppEnvironment get _environment => widget.environment;
  SpaceSwitcher? get _spaces => widget.spaces;

  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter _router = buildAppRouter(
    registry: _environment.registry,
    controller: _environment.plugins,
    messengerKey: _messengerKey,
    initialLocation: widget.initialLocation,
    sync: _environment.sync,
    locator: _environment.locator,
    spaces: _spaces,
  );

  StreamSubscription<String>? _shortcutSelections;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Después del primer frame, con el router ya montado. Una pulsación que
    // abrió la app en frío la guarda el servicio hasta este momento.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _shortcutSelections = _environment.shortcuts?.selections.listen(_openShortcut);
        unawaited(_showNotice());
      }
    });
  }

  /// Avisa de lo que pasó al cambiar de espacio.
  Future<void> _showNotice() async {
    final SpaceNotice? notice = widget.notice;
    final SpaceSwitcher? spaces = _spaces;
    if (notice == null || spaces == null) {
      return;
    }
    final DataSpace space = await spaces.activeSpace();
    final AppTranslations$app$spaces$es t = appStrings.app.spaces;
    final SnackBar snackBar = switch (notice) {
      SpaceNotice.switched => SnackBar(
          content: Text(space.isShared ? t.noticeShared(name: space.name) : t.noticeSwitched(name: space.name)),
        ),
      SpaceNotice.created => SnackBar(
          content: Text(t.noticeCreated),
          action: SnackBarAction(label: t.choosePlugins, onPressed: () => _router.push(AppRoutes.catalog)),
        ),
      SpaceNotice.failed => SnackBar(content: Text(t.noticeFailed(name: space.name))),
      SpaceNotice.actionFailed => SnackBar(content: Text(t.errorGeneric)),
    };
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Abre la pantalla principal del plugin del acceso pulsado. Si el plugin
  /// no está listo, el guard del router lleva al inicio con un aviso.
  void _openShortcut(String pluginId) {
    final String? route = _environment.shortcuts?.entryRouteOf(pluginId);
    if (route != null) {
      _router.go(route);
    }
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
      _environment.settings.systemLocalesChanged(locales);
    }
  }

  /// La sincronización solo corre en primer plano: en segundo plano el
  /// sistema cortaría la red igualmente.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final SyncController? sync = _environment.sync?.controller;
    if (sync == null) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(sync.resume());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(sync.pause());
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_shortcutSelections?.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizationCoordinator localization = _environment.localization;
    return RepositoryProvider<LocalizationCoordinator>.value(
      value: localization,
      child: BlocProvider<AppSettingsController>.value(
        value: _environment.settings,
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
