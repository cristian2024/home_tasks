import 'dart:async';
import 'dart:developer' as developer;

import 'package:core_spaces/core_spaces.dart';
import 'package:core_sync/core_sync.dart';
import 'package:sync_engine/sync_engine.dart';

/// Anota en la lista de espacios el hogar de la base abierta: al abrirla
/// (completa la migración de la base de siempre) y cada vez que el usuario
/// crea un hogar, se une, cambia de época o sale.
class SpaceHouseholdTracker {
  SpaceHouseholdTracker({
    required DataSpaceDirectory directory,
    required String spaceId,
    required HouseholdService households,
  })  : _directory = directory,
        _spaceId = spaceId,
        _households = households;

  final DataSpaceDirectory _directory;
  final String _spaceId;
  final HouseholdService _households;
  StreamSubscription<Household?>? _subscription;
  Future<void> _pending = Future<void>.value();

  /// Anota el hogar actual y empieza a seguirlo.
  Future<void> start() async {
    await _record(await _households.current());
    _subscription = _households.watch().listen((Household? household) => _pending = _record(household));
  }

  /// Termina cuando se anotó el último cambio (para los tests).
  Future<void> get idle => _pending;

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  Future<void> _record(Household? household) async {
    final List<DataSpace> spaces = await _directory.spaces();
    final DataSpace? space = spaces.where((DataSpace space) => space.id == _spaceId).firstOrNull;
    if (space == null || space.householdId == household?.id) {
      return;
    }
    try {
      await _directory.save(space.copyWith(householdId: () => household?.id));
    } on DataSpaceException catch (error, stackTrace) {
      // Otro espacio ya es de ese hogar: la app lo evita al unirse.
      developer.log('No se pudo anotar el hogar del espacio', name: 'home_utility_app', error: error, stackTrace: stackTrace);
    }
  }
}
