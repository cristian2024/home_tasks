import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:design_system/design_system.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/build_shopping_export.dart';
import '../../i18n/strings.g.dart';

ShoppingListTranslations$shoppingList$es get _t => shoppingListStrings.shoppingList;

String urgencyLabel(Urgency urgency) => switch (urgency) {
      Urgency.immediate => _t.urgency.immediate,
      Urgency.high => _t.urgency.high,
      Urgency.normal => _t.urgency.normal,
      Urgency.low => _t.urgency.low,
    };

String stateLabel(ShoppingItemState state) => switch (state) {
      ShoppingItemState.overdue => _t.states.overdue,
      ShoppingItemState.pending => _t.states.pending,
      ShoppingItemState.waiting => _t.states.waiting,
      ShoppingItemState.purchased => _t.states.purchased,
    };

/// Nombre visible: el que puso el usuario o, en una por defecto, su
/// traducción.
String categoryName(ShoppingCategory category) {
  final String? name = category.name;
  if (name != null) {
    return name;
  }
  return switch (DefaultShoppingCategory.values.asNameMap()[category.defaultKey]) {
    DefaultShoppingCategory.food => _t.defaultCategories.food,
    DefaultShoppingCategory.hygiene => _t.defaultCategories.hygiene,
    DefaultShoppingCategory.cleaning => _t.defaultCategories.cleaning,
    DefaultShoppingCategory.home => _t.defaultCategories.home,
    DefaultShoppingCategory.pharmacy => _t.defaultCategories.pharmacy,
    null => category.defaultKey ?? category.id,
  };
}

String recurrenceLabel(Recurrence recurrence) => recurrence.isFixed
    ? _t.recurrence.every(n: recurrence.minDays)
    : _t.recurrence.between(min: recurrence.minDays, max: recurrence.maxDays);

/// Tono del badge de urgencia; `null` si no merece badge.
AppBadgeTone? urgencyTone(Urgency urgency) => switch (urgency) {
      Urgency.immediate || Urgency.high => AppBadgeTone.critical,
      Urgency.normal || Urgency.low => null,
    };

String validationMessage(ShoppingValidationException error) => switch (error.reason) {
      ShoppingValidationReason.empty => commonStrings.common.requiredField,
      ShoppingValidationReason.tooLong => _t.errors.tooLong(
          max: switch (error.field) {
            ShoppingValidationField.name => ShoppingValidator.maxNameLength,
            ShoppingValidationField.notes => ShoppingValidator.maxNotesLength,
            ShoppingValidationField.quantity => ShoppingValidator.maxQuantityLength,
            ShoppingValidationField.categoryName => ShoppingValidator.maxCategoryNameLength,
          },
        ),
    };

/// Mensaje de un error de la lista; otro error usa el texto genérico.
String errorMessage(Object error) => switch (error) {
      ShoppingItemNotFoundException() => _t.errors.itemNotFound,
      ShoppingCategoryNotFoundException() => _t.errors.categoryNotFound,
      ShoppingCategoryNameTakenException(:final String name) => _t.errors.categoryNameTaken(name: name),
      ShoppingValidationException() => validationMessage(error),
      _ => commonStrings.common.unexpectedError,
    };

/// Textos del export en el idioma actual, con la fecha de [now] en el pie.
ShoppingExportTexts exportTexts(DateTime now) {
  final DateTime local = now.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return ShoppingExportTexts(
    title: _t.export.documentTitle,
    uncategorized: _t.list.uncategorized,
    urgency: urgencyLabel,
    categoryName: categoryName,
    footer: _t.export.footer(date: '${two(local.day)}/${two(local.month)}/${local.year}'),
  );
}

/// El día de [day] con el mes corto («12 nov»).
String shortDate(DateTime day) {
  final ShoppingListTranslations$shoppingList$dates$months$es months = _t.dates.months;
  final String month = <String>[
    months.m1,
    months.m2,
    months.m3,
    months.m4,
    months.m5,
    months.m6,
    months.m7,
    months.m8,
    months.m9,
    months.m10,
    months.m11,
    months.m12,
  ][day.month - 1];
  return '${day.day} $month';
}

/// «Hoy», «Ayer» o el día con el mes corto. [day] y [today] son días de
/// calendario (`CalendarDay`).
String relativeDate(DateTime day, {required DateTime today}) => switch (CalendarDay.relativeTo(day, today: today)) {
      RelativeDay.today => _t.dates.today,
      RelativeDay.yesterday => _t.dates.yesterday,
      RelativeDay.tomorrow || RelativeDay.other => shortDate(day),
    };

/// Cuándo se compró, para los lectores de pantalla («comprado hoy», «comprado
/// el 12 nov»).
String boughtOn(DateTime day, {required DateTime today}) => switch (CalendarDay.relativeTo(day, today: today)) {
      RelativeDay.today => _t.bought.today,
      RelativeDay.yesterday => _t.bought.yesterday,
      RelativeDay.tomorrow || RelativeDay.other => _t.bought.on(date: shortDate(day)),
    };
