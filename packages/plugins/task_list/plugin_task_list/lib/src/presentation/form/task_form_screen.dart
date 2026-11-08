import 'package:core_ui/core_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_list_domain/task_list_domain.dart';

import '../../i18n/strings.g.dart';
import '../common/task_list_l10n.dart';
import 'task_form_cubit.dart';

/// Caracteres restantes a partir de los que se avisa a los lectores de
/// pantalla.
const int _remainingWarning = 10;

/// Crear o editar una tarea. Al guardar hace `pop` con su ID; al borrarla,
/// `pop` sin resultado.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, required this.today});

  /// El día local de hoy, del `Clock`.
  final DateTime Function() today;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _every = TextEditingController();
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  bool _initialized = false;
  bool _warnedRemaining = false;

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[_title, _every, _min, _max]) {
      controller.dispose();
    }
    _titleFocus.dispose();
    super.dispose();
  }

  void _announce(String message) =>
      SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context));

  void _syncInitialValues(TaskFormState state) {
    if (!_initialized && state.status != TaskFormStatus.loading) {
      _initialized = true;
      _title.text = state.title;
      _every.text = state.everyDays;
      _min.text = state.minDays;
      _max.text = state.maxDays;
    }
  }

  /// Avisa una vez al quedar pocos caracteres.
  void _onTitleChanged(String value) {
    final int remaining = TaskValidator.maxTitleLength - value.length;
    if (remaining <= _remainingWarning && remaining >= 0 && !_warnedRemaining) {
      _warnedRemaining = true;
      _announce(taskListStrings.taskList.form.remaining(n: remaining));
    } else if (remaining > _remainingWarning) {
      _warnedRemaining = false;
    }
  }

  Future<void> _pickDate(TaskFormCubit cubit, DateTime? current) async {
    final TaskListTranslations$taskList$dateSheet$es sheetStrings = taskListStrings.taskList.dateSheet;
    final TaskListTranslations$taskList$dates$es dateStrings = taskListStrings.taskList.dates;
    final DateTime today = widget.today();
    final DateTime local = DateTime(today.year, today.month, today.day);
    final int daysToSaturday = (DateTime.saturday - local.weekday + DateTime.daysPerWeek) % DateTime.daysPerWeek;
    final AppDateChoice? choice = await showAppDateSheet(
      context,
      texts: AppDateSheetTexts(
        title: sheetStrings.title,
        fieldLabel: sheetStrings.typeDate,
        fieldHint: sheetStrings.typeDateHint,
        invalidDate: sheetStrings.invalidDate,
        save: commonStrings.common.save,
        calendar: sheetStrings.calendar,
        remove: current == null ? null : sheetStrings.remove,
      ),
      options: <AppDateOption>[
        AppDateOption(label: dateStrings.today, date: local),
        AppDateOption(label: dateStrings.tomorrow, date: local.add(const Duration(days: 1))),
        // El viernes, el sábado es mañana; el sábado, el próximo es en una semana.
        if (daysToSaturday > 1)
          AppDateOption(label: sheetStrings.saturday, date: local.add(Duration(days: daysToSaturday))),
        AppDateOption(label: sheetStrings.inAWeek, date: local.add(const Duration(days: DateTime.daysPerWeek))),
      ],
      firstDate: DateTime(local.year - 1),
      lastDate: DateTime(local.year + 10),
      initialDate: current == null ? null : DateTime(current.year, current.month, current.day),
    );
    if (choice != null) {
      final DateTime? date = choice.date;
      cubit.setDueDate(date == null ? null : CalendarDay.of(date));
    }
  }

  Future<void> _confirmDelete(TaskFormCubit cubit) async {
    final TaskListTranslations$taskList$form$es formStrings = taskListStrings.taskList.form;
    if (await showAppConfirmDialog(
      context,
      title: formStrings.deleteTitle(name: _title.text.trim()),
      message: formStrings.deleteMessage,
      confirmLabel: taskListStrings.taskList.delete,
      destructive: true,
    )) {
      await cubit.delete();
    }
  }

  void _onState(BuildContext context, TaskFormState state) {
    final TaskListTranslations$taskList$form$es formStrings = taskListStrings.taskList.form;
    _syncInitialValues(state);
    final TaskFormError? error = state.error;
    if (state.status == TaskFormStatus.saved) {
      _announce(formStrings.saved);
      context.pop(state.savedTaskId);
    } else if (state.status == TaskFormStatus.deleted) {
      _announce(formStrings.deleted);
      context.pop();
    } else if (error is TaskFormValidationError && error.error.field == TaskValidationField.title) {
      _titleFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TaskListTranslations$taskList$es strings = taskListStrings.taskList;
    final TaskListTranslations$taskList$form$es formStrings = strings.form;
    final TaskFormCubit cubit = context.read<TaskFormCubit>();
    return BlocConsumer<TaskFormCubit, TaskFormState>(
      listener: _onState,
      builder: (BuildContext context, TaskFormState state) {
        _syncInitialValues(state);
        final TaskFormError? error = state.error;
        final String? titleError =
            error is TaskFormValidationError && error.error.field == TaskValidationField.title ? validationMessage(error.error) : null;
        String? daysError(RecurrenceField field) => switch (error) {
              TaskFormInvalidDays(field: final RecurrenceField invalid) when invalid == field => strings.errors.invalidDays,
              TaskFormInvalidRange() when field == RecurrenceField.min => strings.errors.invalidRange,
              _ => null,
            };
        final ThemeData theme = Theme.of(context);
        final TextStyle? captionStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
        final RecurrenceMode recurrenceMode = state.recurrenceMode;
        final List<TaskCategory> categories = state.categories;
        final DateTime? dueDate = state.dueDate;
        final DateTime? lastDoneAt = state.lastDoneAt;
        final DateTime today = widget.today();
        return Scaffold(
          appBar: AppTopBar(title: Text(cubit.isEditing ? formStrings.editTitle : formStrings.createTitle)),
          body: state.status == TaskFormStatus.loading
              ? const AppLoadingView()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                        children: <Widget>[
                          if (error is TaskFormGeneralError)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Text(
                                errorMessage(error.error, unexpected: commonStrings.common.unexpectedError),
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          AppTextField(
                            label: formStrings.title,
                            hint: formStrings.titleHint,
                            controller: _title,
                            focusNode: _titleFocus,
                            autofocus: !cubit.isEditing,
                            maxLength: TaskValidator.maxTitleLength,
                            maxLines: null,
                            textInputAction: TextInputAction.next,
                            errorText: titleError,
                            onChanged: _onTitleChanged,
                          ),
                          if (recurrenceMode == RecurrenceMode.none) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            AppPickerField(
                              label: formStrings.date,
                              placeholder: formStrings.noDate,
                              value: dueDate == null ? null : relativeDate(dueDate, today: today),
                              icon: AppIcons.calendar,
                              semanticHint: formStrings.change,
                              onTap: () => _pickDate(cubit, dueDate),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          AppChoiceSelector<Urgency>(
                            label: formStrings.urgency,
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
                                ? Text(formStrings.noCategories)
                                : AppFilterChips<String>(
                                    label: formStrings.categories,
                                    options: <AppChoice<String>>[
                                      for (final TaskCategory category in categories)
                                        AppChoice<String>(value: category.id, label: categoryName(category)),
                                    ],
                                    selected: state.categoryIds,
                                    onChanged: cubit.setCategories,
                                  ),
                          ),
                          AppChoiceSelector<RecurrenceMode>(
                            label: formStrings.recurrence,
                            padding: EdgeInsets.zero,
                            options: <AppChoice<RecurrenceMode>>[
                              AppChoice<RecurrenceMode>(value: RecurrenceMode.none, label: formStrings.recurrenceNone),
                              AppChoice<RecurrenceMode>(value: RecurrenceMode.fixed, label: formStrings.recurrenceFixed),
                              AppChoice<RecurrenceMode>(value: RecurrenceMode.range, label: formStrings.recurrenceRange),
                            ],
                            selected: recurrenceMode,
                            onChanged: cubit.setRecurrenceMode,
                          ),
                          if (recurrenceMode != RecurrenceMode.none) const SizedBox(height: AppSpacing.md),
                          if (recurrenceMode == RecurrenceMode.fixed)
                            AppTextField(
                              label: formStrings.everyDays,
                              controller: _every,
                              keyboardType: TextInputType.number,
                              helperText: formStrings.recurrenceHelp,
                              errorText: daysError(RecurrenceField.every),
                            ),
                          if (recurrenceMode == RecurrenceMode.range) ...<Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: AppSpacing.s300,
                              children: <Widget>[
                                Expanded(
                                  child: AppTextField(
                                    label: formStrings.minDays,
                                    controller: _min,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    errorText: daysError(RecurrenceField.min),
                                  ),
                                ),
                                Expanded(
                                  child: AppTextField(
                                    label: formStrings.maxDays,
                                    controller: _max,
                                    keyboardType: TextInputType.number,
                                    errorText: daysError(RecurrenceField.max),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(formStrings.recurrenceHelp, style: captionStyle),
                          ],
                          if (lastDoneAt != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              formStrings.lastDone(date: shortDate(CalendarDay.localDayOf(lastDoneAt))),
                              semanticsLabel: formStrings.lastDone(date: fullDate(context, CalendarDay.localDayOf(lastDoneAt))),
                              style: captionStyle,
                            ),
                          ],
                          if (cubit.isEditing) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: AppButton(
                                label: formStrings.delete,
                                icon: AppIcons.trash2,
                                variant: AppButtonVariant.dangerText,
                                size: AppButtonSize.medium,
                                onPressed: () => _confirmDelete(cubit),
                              ),
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
                          isLoading: state.status == TaskFormStatus.submitting,
                          onPressed: () => cubit.submit(
                            title: _title.text,
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
