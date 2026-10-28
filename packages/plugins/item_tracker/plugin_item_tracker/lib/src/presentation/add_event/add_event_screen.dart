import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/item_tracker_l10n.dart';
import 'add_event_cubit.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItemTrackerTranslations$itemTracker$addEvent$es t = itemTrackerStrings.itemTracker.addEvent;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocConsumer<AddEventCubit, AddEventState>(
        listener: (BuildContext context, AddEventState state) {
          if (state.status == AddEventStatus.saved) {
            context.pop();
          }
        },
        builder: (BuildContext context, AddEventState state) {
          final Object? error = state.error;
          String? fieldError(ValidationField field) =>
              error is ItemValidationException && error.field == field ? validationMessage(error) : null;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              if (error != null && error is! ItemValidationException)
                Text(errorMessage(error), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              AppTextField(
                label: t.eventTitle,
                controller: _title,
                autofocus: true,
                maxLength: ItemValidator.maxEventTitleLength,
                textInputAction: TextInputAction.next,
                errorText: fieldError(ValidationField.eventTitle),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: t.eventDescription,
                controller: _description,
                maxLines: 4,
                maxLength: ItemValidator.maxDescriptionLength,
                errorText: fieldError(ValidationField.eventDescription),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: t.save,
                icon: Icons.check,
                expand: true,
                isLoading: state.status == AddEventStatus.submitting,
                onPressed: () =>
                    context.read<AddEventCubit>().submit(title: _title.text, description: _description.text),
              ),
            ],
          );
        },
      ),
    );
  }
}
