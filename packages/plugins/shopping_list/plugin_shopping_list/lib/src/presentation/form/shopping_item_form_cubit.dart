import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shopping_list_domain/shopping_list_domain.dart';

import '../../domain/use_cases/item_use_cases.dart';
import '../../domain/use_cases/list_queries.dart';

enum ShoppingItemFormStatus { loading, editing, submitting, saved, deleted }

enum RecurrenceMode { none, fixed, range }

/// Campo de días de la recurrencia.
enum RecurrenceField { every, min, max }

sealed class ShoppingItemFormError extends Equatable {
  const ShoppingItemFormError();
}

final class ShoppingItemFormValidationError extends ShoppingItemFormError {
  const ShoppingItemFormValidationError(this.error);

  final ShoppingValidationException error;

  @override
  List<Object?> get props => <Object?>[error.field, error.reason];
}

/// Un número de días que no se puede leer o fuera de 1..365.
final class ShoppingItemFormInvalidDays extends ShoppingItemFormError {
  const ShoppingItemFormInvalidDays(this.field);

  final RecurrenceField field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// El mínimo es mayor que el máximo.
final class ShoppingItemFormInvalidRange extends ShoppingItemFormError {
  const ShoppingItemFormInvalidRange();

  @override
  List<Object?> get props => <Object?>[];
}

/// Error no ligado a un campo (item borrado, categoría que ya no existe…).
final class ShoppingItemFormGeneralError extends ShoppingItemFormError {
  const ShoppingItemFormGeneralError(this.error);

  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}

class ShoppingItemFormState extends Equatable {
  const ShoppingItemFormState({
    this.status = ShoppingItemFormStatus.loading,
    this.name = '',
    this.quantity = '',
    this.notes = '',
    this.urgency = Urgency.normal,
    this.categoryIds = const <String>{},
    this.recurrenceMode = RecurrenceMode.none,
    this.everyDays = '',
    this.minDays = '',
    this.maxDays = '',
    this.categories = const <ShoppingCategory>[],
    this.error,
    this.savedItemId,
  });

  final ShoppingItemFormStatus status;

  /// Valores iniciales de los campos de texto.
  final String name;
  final String quantity;
  final String notes;
  final String everyDays;
  final String minDays;
  final String maxDays;

  final Urgency urgency;
  final Set<String> categoryIds;
  final RecurrenceMode recurrenceMode;
  final List<ShoppingCategory> categories;
  final ShoppingItemFormError? error;
  final String? savedItemId;

  ShoppingItemFormState copyWith({
    ShoppingItemFormStatus? status,
    String? name,
    String? quantity,
    String? notes,
    Urgency? urgency,
    Set<String>? categoryIds,
    RecurrenceMode? recurrenceMode,
    String? everyDays,
    String? minDays,
    String? maxDays,
    List<ShoppingCategory>? categories,
    ShoppingItemFormError? Function()? error,
    String? savedItemId,
  }) =>
      ShoppingItemFormState(
        status: status ?? this.status,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        urgency: urgency ?? this.urgency,
        categoryIds: categoryIds ?? this.categoryIds,
        recurrenceMode: recurrenceMode ?? this.recurrenceMode,
        everyDays: everyDays ?? this.everyDays,
        minDays: minDays ?? this.minDays,
        maxDays: maxDays ?? this.maxDays,
        categories: categories ?? this.categories,
        error: error == null ? this.error : error(),
        savedItemId: savedItemId ?? this.savedItemId,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        name,
        quantity,
        notes,
        urgency,
        categoryIds,
        recurrenceMode,
        everyDays,
        minDays,
        maxDays,
        categories,
        error,
        savedItemId,
      ];
}

/// Crear o editar un item.
class ShoppingItemFormCubit extends Cubit<ShoppingItemFormState> {
  ShoppingItemFormCubit({
    required this.itemId,
    required GetShoppingItem getItem,
    required WatchShoppingCategories watchCategories,
    required CreateShoppingItem createItem,
    required UpdateShoppingItem updateItem,
    required DeleteShoppingItems deleteItems,
  })  : _getItem = getItem,
        _createItem = createItem,
        _updateItem = updateItem,
        _deleteItems = deleteItems,
        super(const ShoppingItemFormState()) {
    _categories = watchCategories().listen(
      (List<ShoppingCategory> categories) => emit(state.copyWith(categories: categories)),
    );
    unawaited(_load());
  }

  /// `null` al crear.
  final String? itemId;
  final GetShoppingItem _getItem;
  final CreateShoppingItem _createItem;
  final UpdateShoppingItem _updateItem;
  final DeleteShoppingItems _deleteItems;
  late final StreamSubscription<List<ShoppingCategory>> _categories;

