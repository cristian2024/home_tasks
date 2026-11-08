import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../tokens/app_icons.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';
import 'app_choice_selector.dart';
import 'app_filter_chips.dart';
import 'app_icon_button.dart';
import 'app_text_field.dart';

/// Un acceso rápido de [showAppDateSheet] (p. ej. «Mañana»).
class AppDateOption {
  const AppDateOption({required this.label, required this.date});

  final String label;

  /// Solo cuenta el día: la hora se ignora.
  final DateTime date;
}

/// Lo que devuelve [showAppDateSheet] al guardar o quitar. Con [date] en `null`
/// se quitó la fecha.
class AppDateChoice {
  const AppDateChoice(this.date);

  final DateTime? date;
}

/// Textos de [showAppDateSheet], que pone quien la abre.
class AppDateSheetTexts {
  const AppDateSheetTexts({
    required this.title,
    required this.fieldLabel,
    required this.invalidDate,
    required this.save,
    required this.calendar,
    this.fieldHint,
    this.remove,
  });

  final String title;

  /// Etiqueta del campo para escribir la fecha (p. ej. «Escribir la fecha»).
  final String fieldLabel;
  final String? fieldHint;

  /// Error de una fecha que no existe o no se entiende.
  final String invalidDate;
  final String save;

  /// Etiqueta del botón que abre el calendario del sistema.
  final String calendar;

  /// Botón para quitar la fecha. Sin él, no se ofrece.
  final String? remove;
}

/// Hoja para elegir un día: accesos rápidos ([options]), un campo para
/// escribirlo en el formato del idioma (`12/11/2026` en español) y el
/// calendario del sistema. Devuelve la elección al guardar o quitar, o `null`
/// si se cierra sin cambiar nada.
Future<AppDateChoice?> showAppDateSheet(
  BuildContext context, {
  required AppDateSheetTexts texts,
  required List<AppDateOption> options,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
}) =>
    showAppBottomSheet<AppDateChoice>(
      context,
      builder: (BuildContext context) => _DateSheet(
        texts: texts,
        options: options,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDate: initialDate,
      ),
    );

class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.texts,
    required this.options,
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
  });

  final AppDateSheetTexts texts;
  final List<AppDateOption> options;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  final TextEditingController _text = TextEditingController();
  DateTime? _date;
  String? _error;

  AppDateSheetTexts get _texts => widget.texts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final DateTime? initialDate = widget.initialDate;
    if (_date == null && initialDate != null) {
      _show(DateUtils.dateOnly(initialDate));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _show(DateTime date) {
    _date = date;
    _text.text = MaterialLocalizations.of(context).formatCompactDate(date);
    _error = null;
  }

  void _choose(DateTime date, {String? label}) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    setState(() => _show(date));
    final String fullDate = localizations.formatFullDate(date);
    SemanticsService.sendAnnouncement(
      View.of(context),
      label == null ? fullDate : '$label, $fullDate',
      Directionality.of(context),
    );
  }

  Future<void> _openCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? widget.options.firstOrNull?.date ?? widget.firstDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null && mounted) {
      _choose(DateUtils.dateOnly(picked));
    }
  }

  void _save() {
    final String text = _text.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop(const AppDateChoice(null));
      return;
    }
    final DateTime? parsed = MaterialLocalizations.of(context).parseCompactDate(text);
    if (parsed == null) {
      setState(() => _error = _texts.invalidDate);
      return;
    }
    Navigator.of(context).pop(AppDateChoice(DateUtils.dateOnly(parsed)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? date = _date;
    final String? remove = _texts.remove;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.s300,
      children: <Widget>[
        Semantics(header: true, child: Text(_texts.title, style: theme.textTheme.titleLarge)),
        AppFilterChips<DateTime>(
          label: _texts.title,
          showLabel: false,
          options: <AppChoice<DateTime>>[
            for (final AppDateOption option in widget.options)
              AppChoice<DateTime>(value: DateUtils.dateOnly(option.date), label: option.label),
          ],
          selected: <DateTime>{?date},
          onChanged: (Set<DateTime> selected) {
            final DateTime? added = selected.where((DateTime value) => value != date).firstOrNull;
            if (added != null) {
              _choose(
                added,
                label: widget.options.firstWhere((AppDateOption option) => DateUtils.isSameDay(option.date, added)).label,
              );
            }
          },
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Expanded(
              child: AppTextField(
                label: _texts.fieldLabel,
                hint: _texts.fieldHint,
                controller: _text,
                errorText: _error,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.done,
                onChanged: (String _) => setState(() {
                  _date = null;
                  _error = null;
                }),
                onSubmitted: (String _) => _save(),
              ),
            ),
            _CalendarButton(label: _texts.fieldLabel, tooltip: _texts.calendar, onPressed: _openCalendar),
          ],
        ),
        AppButton(label: _texts.save, expand: true, onPressed: _save),
        if (remove != null)
          AppButton(
            label: remove,
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.of(context).pop(const AppDateChoice(null)),
          ),
      ],
    );
  }
}

/// Botón del calendario, alineado con el campo aunque cambie el tamaño del
/// texto: deja encima un hueco del alto de la etiqueta del campo.
class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.label, required this.tooltip, required this.onPressed});

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Solo aporta el alto: con un ancho fijo no aparta el botón del campo.
        ExcludeSemantics(
          child: SizedBox(
            width: AppSizes.minTouchTarget,
            child: Visibility.maintain(
              visible: false,
              child: Text(label, style: Theme.of(context).textTheme.labelLarge, maxLines: 1, softWrap: false),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s150),
        AppIconButton(icon: AppIcons.calendar, tooltip: tooltip, onPressed: onPressed),
      ],
    );
  }
}
