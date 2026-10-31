import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';
import 'package:sync_engine/sync_engine.dart';

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
  }) : status = status ?? SyncStatus();

  final SyncStatus status;
  final Household? household;
  final DeviceIdentity? device;

  /// Dispositivos del hogar con los que ya se sincronizó, por nombre.
  final List<SyncPeer> peers;
  final int openConflicts;

  /// Hay una acción del hogar en curso.
  final bool busy;

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
  }) =>
      SyncViewState(
        status: status ?? this.status,
        household: household == null ? this.household : household(),
        device: device ?? this.device,
        peers: peers ?? this.peers,
        openConflicts: openConflicts ?? this.openConflicts,
        busy: busy ?? this.busy,
      );

  @override
  List<Object?> get props => <Object?>[status, household, device, peers, openConflicts, busy];
}

/// Estado de la sincronización y acciones del hogar para la pantalla de
/// sincronización.
class SyncCubit extends Cubit<SyncViewState> {
  SyncCubit(this._services) : super(SyncViewState()) {
    _subscriptions
      ..add(_services.controller.watchStatus().listen(_onStatus))
      ..add(_services.households.watch().listen(_onHousehold))
      ..add(_services.inbox.watchOpen().listen(
            (List<SyncConflict> conflicts) => emit(state.copyWith(openConflicts: conflicts.length)),
          ));
    unawaited(_reloadDevices());
  }

  final SyncServices _services;
  final List<StreamSubscription<Object?>> _subscriptions = <StreamSubscription<Object?>>[];

  Future<void> syncNow() => _services.controller.syncNow();

  Future<SyncActionError?> createHousehold() => _run(() => _services.households.create());

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
