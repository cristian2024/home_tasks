import 'package:core_contracts/core_contracts.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/strings.g.dart';
import '../../navigation/app_router.dart';
import '../bloc/home_bloc.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appStrings.app.home;
    return Scaffold(
      appBar: AppBar(
        title: Text(appStrings.app.title),
        actions: [
          AppIconButton(
            icon: Icons.extension_outlined,
            tooltip: t.openCatalog,
            onPressed: () => context.push(AppRoutes.catalog),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.loading) {
            return const AppLoadingView();
          }
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
            onReorderItem: (oldIndex, newIndex) =>
                context.read<HomeBloc>().add(HomeTileMoved(oldIndex, newIndex)),
            itemBuilder: (context, index) {
              final tile = state.tiles[index];
              return Padding(
                key: ValueKey(tile.plugin.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: tile.status == PluginStatus.ready
                    ? tile.plugin.buildDashboardTile(context)
                    : _FailedTile(tile: tile, retrying: state.retrying),
              );
            },
          );
        },
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
    final t = appStrings.app.home;
    final name = context.read<LocalizationCoordinator>().translate(
      tile.plugin.nameKey,
    );
    return AppCard(
      child: Row(
        children: [
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
