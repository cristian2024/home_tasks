import 'dart:async';

import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

import '../engine/sync_engine.dart';
import '../engine/sync_session.dart';
import '../household/household_keys.dart';
import '../household/household_service.dart';
import '../sync_engine_exception.dart';
import 'sync_status.dart';

/// Decide cuándo sincronizar y publica el estado.
///
/// Con hogar, arranca los transportes con el anuncio de la época y sincroniza:
/// - con cada dispositivo que aparece (lo inicia el de `deviceId` menor, para
///   no abrir dos sesiones a la vez);
/// - tras un cambio local, con [debounce];
/// - con [syncNow] (el botón «Sincronizar ahora») y al volver a primer plano
///   ([resume]).
///
/// Acepta las sesiones que abren los demás.
class SyncController {
  SyncController({
    required SyncEngine engine,
    required HouseholdService households,
    required ChangeLog log,
    required SyncTransports transports,
    required SyncStateRepository state,
    required HlcClock hlcClock,
    Clock clock = const SystemClock(),
    this.debounce = const Duration(seconds: 2),
  })  : _engine = engine,
        _households = households,
        _log = log,
        _transports = transports,
        _state = state,
        _hlcClock = hlcClock,
        _clock = clock;

  final Duration debounce;
  final SyncEngine _engine;
  final HouseholdService _households;
  final ChangeLog _log;
  final SyncTransports _transports;
  final SyncStateRepository _state;
  final HlcClock _hlcClock;
  final Clock _clock;

  final StreamController<SyncStatus> _statusChanges = StreamController<SyncStatus>.broadcast(sync: true);
  final List<StreamSubscription<Object?>> _subscriptions = <StreamSubscription<Object?>>[];
  final List<StreamSubscription<Object?>> _transportSubscriptions = <StreamSubscription<Object?>>[];
  final Map<String, List<SyncEndpoint>> _endpoints = <String, List<SyncEndpoint>>{};
  final Map<String, VersionVector> _peerVectors = <String, VersionVector>{};
  final Set<String> _syncingWith = <String>{};
  Future<void> _householdTask = Future<void>.value();
  SyncStatus _status = SyncStatus();
  Household? _household;
  bool _started = false;
  bool _paused = false;
  int _sessions = 0;
  int _ownSeq = 0;
  Timer? _debounceTimer;

  SyncStatus get status => _status;

