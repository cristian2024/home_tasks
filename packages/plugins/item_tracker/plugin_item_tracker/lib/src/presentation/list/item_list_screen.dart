import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../item_tracker_routes.dart';
import 'item_list_cubit.dart';

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final String? itemId = await context.push<String>(ItemTrackerRoutes.create);
    if (itemId != null && context.mounted) {
      await context.push<void>(ItemTrackerRoutes.detail(itemId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$list$es t = itemTrackerStrings.itemTracker.list;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.title),
        actions: <Widget>[AppIconButton(icon: Icons.add, tooltip: t.create, onPressed: () => _create(context))],
      ),
      body: BlocBuilder<ItemListCubit, ItemListState>(
        builder: (BuildContext context, ItemListState state) {
          if (state.loading) {
            return const AppLoadingView();
          }
          if (state.all.isEmpty) {
            return AppStatusView(
              icon: Icons.inventory_2_outlined,
              title: t.emptyTitle,
              message: t.emptyMessage,
              action: AppButton(label: t.create, icon: Icons.add, onPressed: () => _create(context)),
            );
          }
          final List<HouseholdItem> visible = state.visible;
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppTextField(
                  label: t.search,
                  textInputAction: TextInputAction.search,
                  onChanged: context.read<ItemListCubit>().search,
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? AppStatusView(icon: Icons.search_off, title: t.noResults)
                    : ItemCardList(
                        items: visible,
                        subtitleBuilder: (HouseholdItem item) => <String>[
                          formatItemPath(state.tree.pathOf(item.id)),
                          item.description,
                        ].where((String line) => line.isNotEmpty).join('\n'),
                        onSelected: (HouseholdItem item) => context.push<void>(ItemTrackerRoutes.detail(item.id)),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lista de tarjetas de objetos, compartida por el listado, "Asociar" y
/// "Mover a…".
class ItemCardList extends StatelessWidget {
  const ItemCardList({
    super.key,
    required this.items,
    required this.onSelected,
    this.semanticLabelBuilder,
    this.subtitleBuilder,
    this.enabledBuilder,
  });

  final List<HouseholdItem> items;
  final ValueChanged<HouseholdItem>? onSelected;
  final String Function(HouseholdItem item)? semanticLabelBuilder;

  /// Subtítulo de cada tarjeta; por defecto, la descripción.
  final String Function(HouseholdItem item)? subtitleBuilder;

  /// Si se puede elegir el objeto; por defecto, todos.
  final bool Function(HouseholdItem item)? enabledBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final HouseholdItem item = items[index];
        final String subtitle = subtitleBuilder?.call(item) ?? item.description;
        final bool selectable = onSelected != null && (enabledBuilder?.call(item) ?? true);
        final String semanticLabel = semanticLabelBuilder?.call(item) ?? item.name;
        return AppCard(
          semanticLabel: subtitle.isEmpty ? semanticLabel : '$semanticLabel. $subtitle',
          onTap: selectable ? () => onSelected!(item) : null,
          child: ExcludeSemantics(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: onSelected == null || selectable,
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(item.name),
              subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: selectable ? const Icon(Icons.chevron_right) : null,
            ),
          ),
        );
      },
    );
  }
}
