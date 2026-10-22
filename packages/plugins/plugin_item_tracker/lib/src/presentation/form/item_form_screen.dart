import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/errors/item_tracker_exception.dart';
import '../../domain/item_validator.dart';
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
  final _name = TextEditingController();
  final _description = TextEditingController();
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
    final t = itemTrackerStrings.itemTracker.form;
    final cubit = context.read<ItemFormCubit>();
    return BlocConsumer<ItemFormCubit, ItemFormState>(
      listener: (context, state) {
        _syncInitialValues(state);
        if (state.status == ItemFormStatus.saved) {
          context.pop(state.savedItemId);
        }
      },
      builder: (context, state) {
        _syncInitialValues(state);
        final error = state.error;
        String? fieldError(ValidationField field) =>
            error is ItemFormValidationError && error.error.field == field ? validationMessage(error.error) : null;

        return Scaffold(
          appBar: AppBar(title: Text(cubit.isEditing ? t.editTitle : t.createTitle)),
          body: state.status == ItemFormStatus.loading
              ? const AppLoadingView()
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (state.initialIdentifier case final identifier?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          child: Text(
                            t.initialIdentifier(
                              type: identifierTypeLabel(identifier.type),
                              value: identifier.rawValue,
                            ),
                          ),
                        ),
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
                      label: t.name,
                      controller: _name,
                      maxLength: ItemValidator.maxNameLength,
                      textInputAction: TextInputAction.next,
                      errorText: fieldError(ValidationField.name),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      label: t.description,
                      controller: _description,
                      maxLines: 4,
                      maxLength: ItemValidator.maxDescriptionLength,
                      errorText: fieldError(ValidationField.description),
                    ),
                    if (cubit.itemId case final itemId?) ...[
                      AppSectionHeader(
                        t.identifiers,
                        trailing: AppButton(
                          label: t.addIdentifier,
                          icon: Icons.add_link,
                          variant: AppButtonVariant.text,
                          onPressed: () => context.push<String>(ItemTrackerRoutes.addIdentifier(itemId)),
                        ),
                      ),
                      Text(t.identifiersHelp, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    AppSectionHeader(
                      t.metadata,
                      trailing: AppIconButton(icon: Icons.add, tooltip: t.addField, onPressed: cubit.addEntry),
                    ),
                    Text(t.metadataHelp, style: Theme.of(context).textTheme.bodySmall),
                    if (error is ItemFormValidationError &&
                        error.error.field == ValidationField.metadata &&
                        error.entryId == null)
                      Text(
                        validationMessage(error.error),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    for (final entry in state.entries)
                      _MetadataRow(key: ValueKey(entry.id), entry: entry, error: _entryError(error, entry)),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: t.save,
                      icon: Icons.check,
                      expand: true,
                      isLoading: state.status == ItemFormStatus.submitting,
                      onPressed: () => cubit.submit(name: _name.text, description: _description.text),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String? _entryError(ItemFormError? error, MetadataEntry entry) {
    final errors = itemTrackerStrings.itemTracker.errors;
    return switch (error) {
      ItemFormDuplicatedKey(:final key, :final entryId) when entryId == entry.id =>
        errors.metadataKeyDuplicated(key: key),
      ItemFormInvalidNumber(:final entryId) when entryId == entry.id => errors.numberInvalid,
      ItemFormValidationError(:final error, :final entryId) when entryId == entry.id => validationMessage(error),
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
  late final _key = TextEditingController(text: widget.entry.key);
  late final _value = TextEditingController(text: widget.entry.text);

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = itemTrackerStrings.itemTracker.form;
    final cubit = context.read<ItemFormCubit>();
    final entry = widget.entry;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: t.key,
                    controller: _key,
                    errorText: widget.error,
                    onChanged: (key) => cubit.updateEntry(entry.copyWith(key: key)),
                  ),
                ),
                AppIconButton(
                  icon: Icons.delete_outline,
                  tooltip: t.removeField(key: entry.key.isEmpty ? '' : entry.key),
                  onPressed: () => cubit.removeEntry(entry.id),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownMenu<MetadataValueType>(
              label: Text(t.valueType),
              initialSelection: entry.type,
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: [
                DropdownMenuEntry(value: MetadataValueType.text, label: t.typeText),
                DropdownMenuEntry(value: MetadataValueType.number, label: t.typeNumber),
                DropdownMenuEntry(value: MetadataValueType.boolean, label: t.typeBoolean),
              ],
              onSelected: (type) => cubit.updateEntry(entry.copyWith(type: type)),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (entry.type == MetadataValueType.boolean)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.value),
                value: entry.flag,
                onChanged: (flag) => cubit.updateEntry(entry.copyWith(flag: flag)),
              )
            else
              AppTextField(
                label: t.value,
                controller: _value,
                keyboardType: entry.type == MetadataValueType.number
                    ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                    : TextInputType.text,
                onChanged: (text) => cubit.updateEntry(entry.copyWith(text: text)),
              ),
          ],
        ),
      ),
    );
  }
}
