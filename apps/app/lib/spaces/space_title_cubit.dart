import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_spaces/core_spaces.dart';

import 'space_defaults.dart';
import 'space_switcher.dart';

/// Nombre del espacio abierto para el título del inicio, al día si se
/// renombra. `null` en el espacio inicial (el de la base de siempre) o sin
/// espacios: el inicio muestra entonces el título de la app.
class SpaceTitleCubit extends Cubit<String?> {
  SpaceTitleCubit(SpaceSwitcher? switcher) : super(null) {
    if (switcher != null) {
      final String activeId = switcher.activeSpaceId;
      _subscription = switcher.watchSpaces().listen((List<DataSpace> spaces) {
        final DataSpace? active = spaces.where((DataSpace space) => space.id == activeId).firstOrNull;
        emit(active == null ? null : titleFor(active));
      });
    }
  }

  StreamSubscription<List<DataSpace>>? _subscription;

  /// Título de [space]: su nombre, salvo en el espacio inicial.
  static String? titleFor(DataSpace space) =>
      space.databaseName == SpaceDefaults.legacyDatabaseName ? null : space.name;

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
