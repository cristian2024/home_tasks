import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:core_utils/core_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:sync_engine/sync_engine.dart';

import '../bootstrap.dart';
import '../navigation/app_router.dart';
import 'device_environment.dart';

/// Abre el espacio de datos [space]: un entorno nuevo de la app sobre su
/// base. Con [deviceName], el nombre de este dispositivo si la base es nueva.
typedef SpaceOpener = Future<AppEnvironment> Function(DataSpace space, {String? deviceName});

/// Qué avisar al mostrar el entorno de un cambio de espacio.
enum SpaceNotice {
  /// Se cambió a un espacio que ya existía.
  switched,

  /// Se creó y se abrió un espacio nuevo: sus plugins están por defecto.
  created,

  /// No se pudo abrir el espacio pedido: se volvió a abrir el anterior.
  failed,

  /// Se abrió el espacio, pero falló lo que había que hacer en él (crear el
  /// hogar o unirse).
  actionFailed,
}

class SpaceSession extends Equatable {
  const SpaceSession({required this.environment, this.location = AppRoutes.home, this.notice, this.switching = false});

  /// Entorno del espacio abierto. Mientras [switching] ya está liberado.
  final AppEnvironment environment;

  /// Dónde empieza la app con este entorno.
  final String location;
  final SpaceNotice? notice;

  /// Se está cambiando de espacio: no hay entorno que mostrar.
  final bool switching;

  @override
  List<Object?> get props => <Object?>[environment, location, notice, switching];
}

/// El espacio de datos abierto y los cambios entre espacios. Un cambio libera
/// el entorno actual (para la sincronización, libera los plugins y cierra la
/// base), abre el del otro espacio y solo entonces lo marca como activo. Si
/// no se puede abrir, vuelve a abrir el anterior.
///
/// Crear un hogar o unirse a uno en otro espacio es cambiar a él y, ya en el
/// entorno nuevo, crear o unirse.
class SpaceSwitcher extends Cubit<SpaceSession> {
  SpaceSwitcher({
    required DeviceEnvironment device,
    required AppEnvironment initial,
    required SpaceOpener open,
    required String Function(int number) newSpaceName,
    IdGenerator ids = const UuidV4Generator(),
    Clock clock = const SystemClock(),
  })  : _device = device,
        _open = open,
        _newSpaceName = newSpaceName,
        _ids = ids,
        _clock = clock,
        super(SpaceSession(environment: initial));

  final DeviceEnvironment _device;
  final SpaceOpener _open;
  final String Function(int number) _newSpaceName;
  final IdGenerator _ids;
  final Clock _clock;

  DataSpaceDirectory get _spaces => _device.spaces;

  /// Id del espacio abierto.
  String get activeSpaceId => state.environment.space!.id;

  Stream<List<DataSpace>> watchSpaces() => _spaces.watchSpaces();

  /// El espacio abierto, con su nombre actual.
  Future<DataSpace> activeSpace() async => (await _find(activeSpaceId))!;

  /// El espacio del hogar [householdId], o `null` si no hay ninguno.
  Future<String?> spaceOfHousehold(String householdId) async =>
      (await _spaces.spaces()).where((DataSpace space) => space.householdId == householdId).firstOrNull?.id;

