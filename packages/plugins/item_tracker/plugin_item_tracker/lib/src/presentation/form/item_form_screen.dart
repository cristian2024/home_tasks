import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import '../item_tracker_routes.dart';
import 'item_form_cubit.dart';

/// Crear o editar un objeto. Al guardar hace `pop` con el ID del objeto.
class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _syncInitialValues(ItemFormState state) {
    if (!_initialized && state.status != ItemFormStatus.loading) {
      _initialized = true;
      _name.text = state.name;
      _description.text = state.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$form$es formStrings = itemTrackerStrings.itemTracker.form;
    final ItemFormCubit cubit = context.read<ItemFormCubit>();
    return BlocConsumer<ItemFormCubit, ItemFormState>(
      listener: (BuildContext context, ItemFormState state) {
        _syncInitialValues(state);
        if (state.status == ItemFormStatus.saved) {
          context.pop(state.savedItemId);
        }
      },
      builder: (BuildContext context, ItemFormState state) {
        _syncInitialValues(state);
        final ItemFormError? error = state.error;
        String? fieldError(ValidationField field) =>
            error is ItemFormValidationError && error.error.field == field ? validationMessage(error.error) : null;

        return Scaffold(
          appBar: AppTopBar(title: Text(cubit.isEditing ? formStrings.editTitle : formStrings.createTitle)),
          body: state.status == ItemFormStatus.loading
              ? const AppLoadingView()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                  children: <Widget>[
                    if (state.initialIdentifier case final ({String rawValue, IdentifierType type}) identifier?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppNote(
                          icon: AppIcons.link,
                          text: formStrings.initialIdentifier(
                            type: identifierTypeLabel(identifier.type),
                            value: identifier.rawValue,
                          ),
                        ),
                      ),
                    if (state.parentPath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppNote(icon: AppIcons.box, text: formStrings.parent(path: formatItemPath(state.parentPath))),
                      ),
                    if (error is ItemFormGeneralError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          errorMessage(error.error),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    AppTextField(
                      label: formStrings.name,
                      controller: _name,
                      maxLength: ItemValidator.maxNameLength,
                      textInputAction: TextInputAction.next,
                      errorText: fieldError(ValidationField.name),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: formStrings.description,
                      controller: _description,
                      maxLines: 4,
                      maxLength: ItemValidator.maxDescriptionLength,
                      errorText: fieldError(ValidationField.description),
                    ),
                    if (cubit.itemId case final String itemId?) ...<Widget>[
                      AppSectionHeader(
                        formStrings.identifiers,
                        trailing: AppButton(
                          label: formStrings.addIdentifier,
                          icon: AppIcons.link,
                          variant: AppButtonVariant.text,
                          onPressed: () => context.push<String>(ItemTrackerRoutes.addIdentifier(itemId)),
                        ),
                      ),
                      Text(formStrings.identifiersHelp, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    AppSectionHeader(
                      formStrings.metadata,
                      trailing: AppButton(
                        label: formStrings.addField,
                        icon: AppIcons.plus,
                        variant: AppButtonVariant.text,
                        onPressed: cubit.addEntry,
                      ),
                    ),
                    if (error is ItemFormValidationError &&
                        error.error.field == ValidationField.metadata &&
                        error.entryId == null)
                      Text(
                        validationMessage(error.error),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    for (final MetadataEntry entry in state.entries)
                      _MetadataRow(key: ValueKey<int>(entry.id), entry: entry, error: _entryError(error, entry)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      formStrings.metadataHelp,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppThemeColors.of(context).textSecondary),
                    ),
                  ],
                      ),
                    ),
                    AppFooterActions(
                      children: <Widget>[
                        AppButton(
                          label: formStrings.save,
                          expand: true,
                          isLoading: state.status == ItemFormStatus.submitting,
                          onPressed: () => cubit.submit(name: _name.text, description: _description.text),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  String? _entryError(ItemFormError? error, MetadataEntry entry) {
    final ItemTrackerTranslations$itemTracker$errors$es errors = itemTrackerStrings.itemTracker.errors;
    return switch (error) {
      ItemFormDuplicatedKey(:final String key, :final int entryId) when entryId == entry.id =>
        errors.metadataKeyDuplicated(key: key),
      ItemFormInvalidNumber(:final int entryId) when entryId == entry.id => errors.numberInvalid,
      ItemFormValidationError(:final ItemValidationException error, :final int? entryId) when entryId == entry.id =>
        validationMessage(error),
      _ => null,
    };
  }
}

class _MetadataRow extends StatefulWidget {
  const _MetadataRow({super.key, required this.entry, required this.error});

  final MetadataEntry entry;
  final String? error;

  @override
  State<_MetadataRow> createState() => _MetadataRowState();
}

class _MetadataRowState extends State<_MetadataRow> {
  late final TextEditingController _key = TextEditingController(text: widget.entry.key);
  late final TextEditingController _value = TextEditingController(text: widget.entry.text);

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$form$es formStrings = itemTrackerStrings.itemTracker.form;
    final ItemFormCubit cubit = context.read<ItemFormCubit>();
    final MetadataEntry entry = widget.entry;
    final Widget valueField = entry.type == MetadataValueType.boolean
        ? SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(formStrings.value),
            value: entry.flag,
            onChanged: (bool flag) => cubit.updateEntry(entry.copyWith(flag: flag)),
          )
        : AppTextField(
            label: formStrings.value,
            controller: _value,
            keyboardType: entry.type == MetadataValueType.number
                ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                : TextInputType.text,
            onChanged: (String text) => cubit.updateEntry(entry.copyWith(text: text)),
          );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s300),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s300,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: AppSpacing.xs,
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    label: formStrings.key,
                    controller: _key,
                    errorText: widget.error,
                    onChanged: (String key) => cubit.updateEntry(entry.copyWith(key: key)),
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.trash2,
                  tooltip: formStrings.removeField(key: entry.key.isEmpty ? '' : entry.key),
                  onPressed: () => cubit.removeEntry(entry.id),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: <Widget>[
                Expanded(child: _TypeField(entry: entry)),
                Expanded(child: valueField),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Elegir el tipo de un dato adicional, con su etiqueta encima como un campo.
class _TypeField extends StatelessWidget {
  const _TypeField({required this.entry});

  final MetadataEntry entry;

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$form$es formStrings = itemTrackerStrings.itemTracker.form;
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s150,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(formStrings.valueType, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
        ),
        Semantics(
          label: formStrings.valueType,
          child: DropdownMenu<MetadataValueType>(
            initialSelection: entry.type,
            expandedInsets: EdgeInsets.zero,
            trailingIcon: const Icon(AppIcons.chevronDown),
            selectedTrailingIcon: const Icon(AppIcons.chevronDown),
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s300),
              constraints: const BoxConstraints.tightFor(height: AppSizes.controlLarge),
            ),
            dropdownMenuEntries: <DropdownMenuEntry<MetadataValueType>>[
              DropdownMenuEntry<MetadataValueType>(value: MetadataValueType.text, label: formStrings.typeText),
              DropdownMenuEntry<MetadataValueType>(value: MetadataValueType.number, label: formStrings.typeNumber),
              DropdownMenuEntry<MetadataValueType>(value: MetadataValueType.boolean, label: formStrings.typeBoolean),
            ],
            onSelected: (MetadataValueType? type) =>
                context.read<ItemFormCubit>().updateEntry(entry.copyWith(type: type)),
          ),
        ),
      ],
    );
  }
}
