import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:equatable/equatable.dart';

import 'space_switcher.dart';

class SpacesState extends Equatable {
  const SpacesState({required this.activeSpaceId, this.spaces = const <DataSpace>[], this.busy = false});

  final String activeSpaceId;
  final List<DataSpace> spaces;

  /// Hay una acción en curso.
  final bool busy;

  SpacesState copyWith({List<DataSpace>? spaces, bool? busy}) =>
      SpacesState(activeSpaceId: activeSpaceId, spaces: spaces ?? this.spaces, busy: busy ?? this.busy);

  @override
  List<Object?> get props => <Object?>[activeSpaceId, spaces, busy];
}

/// Los espacios de datos del dispositivo para su pantalla: cambiar de uno a
/// otro, crear, renombrar y borrar. Cambiar de espacio cambia el entorno de
/// la app, que cierra este cubit.
class SpacesCubit extends Cubit<SpacesState> {
  SpacesCubit(this._switcher) : super(SpacesState(activeSpaceId: _switcher.activeSpaceId)) {
    _subscription = _switcher.watchSpaces().listen((List<DataSpace> spaces) => emit(state.copyWith(spaces: spaces)));
  }

  final SpaceSwitcher _switcher;
  late final StreamSubscription<List<DataSpace>> _subscription;

  Future<bool> switchTo(String spaceId) => _run(() => _switcher.switchTo(spaceId));

  /// Crea un espacio local vacío llamado [name] y lo abre.
  Future<bool> create(String name) => _run(() => _switcher.createAndSwitch(name: name));

  Future<bool> rename(String spaceId, String name) => _run(() async {
        await _switcher.rename(spaceId, name);
        return true;
      });

  /// Borra un espacio que no es el abierto, con sus datos de este dispositivo.
  Future<bool> delete(String spaceId) => _run(() async {
        await _switcher.delete(spaceId);
        return true;
      });

  Future<bool> _run(Future<bool> Function() action) async {
    emit(state.copyWith(busy: true));
    bool done;
    try {
      done = await action();
    } on Object catch (error, stackTrace) {
      developer.log('Falló una acción de los espacios', name: 'home_utility_app', error: error, stackTrace: stackTrace);
      done = false;
    }
    if (!isClosed) {
      emit(state.copyWith(busy: false));
    }
    return done;
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
