import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';
import 'package:sync_engine/sync_engine.dart';

import '../spaces/space_switcher.dart';
import 'sync_services.dart';

/// Por qué falló una acción del hogar, para explicarlo.
enum SyncActionError { alreadyInHousehold, notCreator, generic }

class SyncViewState extends Equatable {
  SyncViewState({
    SyncStatus? status,
    this.household,
    this.device,
    this.peers = const <SyncPeer>[],
    this.openConflicts = 0,
    this.busy = false,
    this.spaceName,
  }) : status = status ?? SyncStatus();

  final SyncStatus status;
  final Household? household;
  final DeviceIdentity? device;

  /// Dispositivos del hogar con los que ya se sincronizó, por nombre.
  final List<SyncPeer> peers;
  final int openConflicts;

  /// Hay una acción del hogar en curso.
  final bool busy;

  /// Nombre del espacio de datos abierto, o `null` sin espacios.
  final String? spaceName;

  /// Si este dispositivo creó el hogar (solo él puede expulsar).
  bool get isCreator {
    final Household? household = this.household;
    final DeviceIdentity? device = this.device;
    return household != null && device != null && household.isCreator(device.deviceId);
  }

  SyncViewState copyWith({
    SyncStatus? status,
    Household? Function()? household,
    DeviceIdentity? device,
    List<SyncPeer>? peers,
    int? openConflicts,
    bool? busy,
    String? spaceName,
  }) =>
      SyncViewState(
        status: status ?? this.status,
        household: household == null ? this.household : household(),
        device: device ?? this.device,
        peers: peers ?? this.peers,
        openConflicts: openConflicts ?? this.openConflicts,
        busy: busy ?? this.busy,
        spaceName: spaceName ?? this.spaceName,
      );

  @override
  List<Object?> get props => <Object?>[status, household, device, peers, openConflicts, busy, spaceName];
}

/// Estado de la sincronización y acciones del hogar para la pantalla de
/// sincronización. Con [spaces], un hogar nuevo puede crearse en un espacio
/// de datos nuevo y vacío.
class SyncCubit extends Cubit<SyncViewState> {
  SyncCubit(this._services, {SpaceSwitcher? spaces}) : _spaces = spaces, super(SyncViewState()) {
    _subscriptions
      ..add(_services.controller.watchStatus().listen(_onStatus))
      ..add(_services.households.watch().listen(_onHousehold))
      ..add(_services.inbox.watchOpen().listen(
            (List<SyncConflict> conflicts) => emit(state.copyWith(openConflicts: conflicts.length)),
          ));
    unawaited(_reloadDevices());
    unawaited(_loadSpaceName());
  }

  final SyncServices _services;
  final SpaceSwitcher? _spaces;

  /// Si se puede elegir dónde van los datos de un hogar nuevo.
  bool get hasSpaces => _spaces != null;
  final List<StreamSubscription<Object?>> _subscriptions = <StreamSubscription<Object?>>[];

  Future<void> syncNow() => _services.controller.syncNow();

  /// Crea un hogar. Con [bringData] (o sin espacios), en este espacio, que
  /// comparte sus datos; si no, en un espacio nuevo y vacío, que la app abre.
  Future<SyncActionError?> createHousehold({bool bringData = true}) {
    final SpaceSwitcher? spaces = _spaces;
    if (bringData || spaces == null) {
      return _run(() => _services.households.create());
    }
    return _run(() async {
      if (!await spaces.createHouseholdInNewSpace()) {
        throw StateError('No se pudo crear el hogar en un espacio nuevo');
      }
      return null;
    });
  }

  Future<SyncActionError?> leave() => _run(_services.households.leave);

  /// Expulsa a [deviceId] y abre una época nueva: los demás deben volver a
  /// escanear el código.
  Future<SyncActionError?> expel(String deviceId) => _run(() => _services.households.expel(deviceId));

  Future<SyncActionError?> rename(String name) => _run(() => _services.households.renameDevice(name));

  void _onStatus(SyncStatus status) {
    final DateTime? previous = state.status.lastSyncAt;
    emit(state.copyWith(status: status));
    if (status.lastSyncAt != previous) {
      unawaited(_reloadDevices());
    }
  }

  void _onHousehold(Household? household) {
    emit(state.copyWith(household: () => household));
    unawaited(_reloadDevices());
  }

  Future<void> _loadSpaceName() async {
    final String? name = (await _spaces?.activeSpace())?.name;
    if (name != null && !isClosed) {
      emit(state.copyWith(spaceName: name));
    }
  }

  Future<void> _reloadDevices() async {
    final DeviceIdentity? device = await _services.state.readDevice();
    final List<SyncPeer> peers = (await _services.state.peers())
      ..sort((SyncPeer a, SyncPeer b) => a.name.compareTo(b.name));
    if (!isClosed) {
      emit(state.copyWith(device: device, peers: peers));
    }
  }

  Future<SyncActionError?> _run(Future<Object?> Function() action) async {
    emit(state.copyWith(busy: true));
    SyncActionError? error;
    try {
      await action();
    } on AlreadyInHouseholdException {
      error = SyncActionError.alreadyInHousehold;
    } on NotHouseholdCreatorException {
      error = SyncActionError.notCreator;
    } on Object {
      error = SyncActionError.generic;
    }
    await _reloadDevices();
    if (!isClosed) {
      emit(state.copyWith(busy: false));
    }
    return error;
  }

  @override
  Future<void> close() {
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    return super.close();
  }
}