  bool get isEditing => itemId != null;

  Future<void> _load() async {
    final String? itemId = this.itemId;
    if (itemId == null) {
      emit(state.copyWith(status: ShoppingItemFormStatus.editing));
      return;
    }
    try {
      final ShoppingItem item = await _getItem(itemId);
      final Recurrence? recurrence = item.recurrence;
      emit(state.copyWith(
        status: ShoppingItemFormStatus.editing,
        name: item.name,
        quantity: item.quantity,
        notes: item.notes,
        urgency: item.urgency,
        categoryIds: item.categoryIds.toSet(),
        recurrenceMode: recurrence == null
            ? RecurrenceMode.none
            : (recurrence.isFixed ? RecurrenceMode.fixed : RecurrenceMode.range),
        everyDays: recurrence == null ? '' : '${recurrence.minDays}',
        minDays: recurrence == null ? '' : '${recurrence.minDays}',
        maxDays: recurrence == null ? '' : '${recurrence.maxDays}',
      ));
    } on Object catch (error) {
      emit(state.copyWith(status: ShoppingItemFormStatus.editing, error: () => ShoppingItemFormGeneralError(error)));
    }
  }

  void setUrgency(Urgency urgency) => emit(state.copyWith(urgency: urgency));

  void setCategories(Set<String> categoryIds) => emit(state.copyWith(categoryIds: categoryIds));

  void setRecurrenceMode(RecurrenceMode mode) => emit(state.copyWith(recurrenceMode: mode, error: () => null));

  Future<void> submit({
    required String name,
    required String quantity,
    required String notes,
    String everyDays = '',
    String minDays = '',
    String maxDays = '',
  }) async {
    final Recurrence? recurrence;
    try {
      recurrence = _recurrence(everyDays, minDays, maxDays);
    } on ShoppingItemFormError catch (error) {
      emit(state.copyWith(error: () => error));
      return;
    }
    emit(state.copyWith(status: ShoppingItemFormStatus.submitting, error: () => null));
    try {
      final String? itemId = this.itemId;
      final List<String> categoryIds = <String>[
        for (final ShoppingCategory category in state.categories)
          if (state.categoryIds.contains(category.id)) category.id,
      ];
      final ShoppingItem item = itemId == null
          ? await _createItem(
              name: name,
              quantity: quantity,
              notes: notes,
              urgency: state.urgency,
              categoryIds: categoryIds,
              recurrence: recurrence,
            )
          : await _updateItem(
              itemId,
              name: name,
              quantity: quantity,
              notes: notes,
              urgency: state.urgency,
              categoryIds: categoryIds,
              recurrence: () => recurrence,
            );
      emit(state.copyWith(status: ShoppingItemFormStatus.saved, savedItemId: item.id));
    } on ShoppingValidationException catch (error) {
      emit(state.copyWith(
        status: ShoppingItemFormStatus.editing,
        error: () => ShoppingItemFormValidationError(error),
      ));
    } on Object catch (error) {
      emit(state.copyWith(status: ShoppingItemFormStatus.editing, error: () => ShoppingItemFormGeneralError(error)));
    }
  }

  Future<void> delete() async {
    final String? itemId = this.itemId;
    if (itemId == null) {
      return;
    }
    try {
      await _deleteItems(<String>[itemId]);
      emit(state.copyWith(status: ShoppingItemFormStatus.deleted));
    } on Object catch (error) {
      emit(state.copyWith(error: () => ShoppingItemFormGeneralError(error)));
    }
  }

  Recurrence? _recurrence(String every, String min, String max) {
    int days(String text, RecurrenceField field) {
      final int? value = int.tryParse(text.trim());
      if (value == null || value < 1 || value > Recurrence.maxAllowedDays) {
        throw ShoppingItemFormInvalidDays(field);
      }
      return value;
    }

    switch (state.recurrenceMode) {
      case RecurrenceMode.none:
        return null;
      case RecurrenceMode.fixed:
        return Recurrence.fixed(days(every, RecurrenceField.every));
      case RecurrenceMode.range:
        final int minDays = days(min, RecurrenceField.min);
        final int maxDays = days(max, RecurrenceField.max);
        if (minDays > maxDays) {
          throw const ShoppingItemFormInvalidRange();
        }
        return Recurrence.between(minDays, maxDays);
    }
  }

  @override
  Future<void> close() {
    unawaited(_categories.cancel());
    return super.close();
  }
}
