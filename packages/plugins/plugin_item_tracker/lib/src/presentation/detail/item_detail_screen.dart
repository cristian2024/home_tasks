import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/household_item.dart';
import '../../domain/entities/physical_identifier.dart';
import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../item_tracker_routes.dart';
import 'item_detail_cubit.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.detail;
    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
        final item = state.item;
        return Scaffold(
          appBar: AppBar(
            title: Text(item?.name ?? t.title),
            actions: [
              if (item != null)
                AppIconButton(
                  icon: Icons.edit,
                  tooltip: t.edit,
                  onPressed: () => context.push<String>(ItemTrackerRoutes.edit(item.id)),
                ),
            ],
          ),
          body: switch (state.status) {
            ItemDetailStatus.loading => const AppLoadingView(),
            ItemDetailStatus.missing => AppStatusView(
                icon: Icons.search_off,
                title: t.missingTitle,
                message: t.missingMessage,
              ),
            ItemDetailStatus.loaded => _DetailBody(state: state, item: item!),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state, required this.item});

  final ItemDetailState state;
  final HouseholdItem item;

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.detail;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        ..._location(context),
        if (item.description.isNotEmpty) ...[
          Text(item.description, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!item.metadata.isEmpty) ...[
          AppSectionHeader(t.metadata),
          for (final MapEntry(:key, :value) in item.metadata.values.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(key),
              subtitle: Text(switch (value) {
                true => t.yes,
                false => t.no,
                _ => '$value',
              }),
            ),
        ],
        ..._contents(context),
        AppSectionHeader(
          t.identifiers,
          trailing: AppButton(
            label: t.addIdentifier,
            icon: Icons.add_link,
            variant: AppButtonVariant.text,
            onPressed: () => context.push<String>(ItemTrackerRoutes.addIdentifier(item.id)),
          ),
        ),
        if (state.identifiers.isEmpty)
          Text(t.noIdentifiers)
        else
          for (final identifier in state.identifiers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (identifier.type) {
                IdentifierType.nfc => Icons.nfc,
                IdentifierType.barcode => Icons.barcode_reader,
                IdentifierType.qr => Icons.qr_code,
              }),
              title: Text(identifier.rawValue),
              subtitle: Text(identifierTypeLabel(identifier.type)),
              trailing: AppIconButton(
                icon: Icons.link_off,
                tooltip: t.removeIdentifier(type: identifierTypeLabel(identifier.type), value: identifier.rawValue),
                onPressed: () => _removeIdentifier(context, identifier),
              ),
            ),
        AppSectionHeader(
          t.history,
          trailing: AppButton(
            label: t.addEvent,
            icon: Icons.add,
            variant: AppButtonVariant.text,
            onPressed: () => context.push<void>(ItemTrackerRoutes.addEvent(item.id)),
          ),
        ),
        Text(t.eventsCount(n: state.events.length), style: textTheme.bodySmall),
        for (final event in state.events)
          Builder(
            builder: (context) {
              final text = describeEvent(event);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(event.isTechnical ? Icons.history : Icons.sticky_note_2_outlined),
                title: Text(text.title),
                subtitle: Text(
                  [?text.subtitle, formatTimestamp(context, event.timestamp)].join('\n'),
                ),
              );
            },
          ),
      ],
    );
  }

  /// Contenedores navegables y acciones para mover el objeto.
  List<Widget> _location(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.detail;
    return [
      AppSectionHeader(t.location),
      if (state.path.isEmpty)
        Text(t.locationRoot)
      else
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (index, container) in state.path.indexed) ...[
              if (index > 0) const ExcludeSemantics(child: Text('›')),
              Tooltip(
                message: t.openContainer(name: container.name),
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
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            label: t.move,
            icon: Icons.drive_file_move_outline,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push<String>(ItemTrackerRoutes.move(item.id)),
          ),
          if (state.path.isNotEmpty)
            AppButton(
              label: t.moveOut,
              icon: Icons.outbox_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => _moveOut(context, state.path.last.name),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  /// Lo que contiene el objeto, con el aviso si supera el límite de niveles.
  List<Widget> _contents(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.detail;
    final colors = Theme.of(context).colorScheme;
    return [
      AppSectionHeader(
        t.contents,
        trailing: AppButton(
          label: t.addInside,
          icon: Icons.add_box_outlined,
          variant: AppButtonVariant.text,
          onPressed: state.canHoldMore ? () => context.push<String>(ItemTrackerRoutes.createInside(item.id)) : null,
        ),
      ),
      if (state.isOverflowing)
        AppCard(
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(t.overflowing(depth: state.depth, max: state.maxDepth))),
            ],
          ),
        )
      else if (!state.canHoldMore)
        Text(t.full(max: state.maxDepth), style: Theme.of(context).textTheme.bodySmall),
      if (state.children.isEmpty)
        Text(t.noContents)
      else
        for (final child in state.children)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(child.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push<void>(ItemTrackerRoutes.detail(child.id)),
          ),
    ];
  }

  Future<void> _moveOut(BuildContext context, String containerName) async {
    final t = itemTrackerStrings.itemTracker.detail;
    final cubit = context.read<ItemDetailCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: t.moveOutTitle,
      message: t.moveOutMessage(name: item.name, container: containerName),
      confirmLabel: t.moveOutConfirm,
    );
    if (!confirmed) {
      return;
    }
    final error = await cubit.moveOut();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error == null ? t.movedOut(name: containerName) : errorMessage(error))));
  }

  Future<void> _removeIdentifier(BuildContext context, PhysicalIdentifier identifier) async {
    final t = itemTrackerStrings.itemTracker.detail;
    final cubit = context.read<ItemDetailCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: t.removeIdentifierTitle,
      message: t.removeIdentifierMessage(type: identifierTypeLabel(identifier.type), value: identifier.rawValue),
      confirmLabel: t.removeIdentifierConfirm,
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    final error = await cubit.removeIdentifier(identifier);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error == null ? t.identifierRemoved : errorMessage(error))));
  }
}
