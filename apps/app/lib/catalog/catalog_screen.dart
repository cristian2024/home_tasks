import 'package:core_contracts/core_contracts.dart';
import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../i18n/strings.g.dart';
import 'catalog_cubit.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = appStrings.app.catalog;
    final localization = context.read<LocalizationCoordinator>();
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(t.description),
            const SizedBox(height: AppSpacing.md),
            for (final plugin in state.plugins)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CatalogEntry(
                  state: plugin,
                  localization: localization,
                  pending: state.pending.contains(plugin.plugin.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatalogEntry extends StatelessWidget {
  const _CatalogEntry({
    required this.state,
    required this.localization,
    required this.pending,
  });

  final PluginState state;
  final LocalizationCoordinator localization;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final t = appStrings.app.catalog;
    final plugin = state.plugin;
    final unavailable = state.status == PluginStatus.unavailable;
    final status = switch (state.status) {
      PluginStatus.unavailable => t.unavailable,
      PluginStatus.failed => t.failed,
      PluginStatus.ready => t.enabled,
      PluginStatus.disabled => t.disabled,
    };
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(plugin.icon),
        title: Text(localization.translate(plugin.nameKey)),
        subtitle: Text(
          '${localization.translate(plugin.descriptionKey)}\n$status',
        ),
        isThreeLine: true,
        value: state.preference.isEnabled,
        onChanged: unavailable || pending
            ? null
            : (enabled) => context.read<CatalogCubit>().setEnabled(
                plugin.id,
                enabled: enabled,
              ),
      ),
    );
  }
}
