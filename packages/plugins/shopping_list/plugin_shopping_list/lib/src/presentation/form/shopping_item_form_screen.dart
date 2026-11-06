import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/shopping_list_l10n.dart';
import 'shopping_item_form_cubit.dart';

/// Crear o editar un item. Al guardar hace `pop` con su ID; al borrarlo,
/// `pop` sin resultado.
class ShoppingItemFormScreen extends StatefulWidget {
  const ShoppingItemFormScreen({super.key});

  @override
  State<ShoppingItemFormScreen> createState() => _ShoppingItemFormScreenState();
}

class _ShoppingItemFormScreenState extends State<ShoppingItemFormScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _every = TextEditingController();
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _name,
      _quantity,
      _notes,
      _every,
      _min,
      _max,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncInitialValues(ShoppingItemFormState state) {
    if (!_initialized && state.status != ShoppingItemFormStatus.loading) {
      _initialized = true;
      _name.text = state.name;
      _quantity.text = state.quantity;
      _notes.text = state.notes;
      _every.text = state.everyDays;
      _min.text = state.minDays;
      _max.text = state.maxDays;
    }
  }

  Future<void> _confirmDelete(ShoppingItemFormCubit cubit) async {
    final ShoppingListTranslations$shoppingList$form$es formStrings = shoppingListStrings.shoppingList.form;
    if (await showAppConfirmDialog(
      context,
      title: formStrings.deleteTitle(name: _name.text.trim()),
      message: formStrings.deleteMessage,
      confirmLabel: formStrings.delete,
      destructive: true,
    )) {
      await cubit.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es strings = shoppingListStrings.shoppingList;
    final ShoppingItemFormCubit cubit = context.read<ShoppingItemFormCubit>();
    return BlocConsumer<ShoppingItemFormCubit, ShoppingItemFormState>(
      listener: (BuildContext context, ShoppingItemFormState state) {
        _syncInitialValues(state);
        if (state.status == ShoppingItemFormStatus.saved) {
          context.pop(state.savedItemId);
        } else if (state.status == ShoppingItemFormStatus.deleted) {
          context.pop();
        }
      },
      builder: (BuildContext context, ShoppingItemFormState state) {
        _syncInitialValues(state);
        final ShoppingItemFormError? error = state.error;
        String? fieldError(ShoppingValidationField field) =>
            error is ShoppingItemFormValidationError && error.error.field == field
                ? validationMessage(error.error)
                : null;
        String? daysError(RecurrenceField field) => switch (error) {
              ShoppingItemFormInvalidDays(field: final RecurrenceField invalid) when invalid == field =>
                strings.errors.invalidDays,
              ShoppingItemFormInvalidRange() when field == RecurrenceField.min => strings.errors.invalidRange,
              _ => null,
            };

        final ThemeData theme = Theme.of(context);
        final RecurrenceMode recurrenceMode = state.recurrenceMode;
        final List<ShoppingCategory> categories = state.categories;

        return Scaffold(
          appBar: AppTopBar(
            title: Text(cubit.isEditing ? strings.form.editTitle : strings.form.createTitle),
            actions: <Widget>[
              if (cubit.isEditing)
                AppIconButton(
                  icon: Icons.delete_outline,
                  tooltip: strings.form.delete,
                  onPressed: () => _confirmDelete(cubit),
                ),
            ],
          ),
          body: state.status == ShoppingItemFormStatus.loading
              ? const AppLoadingView()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                  children: <Widget>[
                    if (error is ShoppingItemFormGeneralError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          errorMessage(error.error),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    AppTextField(
                      label: strings.form.name,
                      controller: _name,
                      maxLength: ShoppingValidator.maxNameLength,
                      textInputAction: TextInputAction.next,
                      errorText: fieldError(ShoppingValidationField.name),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: strings.form.quantity,
                      hint: strings.form.quantityHint,
                      controller: _quantity,
                      maxLength: ShoppingValidator.maxQuantityLength,
                      textInputAction: TextInputAction.next,
                      errorText: fieldError(ShoppingValidationField.quantity),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: strings.form.notes,
                      controller: _notes,
                      maxLines: 4,
                      maxLength: ShoppingValidator.maxNotesLength,
                      errorText: fieldError(ShoppingValidationField.notes),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppChoiceSelector<Urgency>(
                      label: strings.form.urgency,
                      padding: EdgeInsets.zero,
                      options: <AppChoice<Urgency>>[
                        for (final Urgency urgency in Urgency.values)
                          AppChoice<Urgency>(value: urgency, label: urgencyLabel(urgency)),
                      ],
                      selected: state.urgency,
                      onChanged: cubit.setUrgency,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: categories.isEmpty
                          ? Text(strings.form.noCategories)
                          : AppFilterChips<String>(
                              label: strings.form.categories,
                              options: <AppChoice<String>>[
                                for (final ShoppingCategory category in categories)
                                  AppChoice<String>(value: category.id, label: categoryName(category)),
                              ],
                              selected: state.categoryIds,
                              onChanged: cubit.setCategories,
                            ),
                    ),
                    AppChoiceSelector<RecurrenceMode>(
                      label: strings.form.recurrence,
                      padding: EdgeInsets.zero,
                      options: <AppChoice<RecurrenceMode>>[
                        AppChoice<RecurrenceMode>(value: RecurrenceMode.none, label: strings.form.recurrenceNone),
                        AppChoice<RecurrenceMode>(value: RecurrenceMode.fixed, label: strings.form.recurrenceFixed),
                        AppChoice<RecurrenceMode>(value: RecurrenceMode.range, label: strings.form.recurrenceRange),
                      ],
                      selected: recurrenceMode,
                      onChanged: cubit.setRecurrenceMode,
                    ),
                    if (recurrenceMode != RecurrenceMode.none) const SizedBox(height: AppSpacing.md),
                    if (recurrenceMode == RecurrenceMode.fixed)
                      AppTextField(
                        label: strings.form.everyDays,
                        controller: _every,
                        keyboardType: TextInputType.number,
                        helperText: strings.form.recurrenceHelp,
                        errorText: daysError(RecurrenceField.every),
                      ),
                    if (recurrenceMode == RecurrenceMode.range)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.s300,
                        children: <Widget>[
                          Expanded(
                            child: AppTextField(
                              label: strings.form.minDays,
                              controller: _min,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              errorText: daysError(RecurrenceField.min),
                            ),
                          ),
                          Expanded(
                            child: AppTextField(
                              label: strings.form.maxDays,
                              controller: _max,
                              keyboardType: TextInputType.number,
                              errorText: daysError(RecurrenceField.max),
                            ),
                          ),
                        ],
                      ),
                    if (recurrenceMode == RecurrenceMode.range) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        strings.form.recurrenceHelp,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                      ),
                    ),
                    AppFooterActions(
                      children: <Widget>[
                        AppButton(
                          label: commonStrings.common.save,
                          expand: true,
                          isLoading: state.status == ShoppingItemFormStatus.submitting,
                          onPressed: () => cubit.submit(
                            name: _name.text,
                            quantity: _quantity.text,
                            notes: _notes.text,
                            everyDays: _every.text,
                            minDays: _min.text,
                            maxDays: _max.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