  /// Abre el espacio [spaceId] y, ya en su entorno, ejecuta [then]. La app
  /// empieza en [location]. Devuelve `false` si no se pudo (sigue en el
  /// anterior) o si ya había un cambio en curso.
  Future<bool> switchTo(
    String spaceId, {
    String location = AppRoutes.home,
    SpaceNotice notice = SpaceNotice.switched,
    Future<void> Function(AppEnvironment environment)? then,
  }) async {
    final DataSpace? target = await _find(spaceId);
    if (state.switching || target == null) {
      return false;
    }
    final AppEnvironment previous = state.environment;
    final DataSpace previousSpace = previous.space!;
    final String? deviceName = (await previous.sync?.state.readDevice())?.name;
    emit(SpaceSession(environment: previous, switching: true));
    await previous.dispose();
    AppEnvironment? opened;
    try {
      opened = await _open(target, deviceName: deviceName);
      await _spaces.setActive(target.id);
      await then?.call(opened);
      emit(SpaceSession(environment: opened, location: location, notice: notice));
      return true;
    } on Object catch (error, stackTrace) {
      developer.log('No se pudo abrir el espacio ${target.id}', name: 'home_utility_app', error: error, stackTrace: stackTrace);
      if (opened != null && await _spaces.active() == target) {
        // Se abrió pero falló lo de después (p. ej. unirse): se queda en él.
        emit(SpaceSession(environment: opened, location: location, notice: SpaceNotice.actionFailed));
        return false;
      }
      await opened?.dispose();
      await _spaces.setActive(previousSpace.id);
      emit(SpaceSession(environment: await _open(previousSpace), notice: SpaceNotice.failed));
      return false;
    }
  }

  /// Crea un espacio local vacío (no lo abre).
  Future<DataSpace> createSpace({String? name}) async {
    final DataSpace space = DataSpace.create(
      id: _ids.newId(),
      name: name ?? _newSpaceName((await _spaces.spaces()).length + 1),
      createdAt: _clock.nowUtc(),
    );
    await _spaces.save(space);
    return space;
  }

  /// Crea un espacio, lo abre y avisa de que elija sus plugins.
  Future<bool> createAndSwitch({String? name}) async =>
      switchTo((await createSpace(name: name)).id, notice: SpaceNotice.created);

  Future<void> rename(String spaceId, String name) async {
    final DataSpace? space = await _find(spaceId);
    if (space != null) {
      await _spaces.save(space.copyWith(name: name));
    }
  }

  /// Borra el espacio [spaceId] y sus datos de este dispositivo. Primero lo
  /// quita de la lista y después borra su base (si el proceso muere entre
  /// medias, `deleteOrphanDatabases` termina al arrancar) y la clave de su
  /// hogar. Lanza `ActiveDataSpaceRemovalException` si es el abierto.
  Future<void> delete(String spaceId) async {
    final DataSpace? space = await _find(spaceId);
    if (space == null) {
      return;
    }
    await _spaces.remove(spaceId);
    await _device.spaceStorage.delete(space.databaseName);
    final String? householdId = space.householdId;
    final SecretStore? secrets = state.environment.locator.isRegistered<SecretStore>()
        ? state.environment.locator.get<SecretStore>()
        : null;
    if (householdId != null && secrets != null) {
      await secrets.delete(HouseholdService.secretKeyFor(householdId));
    }
  }

  /// Crea un hogar en un espacio nuevo y vacío, y muestra su código.
  Future<bool> createHouseholdInNewSpace() async {
    final DataSpace space = await createSpace();
    return switchTo(
      space.id,
      location: AppRoutes.syncInvitation,
      notice: SpaceNotice.created,
      then: (AppEnvironment environment) => _households(environment).create(),
    );
  }

  /// Se une al hogar de [invitation] en el espacio [spaceId] (el que ya es de
  /// ese hogar) o, sin él, en uno nuevo y vacío.
  Future<bool> joinInSpace(HouseholdInvitation invitation, {String? spaceId}) async {
    final String target = spaceId ?? (await createSpace()).id;
    return switchTo(
      target,
      location: AppRoutes.sync,
      notice: spaceId == null ? SpaceNotice.created : SpaceNotice.switched,
      then: (AppEnvironment environment) => _households(environment).join(invitation),
    );
  }

  HouseholdService _households(AppEnvironment environment) {
    final HouseholdService? households = environment.sync?.households;
    if (households == null) {
      throw StateError('El espacio no tiene sincronización');
    }
    return households;
  }

  Future<DataSpace?> _find(String spaceId) async =>
      (await _spaces.spaces()).where((DataSpace space) => space.id == spaceId).firstOrNull;
}
