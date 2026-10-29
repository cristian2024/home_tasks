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
    final ShoppingListTranslations$shoppingList$form$es t = shoppingListStrings.shoppingList.form;
    if (await showAppConfirmDialog(
      context,
      title: t.deleteTitle(name: _name.text.trim()),
      message: t.deleteMessage,
      confirmLabel: t.delete,
      destructive: true,
    )) {
      await cubit.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingListTranslations$shoppingList$es t = shoppingListStrings.shoppingList;
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
                t.errors.invalidDays,
              ShoppingItemFormInvalidRange() when field == RecurrenceField.min => t.errors.invalidRange,
              _ => null,
            };

        return Scaffold(
          appBar: AppBar(
            title: Text(cubit.isEditing ? t.form.editTitle : t.form.createTitle),
            actions: <Widget>[
              if (cubit.isEditing)
                AppIconButton(
                  icon: Icons.delete_outline,
                  tooltip: t.form.delete,
                  onPressed: () => _confirmDelete(cubit),
                ),
            ],
          ),
          body: state.status == ShoppingItemFormStatus.loading
              ? const AppLoadingView()
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: <Widget>[
                    if (error is ShoppingItemFormGeneralError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          errorMessage(error.error),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    AppTextField(
                      label: t.form.name,
                      controller: _name,
                      maxLength: ShoppingValidator.maxNameLength,
                      textInputAction: TextInputAction.next,
                      errorText: fieldError(ShoppingValidationField.name),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      label: t.form.quantity,
                      hint: t.form.quantityHint,
                      controller: _quantity,
                      maxLength: ShoppingValidator.maxQuantityLength,
                      textInputAction: TextInputAction.next,
                      errorText: fieldError(ShoppingValidationField.quantity),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      label: t.form.notes,
                      controller: _notes,
                      maxLines: 3,
                      maxLength: ShoppingValidator.maxNotesLength,
                      errorText: fieldError(ShoppingValidationField.notes),
                    ),
                    AppChoiceSelector<Urgency>(
                      label: t.form.urgency,
                      icon: Icons.priority_high,
                      options: <AppChoice<Urgency>>[
                        for (final Urgency urgency in Urgency.values)
                          AppChoice<Urgency>(value: urgency, label: urgencyLabel(urgency)),
                      ],
                      selected: state.urgency,
                      onChanged: cubit.setUrgency,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: state.categories.isEmpty
                          ? Text(t.form.noCategories)
                          : AppFilterChips<String>(
                              label: t.form.categories,
                              options: <AppChoice<String>>[
                                for (final ShoppingCategory category in state.categories)
                                  AppChoice<String>(value: category.id, label: categoryName(category)),
                              ],
                              selected: state.categoryIds,
                              onChanged: cubit.setCategories,
                            ),
                    ),
                    AppChoiceSelector<RecurrenceMode>(
                      label: t.form.recurrence,
                      icon: Icons.repeat,
                      options: <AppChoice<RecurrenceMode>>[
                        AppChoice<RecurrenceMode>(value: RecurrenceMode.none, label: t.form.recurrenceNone),
                        AppChoice<RecurrenceMode>(value: RecurrenceMode.fixed, label: t.form.recurrenceFixed),
                        AppChoice<RecurrenceMode>(value: RecurrenceMode.range, label: t.form.recurrenceRange),
                      ],
                      selected: state.recurrenceMode,
                      onChanged: cubit.setRecurrenceMode,
                    ),
                    if (state.recurrenceMode == RecurrenceMode.fixed)
                      AppTextField(
                        label: t.form.everyDays,
                        controller: _every,
                        keyboardType: TextInputType.number,
                        helperText: t.form.recurrenceHelp,
                        errorText: daysError(RecurrenceField.every),
                      ),
                    if (state.recurrenceMode == RecurrenceMode.range) ...<Widget>[
                      AppTextField(
                        label: t.form.minDays,
                        controller: _min,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        errorText: daysError(RecurrenceField.min),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: t.form.maxDays,
                        controller: _max,
                        keyboardType: TextInputType.number,
                        helperText: t.form.recurrenceHelp,
                        errorText: daysError(RecurrenceField.max),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: commonStrings.common.save,
                      icon: Icons.check,
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
        );
      },
    );
  }
}
