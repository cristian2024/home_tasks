import 'package:core_contracts/core_contracts.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../catalog/catalog_cubit.dart';
import '../catalog/catalog_screen.dart';
import '../home/bloc/home_bloc.dart';
import '../home/presentation/home_dashboard_screen.dart';
import '../i18n/strings.g.dart';
import '../plugins/plugin_controller.dart';
import '../settings/settings_screen.dart';
import 'plugin_route_guard.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String catalog = '/plugins-catalog';
  static const String settings = '/settings';
}

/// Router de la app: inicio, catálogo y las rutas de **todos** los plugins
/// registrados. Las de plugins no listos las bloquea [PluginRouteGuard],
/// que redirige a inicio con un aviso; se reevalúa cuando cambian los plugins.
GoRouter buildAppRouter({
  required PluginRegistry registry,
  required PluginController controller,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
  String initialLocation = AppRoutes.home,
}) {
  final guard = PluginRouteGuard(registry: registry, controller: controller);
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: controller,
    redirect: (context, state) {
      final reason = guard.check(state.uri.path);
      if (reason == null) {
        return null;
      }
      final message = switch (reason) {
        BlockedReason.disabled => appStrings.app.guard.pluginDisabled,
        BlockedReason.unavailable => appStrings.app.guard.pluginUnavailable,
      };
      // El redirect ocurre durante la navegación: el aviso, en el siguiente frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      });
      return AppRoutes.home;
    },
    routes: withLanguageRebuild([
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => BlocProvider(
          create: (_) => HomeBloc(controller)..add(const HomeStarted()),
          child: const HomeDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.catalog,
        builder: (context, state) => BlocProvider(
          create: (_) => CatalogCubit(controller),
          child: const CatalogScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      for (final plugin in registry.allPlugins) ...plugin.routes,
    ]),
  );
}

/// Envuelve el contenido de cada `GoRoute` con [LanguageRebuilder] para que
/// las páginas abiertas cambien de idioma (ver su documentación). Las rutas
/// con `pageBuilder` se dejan igual: ningún plugin lo usa todavía.
List<RouteBase> withLanguageRebuild(List<RouteBase> routes) => [
  for (final route in routes)
    if (route is GoRoute && route.builder != null)
      GoRoute(
        path: route.path,
        name: route.name,
        redirect: route.redirect,
        parentNavigatorKey: route.parentNavigatorKey,
        builder: (context, state) =>
            LanguageRebuilder(child: route.builder!(context, state)),
        routes: withLanguageRebuild(route.routes),
      )
    else
      route,
];
