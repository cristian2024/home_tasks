import 'package:core_contracts/core_contracts.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/strings.g.dart';
import '../../navigation/app_router.dart';
import '../../settings/app_settings.dart';
import '../../settings/app_settings_controller.dart';
import '../bloc/home_bloc.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$home$es t = appStrings.app.home;
    final bool grid = context.select<AppSettingsController, bool>(
      (AppSettingsController settings) => settings.state.homeLayout == HomeLayout.grid,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(appStrings.app.title),
        actions: <Widget>[
          AppIconButton(
            icon: grid ? Icons.view_list_outlined : Icons.grid_view_outlined,
            tooltip: grid ? t.showList : t.showGrid,
            onPressed: () => context.read<AppSettingsController>().setHomeLayout(
              grid ? HomeLayout.list : HomeLayout.grid,
            ),
          ),
          AppIconButton(
            icon: Icons.settings_outlined,
            tooltip: t.openSettings,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (BuildContext context, HomeState state) {
          if (state.loading) {
            return const AppLoadingView();
          }
          return grid ? _ShortcutGrid(state: state) : _DashboardList(state: state);
        },
      ),
    );
  }
}

/// Vista de lista: las tarjetas de los plugins, reordenables.
class _DashboardList extends StatelessWidget {
  const _DashboardList({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$home$es t = appStrings.app.home;
    if (state.tiles.isEmpty) {
      return AppStatusView(
        icon: Icons.extension_off_outlined,
        title: t.emptyTitle,
        message: t.emptyMessage,
        action: AppButton(
          label: t.openCatalog,
          icon: Icons.extension_outlined,
          onPressed: () => context.push(AppRoutes.catalog),
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      header: state.tiles.length > 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                t.reorderHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : null,
      itemCount: state.tiles.length,
      onReorderItem: (int oldIndex, int newIndex) =>
          context.read<HomeBloc>().add(HomeTileMoved(oldIndex, newIndex)),
      itemBuilder: (BuildContext context, int index) {
        final PluginState tile = state.tiles[index];
        return Padding(
          key: ValueKey<String>(tile.plugin.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: tile.status == PluginStatus.ready
              ? tile.plugin.buildDashboardTile(context)
              : _FailedTile(tile: tile, retrying: state.retrying),
        );
      },
    );
  }
}

/// Vista de accesos rápidos: un icono por plugin, en el mismo orden que la
/// lista, y al final siempre «Añadir», que abre el catálogo.
class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) => AppShortcutGrid(
        children: <Widget>[
          for (final PluginState tile in state.tiles)
            _PluginShortcut(key: ValueKey<String>(tile.plugin.id), tile: tile, retrying: state.retrying),
          AppShortcutTile(
            icon: Icons.add,
            label: appStrings.app.home.addShortcut,
            onTap: () => context.push(AppRoutes.catalog),
          ),
        ],
      );
}

/// Acceso rápido de un plugin. Si el plugin tiene pantalla principal
/// ([HomePluginEntryRoute]) la abre; si no, muestra su tarjeta en una hoja
/// inferior, con todas sus acciones. Si no pudo iniciarse, se muestra con
/// error y reintenta.
class _PluginShortcut extends StatelessWidget {
  const _PluginShortcut({super.key, required this.tile, required this.retrying});

  final PluginState tile;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final HomePlugin plugin = tile.plugin;
    final String name = context.read<LocalizationCoordinator>().translate(plugin.nameKey);
    if (tile.status != PluginStatus.ready) {
      return AppShortcutTile(
        icon: plugin.icon,
        label: name,
        error: true,
        tooltip: appStrings.app.home.pluginFailed(name: name),
        onTap: retrying ? null : () => context.read<HomeBloc>().add(const HomeRetryRequested()),
      );
    }
    if (plugin case HomePluginEntryRoute(:final String entryRoute)) {
      return AppShortcutTile(icon: plugin.icon, label: name, onTap: () => context.push(entryRoute));
    }
    return AppShortcutTile(
      icon: plugin.icon,
      label: name,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (BuildContext context) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: plugin.buildDashboardTile(context),
        ),
      ),
    );
  }
}

/// Tarjeta local de error de un plugin que no pudo iniciarse (§6.2.6).
class _FailedTile extends StatelessWidget {
  const _FailedTile({required this.tile, required this.retrying});

  final PluginState tile;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final AppTranslations$app$home$es t = appStrings.app.home;
    final String name = context.read<LocalizationCoordinator>().translate(
      tile.plugin.nameKey,
    );
    return AppCard(
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(t.pluginFailed(name: name))),
          AppButton(
            label: t.retry,
            variant: AppButtonVariant.text,
            isLoading: retrying,
            onPressed: () =>
                context.read<HomeBloc>().add(const HomeRetryRequested()),
          ),
        ],
      ),
    );
  }
}
