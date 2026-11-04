import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../domain/use_cases/delete_item.dart';
import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../item_tracker_routes.dart';
import 'item_detail_cubit.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (BuildContext context, ItemDetailState state) {
        final HouseholdItem? item = state.item;
        return Scaffold(
          appBar: AppBar(
            title: Text(item?.name ?? detailStrings.title),
            actions: <Widget>[
              if (item != null)
                AppIconButton(
                  icon: Icons.edit,
                  tooltip: detailStrings.edit,
                  onPressed: () => context.push<String>(ItemTrackerRoutes.edit(item.id)),
                ),
              if (item != null && state.status == ItemDetailStatus.loaded)
                AppIconButton(
                  icon: Icons.delete_outline,
                  tooltip: detailStrings.delete,
                  onPressed: () => _delete(context, state, item),
                ),
            ],
          ),
          body: switch (state.status) {
            ItemDetailStatus.loading => const AppLoadingView(),
            ItemDetailStatus.missing => AppStatusView(
                icon: Icons.search_off,
                title: detailStrings.missingTitle,
                message: detailStrings.missingMessage,
              ),
            ItemDetailStatus.loaded => _DetailBody(state: state, item: item!),
          },
        );
      },
    );
  }

  /// Confirma el borrado. Si el objeto contiene otros, pregunta qué hacer con
  /// ellos. Al borrarlo vuelve a la pantalla anterior (o al listado).
  Future<void> _delete(BuildContext context, ItemDetailState state, HouseholdItem item) async {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    final ItemDetailCubit cubit = context.read<ItemDetailCubit>();
    final HouseholdItem? container = state.path.lastOrNull;
    final DeletedContents? contents = state.children.isEmpty
        ? (await showAppConfirmDialog(
            context,
            title: detailStrings.deleteTitle(name: item.name),
            message: detailStrings.deleteMessage,
            confirmLabel: detailStrings.delete,
            destructive: true,
          ))
            ? DeletedContents.deleteAll
            : null
        : await showAppChoiceDialog<DeletedContents>(
            context,
            title: detailStrings.deleteTitle(name: item.name),
            message: detailStrings.deleteContentsMessage(n: state.descendantCount),
            options: <AppDialogOption<DeletedContents>>[
              AppDialogOption<DeletedContents>(
                value: DeletedContents.moveToParent,
                label: container == null ? detailStrings.keepContentsLoose : detailStrings.keepContentsIn(container: container.name),
              ),
              AppDialogOption<DeletedContents>(value: DeletedContents.deleteAll, label: detailStrings.deleteAll, destructive: true),
            ],
          );
    if (contents == null) {
      return;
    }
    final Object? error = await cubit.delete(contents);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error == null ? detailStrings.deleted(name: item.name) : errorMessage(error))));
    if (error == null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(ItemTrackerRoutes.items);
      }
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state, required this.item});

  final ItemDetailState state;
  final HouseholdItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        if (item.description.isNotEmpty)
          Text(item.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        _LocationSection(state: state, item: item),
        _ContentsSection(state: state, item: item),
        if (!item.metadata.isEmpty) _MetadataSection(metadata: item.metadata),
        _IdentifiersSection(state: state, item: item),
        _HistorySection(state: state, item: item),
      ],
    );
  }
}

/// Filas de una sección, en una tarjeta y separadas por líneas.
class _DetailGroup extends StatelessWidget {
  const _DetailGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (final (int index, Widget child) in children.indexed) ...<Widget>[
            if (index > 0) const Divider(height: AppSizes.strokeThin),
            child,
          ],
        ],
      ),
    );
  }
}

/// Contenedores navegables y acciones para mover el objeto.
class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.state, required this.item});

  final ItemDetailState state;
  final HouseholdItem item;

  Future<void> _moveOut(BuildContext context, String containerName) async {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    final ItemDetailCubit cubit = context.read<ItemDetailCubit>();
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: detailStrings.moveOutTitle,
      message: detailStrings.moveOutMessage(name: item.name, container: containerName),
      confirmLabel: detailStrings.moveOutConfirm,
    );
    if (!confirmed) {
      return;
    }
    final Object? error = await cubit.moveOut();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error == null ? detailStrings.movedOut(name: containerName) : errorMessage(error))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    final List<HouseholdItem> path = state.path;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(detailStrings.location),
        if (path.isEmpty)
          Text(detailStrings.locationRoot)
        else
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final (int index, HouseholdItem container) in path.indexed) ...<Widget>[
                if (index > 0) const ExcludeSemantics(child: Text('›')),
                Tooltip(
                  message: detailStrings.openContainer(name: container.name),
                  child: AppButton(
                    label: container.name,
                    variant: AppButtonVariant.text,
                    onPressed: () => context.push<void>(ItemTrackerRoutes.detail(container.id)),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: detailStrings.move,
          icon: Icons.drive_file_move_outline,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => context.push<String>(ItemTrackerRoutes.move(item.id)),
        ),
        if (path.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: detailStrings.moveOut,
            icon: Icons.outbox_outlined,
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => _moveOut(context, path.last.name),
          ),
        ],
      ],
    );
  }
}

