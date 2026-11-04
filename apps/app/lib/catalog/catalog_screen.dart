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
    final AppTranslations$app$catalog$es catalogStrings = appStrings.app.catalog;
    final LocalizationCoordinator localization = context.read<LocalizationCoordinator>();
    final ThemeData theme = Theme.of(context);
    final TextStyle? descriptionStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: Text(catalogStrings.title)),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (BuildContext context, CatalogState state) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Text(catalogStrings.description, style: descriptionStyle),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (final (int index, PluginState plugin) in state.plugins.indexed) ...<Widget>[
                    if (index > 0) const Divider(height: AppSizes.strokeThin),
                    _CatalogEntry(
                      state: plugin,
                      localization: localization,
                      pending: state.pending.contains(plugin.plugin.id),
                    ),
                  ],
                ],
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
    final AppTranslations$app$catalog$es catalogStrings = appStrings.app.catalog;
    final HomePlugin plugin = state.plugin;
    final bool unavailable = state.status == PluginStatus.unavailable;
    final (String status, AppBadgeTone tone) = switch (state.status) {
      PluginStatus.unavailable => (catalogStrings.unavailable, AppBadgeTone.warning),
      PluginStatus.failed => (catalogStrings.failed, AppBadgeTone.critical),
      PluginStatus.ready => (catalogStrings.enabled, AppBadgeTone.success),
      PluginStatus.disabled => (catalogStrings.disabled, AppBadgeTone.neutral),
    };
    return SwitchListTile(
      secondary: Icon(plugin.icon),
      title: Text(localization.translate(plugin.nameKey)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(localization.translate(plugin.descriptionKey)),
          const SizedBox(height: AppSpacing.xs),
          AppBadge(label: status, tone: tone),
        ],
      ),
      value: state.preference.isEnabled,
      onChanged: unavailable || pending
          ? null
          : (bool enabled) => context.read<CatalogCubit>().setEnabled(
              plugin.id,
              enabled: enabled,
            ),
    );
  }
}
