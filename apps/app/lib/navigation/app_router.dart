import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:core_hardware/core_hardware.dart';
import 'package:core_share/core_share.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_item_tracker/plugin_item_tracker.dart';

import '../catalog/catalog_cubit.dart';
import '../catalog/catalog_screen.dart';
import '../home/bloc/home_bloc.dart';
import '../home/presentation/home_dashboard_screen.dart';
import '../i18n/strings.g.dart';
import '../plugins/plugin_controller.dart';
import '../settings/settings_screen.dart';
import '../spaces/space_switcher.dart';
import '../spaces/space_title_cubit.dart';
import '../spaces/spaces_cubit.dart';
import '../spaces/spaces_screen.dart';
import '../sync/conflicts_cubit.dart';
import '../sync/conflicts_screen.dart';
import '../sync/invitation_cubit.dart';
import '../sync/invitation_screen.dart';
import '../sync/join_household_cubit.dart';
import '../sync/join_household_screen.dart';
import '../sync/sync_cubit.dart';
import '../sync/sync_screen.dart';
import '../sync/sync_services.dart';
import 'plugin_route_guard.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String catalog = '/plugins-catalog';
  static const String settings = '/settings';
  static const String sync = '/settings/sync';
  static const String syncInvitation = '/settings/sync/invitation';
  static const String syncJoin = '/settings/sync/join';
  static const String syncConflicts = '/settings/sync/conflicts';
  static const String spaces = '/settings/spaces';
}

/// Router de la app: inicio, catálogo y las rutas de **todos** los plugins
/// registrados. Las de plugins no listos las bloquea [PluginRouteGuard],
/// que redirige a inicio con un aviso; se reevalúa cuando cambian los plugins.
/// Con [sync], también las pantallas de la sincronización, que piden a
/// [locator] la cámara y los nombres de los objetos. Con [spaces], la
/// pantalla de los espacios de datos, y crear un hogar o unirse a uno puede
/// abrir otro espacio.
GoRouter buildAppRouter({
  required PluginRegistry registry,
  required PluginController controller,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
  String initialLocation = AppRoutes.home,
  SyncServices? sync,
  ServiceLocator? locator,
  SpaceSwitcher? spaces,
}) {
  final PluginRouteGuard guard = PluginRouteGuard(registry: registry, controller: controller);
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: controller,
    redirect: (BuildContext context, GoRouterState state) {
      final BlockedReason? reason = guard.check(state.uri.path);
      if (reason == null) {
        return null;
      }
      final String message = switch (reason) {
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
    routes: withLanguageRebuild(<RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        builder: (BuildContext context, GoRouterState state) => MultiBlocProvider(
          providers: <BlocProvider<Object?>>[
            BlocProvider<HomeBloc>(create: (_) => HomeBloc(controller)..add(const HomeStarted())),
            BlocProvider<SpaceTitleCubit>(create: (_) => SpaceTitleCubit(spaces)),
          ],
          child: const HomeDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.catalog,
        builder: (BuildContext context, GoRouterState state) => BlocProvider<CatalogCubit>(
          create: (_) => CatalogCubit(controller),
          child: const CatalogScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (BuildContext context, GoRouterState state) =>
            SettingsScreen(showSync: sync != null, showSpaces: spaces != null),
      ),
      if (spaces != null)
        GoRoute(
          path: AppRoutes.spaces,
          builder: (BuildContext context, GoRouterState state) => BlocProvider<SpacesCubit>(
            create: (_) => SpacesCubit(spaces),
            child: const SpacesScreen(),
          ),
        ),
      if (sync != null) ..._syncRoutes(sync, locator ?? ServiceLocator.instance, spaces),
      for (final HomePlugin plugin in registry.allPlugins) ...plugin.routes,
    ]),
  );
}

List<RouteBase> _syncRoutes(SyncServices sync, ServiceLocator locator, SpaceSwitcher? spaces) => <RouteBase>[
      GoRoute(
        path: AppRoutes.sync,
        builder: (BuildContext context, GoRouterState state) => BlocProvider<SyncCubit>(
          create: (_) => SyncCubit(sync, spaces: spaces),
          child: const SyncScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.syncInvitation,
        builder: (BuildContext context, GoRouterState state) => BlocProvider<InvitationCubit>(
          create: (_) => InvitationCubit(
            sync.households,
            share: locator.isRegistered<ShareService>() ? locator.get<ShareService>() : null,
          ),
          child: const InvitationScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.syncJoin,
        builder: (BuildContext context, GoRouterState state) => BlocProvider<JoinHouseholdCubit>(
          create: (_) => JoinHouseholdCubit(
            households: sync.households,
            spaces: spaces,
            // Los escáneres se registran como factorías: uno nuevo en cada get.
            cameraFactory: locator.isRegistered<CameraIdentifierScanner>()
                ? () => locator.get<CameraIdentifierScanner>()
                : null,
            permissions: locator.isRegistered<HardwarePermissions>() ? locator.get<HardwarePermissions>() : null,
          )..start(),
          child: const JoinHouseholdScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.syncConflicts,
        builder: (BuildContext context, GoRouterState state) => BlocProvider<ConflictsCubit>(
          create: (_) => ConflictsCubit(
            inbox: sync.inbox,
            items: locator.isRegistered<HouseholdItemRepository>() ? locator.get<HouseholdItemRepository>() : null,
          ),
          child: const ConflictsScreen(),
        ),
      ),
    ];

/// Envuelve el contenido de cada `GoRoute` con [LanguageRebuilder] para que
/// las páginas abiertas cambien de idioma (ver su documentación). Las rutas
/// con `pageBuilder` se dejan igual: ningún plugin lo usa todavía.
List<RouteBase> withLanguageRebuild(List<RouteBase> routes) => <RouteBase>[
  for (final RouteBase route in routes)
    if (route is GoRoute && route.builder != null)
      GoRoute(
        path: route.path,
        name: route.name,
        redirect: route.redirect,
        parentNavigatorKey: route.parentNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            LanguageRebuilder(child: route.builder!(context, state)),
        routes: withLanguageRebuild(route.routes),
      )
    else
      route,
];
