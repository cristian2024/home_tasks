import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/use_cases/add_item_event.dart';

enum AddEventStatus { editing, submitting, saved }

class AddEventState extends Equatable {
  const AddEventState({this.status = AddEventStatus.editing, this.error});

  final AddEventStatus status;
  final Object? error;

  @override
  List<Object?> get props => [status, error];
}

/// Añade una nota al historial de un objeto.
class AddEventCubit extends Cubit<AddEventState> {
  AddEventCubit(this.itemId, {required AddItemEvent addItemEvent})
      : _addItemEvent = addItemEvent,
        super(const AddEventState());

  final String itemId;
  final AddItemEvent _addItemEvent;

  Future<void> submit({required String title, required String description}) async {
    if (state.status != AddEventStatus.editing) {
      return;
    }
    emit(const AddEventState(status: AddEventStatus.submitting));
    try {
      await _addItemEvent(itemId, title: title, description: description);
      emit(const AddEventState(status: AddEventStatus.saved));
    } catch (error) {
      emit(AddEventState(error: error));
    }
  }
}