  /// Emite el estado al escuchar y cada vez que cambia.
  Stream<SyncStatus> watchStatus() {
    late final StreamController<SyncStatus> controller;
    StreamSubscription<SyncStatus>? subscription;
    controller = StreamController<SyncStatus>(
      onListen: () {
        controller.add(_status);
        subscription = _statusChanges.stream.listen(controller.add);
      },
      onCancel: () {
        unawaited(subscription?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  /// Empieza a seguir el hogar y los cambios locales. No hace nada si ya
  /// había empezado.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _ownSeq = (await _log.vector())[_hlcClock.deviceId];
    _subscriptions
      ..add(_households.watch().listen((Household? household) => _onHousehold(household)))
      ..add(_log.watchVector().listen(_onVector));
  }

  /// Detiene los transportes y deja de seguir el hogar y los cambios. Guarda
  /// el último HLC.
  Future<void> stop() async {
    _started = false;
    _debounceTimer?.cancel();
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    await _householdTask;
    await _stopTransports();
    await _state.saveLastHlc(_hlcClock.last);
    _update(_status.copyWith(phase: SyncPhase.disabled));
  }

  /// La app pasa a segundo plano: detiene los transportes.
  Future<void> pause() async {
    _paused = true;
    _debounceTimer?.cancel();
    await _householdTask;
    await _stopTransports();
    await _state.saveLastHlc(_hlcClock.last);
    _update(_status.copyWith(phase: SyncPhase.disabled));
  }

  /// La app vuelve a primer plano: arranca los transportes y sincroniza.
  Future<void> resume() async {
    _paused = false;
    await _onHousehold(_household);
    await syncNow();
  }

  /// Sincroniza con todos los dispositivos visibles, uno detrás de otro.
  Future<void> syncNow() async {
    await _householdTask;
    for (final SyncTransport transport in _transports.all) {
      for (final SyncEndpoint endpoint in List<SyncEndpoint>.of(_endpoints[transport.id] ?? const <SyncEndpoint>[])) {
        await _syncWith(transport, endpoint);
      }
    }
  }

  Future<void> _onHousehold(Household? household) {
    _household = household;
    return _householdTask = _householdTask.then((_) async {
      await _stopTransports();
      final HouseholdKeys? keys = household == null ? null : await _households.keys();
      if (!_started || _paused || keys == null) {
        _update(_status.copyWith(phase: SyncPhase.disabled));
        return;
      }
      final DeviceIdentity device = (await _state.readDevice())!;
      final SyncAdvertisement advertisement = SyncAdvertisement(
        discoveryId: await keys.discoveryId(),
        deviceId: device.deviceId,
        deviceName: device.name,
      );
      for (final SyncTransport transport in _transports.all) {
        _transportSubscriptions
          ..add(transport.incoming.listen((SyncChannel channel) => _accept(channel)))
          ..add(transport.watchEndpoints().listen((List<SyncEndpoint> endpoints) => _onEndpoints(transport, endpoints)));
        await transport.start(advertisement);
      }
      _update(_status.copyWith(phase: _sessions > 0 ? SyncPhase.syncing : SyncPhase.idle));
    });
  }

  Future<void> _stopTransports() async {
    for (final StreamSubscription<Object?> subscription in _transportSubscriptions) {
      unawaited(subscription.cancel());
    }
    _transportSubscriptions.clear();
    _endpoints.clear();
    for (final SyncTransport transport in _transports.all) {
      await transport.stop();
    }
    _update(_status.copyWith(visibleDevices: const <SyncEndpoint>[]));
  }

  void _onEndpoints(SyncTransport transport, List<SyncEndpoint> endpoints) {
    final Set<String> known = <String>{
      for (final SyncEndpoint endpoint in _endpoints[transport.id] ?? const <SyncEndpoint>[]) endpoint.deviceId,
    };
    _endpoints[transport.id] = endpoints;
    _update(_status.copyWith(visibleDevices: <SyncEndpoint>[for (final List<SyncEndpoint> list in _endpoints.values) ...list]));
    for (final SyncEndpoint endpoint in endpoints) {
      if (!known.contains(endpoint.deviceId) && _hlcClock.deviceId.compareTo(endpoint.deviceId) < 0) {
        unawaited(_syncWith(transport, endpoint));
      }
    }
  }

  void _onVector(VersionVector vector) {
    final int ownSeq = vector[_hlcClock.deviceId];
    if (ownSeq <= _ownSeq) {
      return;
    }
    _ownSeq = ownSeq;
    _updatePending();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(syncNow()));
  }

  Future<void> _syncWith(SyncTransport transport, SyncEndpoint endpoint) async {
    if (!_syncingWith.add(endpoint.deviceId)) {
      return;
    }
    try {
      await _session(() => _engine.syncWith(transport, endpoint));
    } finally {
      _syncingWith.remove(endpoint.deviceId);
    }
  }

  Future<void> _accept(SyncChannel channel) => _session(() => _engine.accept(channel));

  Future<void> _session(Future<SyncSessionResult> Function() run) async {
    _sessions++;
    _update(_status.copyWith(phase: SyncPhase.syncing));
    SyncErrorKind? error;
    try {
      final SyncSessionResult result = await run();
      _peerVectors[result.peer.deviceId] = result.remoteVector.merge(result.localVector);
      _update(_status.copyWith(lastSyncAt: _clock.nowUtc()));
    } on SyncTransportException {
      error = SyncErrorKind.transport;
    } on SyncAuthenticationException {
      error = SyncErrorKind.authentication;
    } on SyncProtocolException {
      error = SyncErrorKind.protocol;
    } on NotInHouseholdException {
      error = null;
    } on Object {
      error = SyncErrorKind.unknown;
    } finally {
      _sessions--;
    }
    _updatePending();
    _update(_status.copyWith(
      phase: _sessions > 0 ? SyncPhase.syncing : (_transportSubscriptions.isEmpty ? SyncPhase.disabled : SyncPhase.idle),
      lastError: () => error,
    ));
  }

  void _updatePending() {
    if (_peerVectors.isEmpty) {
      return;
    }
    final int delivered = _peerVectors.values
        .map((VersionVector vector) => vector[_hlcClock.deviceId])
        .reduce((int a, int b) => a > b ? a : b);
    _update(_status.copyWith(pendingChanges: _ownSeq > delivered ? _ownSeq - delivered : 0));
  }

  void _update(SyncStatus status) {
    if (status == _status) {
      return;
    }
    _status = status;
    _statusChanges.add(status);
  }
}
