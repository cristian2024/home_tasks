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
    final ItemTrackerTranslations$itemTracker$list$es listStrings = itemTrackerStrings.itemTracker.list;
    return Scaffold(
      appBar: AppTopBar(
        title: Text(listStrings.title),
        actions: <Widget>[
          BlocSelector<ItemListCubit, ItemListState, bool>(
            selector: (ItemListState state) => state.loading || state.all.isEmpty,
            builder: (BuildContext context, bool empty) => empty
                ? const SizedBox.shrink()
                : AppIconButton(icon: AppIcons.plus, tooltip: listStrings.create, onPressed: () => _create(context)),
          ),
        ],
      ),
      body: BlocBuilder<ItemListCubit, ItemListState>(
        builder: (BuildContext context, ItemListState state) {
          if (state.loading) {
            return const AppLoadingView();
          }
          if (state.all.isEmpty) {
            return AppStatusView(
              icon: AppIcons.box,
              title: listStrings.emptyTitle,
              message: listStrings.emptyMessage,
              action: AppButton(
                label: listStrings.create,
                icon: AppIcons.plus,
                size: AppButtonSize.medium,
                onPressed: () => _create(context),
              ),
            );
          }
          final List<HouseholdItem> visible = state.visible;
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: AppTextField(
                  label: listStrings.search,
                  prefixIcon: AppIcons.search,
                  textInputAction: TextInputAction.search,
                  onChanged: context.read<ItemListCubit>().search,
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? AppStatusView(icon: AppIcons.search, title: listStrings.noResults)
                    : ItemCardList(
                        items: visible,
                        subtitleBuilder: (HouseholdItem item) => formatItemPath(state.tree.pathOf(item.id)),
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
    final AppThemeColors colors = AppThemeColors.of(context);
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.s300, AppSpacing.sm, AppSpacing.s300),
          child: ExcludeSemantics(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: AppSpacing.s0,
              minTileHeight: AppSizes.iconMedium,
              enabled: onSelected == null || selectable,
              leading: const Icon(AppIcons.box),
              title: Text(item.name),
              subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
              trailing: selectable ? Icon(AppIcons.chevronRight, size: AppSizes.iconCompact, color: colors.textTertiary) : null,
            ),
          ),
        );
      },
    );
  }
}