/// Lo que contiene el objeto, con el aviso si supera el límite de niveles.
class _ContentsSection extends StatelessWidget {
  const _ContentsSection({required this.state, required this.item});

  final ItemDetailState state;
  final HouseholdItem item;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    final ThemeData theme = Theme.of(context);
    final List<HouseholdItem> children = state.children;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          detailStrings.contents,
          trailing: AppButton(
            label: detailStrings.addInside,
            icon: Icons.add_box_outlined,
            variant: AppButtonVariant.text,
            onPressed: state.canHoldMore ? () => context.push<String>(ItemTrackerRoutes.createInside(item.id)) : null,
          ),
        ),
        if (state.isOverflowing)
          AppCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(detailStrings.overflowing(depth: state.depth, max: state.maxDepth))),
              ],
            ),
          )
        else if (!state.canHoldMore)
          Text(detailStrings.full(max: state.maxDepth), style: theme.textTheme.bodySmall),
        if (children.isEmpty)
          Text(detailStrings.noContents)
        else
          _DetailGroup(
            children: <Widget>[
              for (final HouseholdItem child in children)
                AppSettingsTile(
                  icon: Icons.inventory_2_outlined,
                  title: child.name,
                  onTap: () => context.push<void>(ItemTrackerRoutes.detail(child.id)),
                ),
            ],
          ),
      ],
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.metadata});

  final ItemMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(detailStrings.metadata),
        _DetailGroup(
          children: <Widget>[
            for (final MapEntry<String, Object>(:String key, :Object value) in metadata.values.entries)
              ListTile(
                title: Text(key),
                subtitle: Text(switch (value) {
                  true => detailStrings.yes,
                  false => detailStrings.no,
                  _ => '$value',
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _IdentifiersSection extends StatelessWidget {
  const _IdentifiersSection({required this.state, required this.item});

  final ItemDetailState state;
  final HouseholdItem item;

  Future<void> _remove(BuildContext context, PhysicalIdentifier identifier) async {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    final ItemDetailCubit cubit = context.read<ItemDetailCubit>();
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: detailStrings.removeIdentifierTitle,
      message: detailStrings.removeIdentifierMessage(
        type: identifierTypeLabel(identifier.type),
        value: identifier.rawValue,
      ),
      confirmLabel: detailStrings.removeIdentifierConfirm,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final Object? error = await cubit.removeIdentifier(identifier);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error == null ? detailStrings.identifierRemoved : errorMessage(error))));
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    final List<PhysicalIdentifier> identifiers = state.identifiers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          detailStrings.identifiers,
          trailing: AppButton(
            label: detailStrings.addIdentifier,
            icon: Icons.add_link,
            variant: AppButtonVariant.text,
            onPressed: () => context.push<String>(ItemTrackerRoutes.addIdentifier(item.id)),
          ),
        ),
        if (identifiers.isEmpty)
          Text(detailStrings.noIdentifiers)
        else
          _DetailGroup(
            children: <Widget>[
              for (final PhysicalIdentifier identifier in identifiers)
                AppSettingsTile(
                  icon: switch (identifier.type) {
                    IdentifierType.nfc => Icons.nfc,
                    IdentifierType.barcode => Icons.barcode_reader,
                    IdentifierType.qr => Icons.qr_code,
                  },
                  title: identifierTypeLabel(identifier.type),
                  subtitle: identifier.rawValue,
                  trailing: AppIconButton(
                    icon: Icons.link_off,
                    tooltip: detailStrings.removeIdentifier(
                      type: identifierTypeLabel(identifier.type),
                      value: identifier.rawValue,
                    ),
                    onPressed: () => _remove(context, identifier),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.state, required this.item});

  final ItemDetailState state;
  final HouseholdItem item;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$detail$es detailStrings = itemTrackerStrings.itemTracker.detail;
    final ThemeData theme = Theme.of(context);
    final List<ItemEvent> events = state.events;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          detailStrings.history,
          trailing: AppButton(
            label: detailStrings.addEvent,
            icon: Icons.add,
            variant: AppButtonVariant.text,
            onPressed: () => context.push<void>(ItemTrackerRoutes.addEvent(item.id)),
          ),
        ),
        Text(
          detailStrings.eventsCount(n: events.length),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (events.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _DetailGroup(
            children: <Widget>[
              for (final ItemEvent event in events) _EventTile(event: event),
            ],
          ),
        ],
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final ItemEvent event;

  @override
  Widget build(BuildContext context) {
    final ({String? subtitle, String title}) text = describeEvent(event);
    return AppSettingsTile(
      icon: event.isTechnical ? Icons.history : Icons.sticky_note_2_outlined,
      title: text.title,
      subtitle: <String>[?text.subtitle, formatTimestamp(context, event.timestamp)].join('\n'),
    );
  }
}
