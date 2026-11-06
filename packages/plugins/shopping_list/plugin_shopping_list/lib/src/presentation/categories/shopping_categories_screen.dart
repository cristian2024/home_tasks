import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';
import 'shopping_categories_cubit.dart';

/// Gestión de las categorías de la lista.
class ShoppingCategoriesScreen extends StatefulWidget {
  const ShoppingCategoriesScreen({super.key});

  @override
  State<ShoppingCategoriesScreen> createState() => _ShoppingCategoriesScreenState();
}

class _ShoppingCategoriesScreenState extends State<ShoppingCategoriesScreen> {
  final TextEditingController _newName = TextEditingController();

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  Future<void> _create(ShoppingCategoriesCubit cubit) async {
    if (await cubit.create(_newName.text)) {
      _newName.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$categories$es categoryStrings = shoppingListStrings.shoppingList.categories;
    final ShoppingCategoriesCubit cubit = context.read<ShoppingCategoriesCubit>();
    return BlocConsumer<ShoppingCategoriesCubit, ShoppingCategoriesState>(
      listenWhen: (ShoppingCategoriesState previous, ShoppingCategoriesState current) =>
          current.error != null && current.error != previous.error,
      listener: (BuildContext context, ShoppingCategoriesState state) {
        cubit.clearError();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(state.error!))));
      },
      builder: (BuildContext context, ShoppingCategoriesState state) {
        final ShoppingCategoriesState(:List<ShoppingCategory> categories) = state;
        return Scaffold(
          appBar: AppTopBar(title: Text(categoryStrings.title)),
          body: state.loading
              ? const AppLoadingView()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: AppSpacing.sm,
                      children: <Widget>[
                        Expanded(
                          child: AppTextField(
                            label: categoryStrings.newLabel,
                            controller: _newName,
                            maxLength: ShoppingValidator.maxCategoryNameLength,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (String _) => _create(cubit),
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.add,
                          tooltip: categoryStrings.add,
                          variant: AppIconButtonVariant.primary,
                          onPressed: () => _create(cubit),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (categories.isEmpty) Text(categoryStrings.empty),
                    if (categories.isNotEmpty)
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < categories.length; i++) ...<Widget>[
                              if (i > 0) const Divider(height: AppSizes.strokeThin),
                              _CategoryRow(
                                key: ValueKey<String>(categories[i].id),
                                category: categories[i],
                                isFirst: i == 0,
                                isLast: i == categories.length - 1,
                                onMove: (int offset) => cubit.move(i, offset),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.category,
    required this.isFirst,
    required this.isLast,
    required this.onMove,
  });

  final ShoppingCategory category;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<int> onMove;

  Future<void> _rename(BuildContext context) async {
    final ShoppingCategoriesCubit cubit = context.read<ShoppingCategoriesCubit>();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _RenameDialog(initialName: categoryName(category)),
    );
    if (name != null) {
      await cubit.rename(category.id, name);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ShoppingListTranslations$shoppingList$categories$es categoryStrings = shoppingListStrings.shoppingList.categories;
    final ShoppingCategoriesCubit cubit = context.read<ShoppingCategoriesCubit>();
    final int usage = await cubit.usage(category.id);
    if (!context.mounted) {
      return;
    }
    final String name = categoryName(category);
    if (await showAppConfirmDialog(
      context,
      title: categoryStrings.deleteTitle(name: name),
      message: usage == 0 ? categoryStrings.deleteUnused : categoryStrings.deleteInUse(n: usage),
      confirmLabel: categoryStrings.delete(name: name),
      destructive: true,
    )) {
      await cubit.delete(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$categories$es categoryStrings = shoppingListStrings.shoppingList.categories;
    final String name = categoryName(category);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: AppSpacing.md),
      title: Text(name),
      trailing: Wrap(
        children: <Widget>[
          AppIconButton(
            icon: Icons.arrow_upward,
            tooltip: categoryStrings.moveUp(name: name),
            variant: AppIconButtonVariant.subtle,
            onPressed: isFirst ? null : () => onMove(-1),
          ),
          AppIconButton(
            icon: Icons.arrow_downward,
            tooltip: categoryStrings.moveDown(name: name),
            variant: AppIconButtonVariant.subtle,
            onPressed: isLast ? null : () => onMove(1),
          ),
          AppIconButton(
            icon: Icons.edit_outlined,
            tooltip: categoryStrings.rename(name: name),
            variant: AppIconButtonVariant.subtle,
            onPressed: () => _rename(context),
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            tooltip: categoryStrings.delete(name: name),
            variant: AppIconButtonVariant.subtle,
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}

/// Pide el nombre nuevo. Devuelve el texto escrito o `null` si se cancela.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$categories$es categoryStrings = shoppingListStrings.shoppingList.categories;
    return AlertDialog(
      title: Text(categoryStrings.renameTitle),
      content: SizedBox(
        // Sin esto, el diálogo se encoge al ancho mínimo del campo.
        width: double.maxFinite,
        child: AppTextField(
          label: categoryStrings.name,
          controller: _name,
          autofocus: true,
          maxLength: ShoppingValidator.maxCategoryNameLength,
          onSubmitted: (String value) => Navigator.of(context).pop(value),
        ),
      ),
      actions: <Widget>[
        AppButton(
          label: commonStrings.common.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: commonStrings.common.save,
          size: AppButtonSize.medium,
          onPressed: () => Navigator.of(context).pop(_name.text),
        ),
      ],
    );
  }
}
