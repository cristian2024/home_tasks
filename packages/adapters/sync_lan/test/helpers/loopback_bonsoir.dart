import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

/// Plataforma de bonsoir en memoria: los anuncios se ven en las búsquedas del
/// mismo tipo, resueltos a `127.0.0.1` si no traen dirección. Sustituye a mDNS en los tests.
class LoopbackBonsoir extends BonsoirPlatformInterface {
  final List<_Broadcast> _broadcasts = <_Broadcast>[];
  final List<_Discovery> _discoveries = <_Discovery>[];

  /// Servicios anunciados ahora mismo.
  List<BonsoirService> get announced =>
      <BonsoirService>[for (final _Broadcast broadcast in _broadcasts) broadcast.service];

  /// Anuncia [service] como si lo hiciera otro dispositivo.
  void announce(BonsoirService service) => _Broadcast(this, service)._announce();

  @override
  BonsoirAction<BonsoirBroadcastEvent> createBroadcastAction(BonsoirService service, {bool printLogs = false}) =>
      _Broadcast(this, service);

  @override
  BonsoirAction<BonsoirDiscoveryEvent> createDiscoveryAction(String type, {bool printLogs = false}) =>
      _Discovery(this, type);
}

abstract class _Action<T extends BonsoirEvent> extends BonsoirAction<T> {
  final StreamController<T> _events = StreamController<T>.broadcast();
  bool _ready = false;
  bool _stopped = false;

  @override
  Stream<T>? get eventStream => _ready ? _events.stream : null;

  @override
  Future<void> initialize() async => _ready = true;

  @override
  bool get isReady => _ready && !_stopped;

  @override
  bool get isStopped => _stopped;
}

class _Broadcast extends _Action<BonsoirBroadcastEvent> {
  _Broadcast(this._platform, this.service);

  final LoopbackBonsoir _platform;
  final BonsoirService service;

  @override
  Future<void> start() async => _announce();

  void _announce() {
    _platform._broadcasts.add(this);
    for (final _Discovery discovery in _platform._discoveries) {
      discovery._found(this);
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _platform._broadcasts.remove(this);
    for (final _Discovery discovery in _platform._discoveries) {
      discovery._lost(this);
    }
  }
}

class _Discovery extends _Action<BonsoirDiscoveryEvent> with ServiceResolver {
  _Discovery(this._platform, this.type);

  final LoopbackBonsoir _platform;
  final String type;

  @override
  Future<void> start() async {
    _platform._discoveries.add(this);
    _events.add(const BonsoirDiscoveryStartedEvent());
    for (final _Broadcast broadcast in List<_Broadcast>.of(_platform._broadcasts)) {
      _found(broadcast);
    }
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _platform._discoveries.remove(this);
    _events.add(const BonsoirDiscoveryStoppedEvent());
  }

  void _found(_Broadcast broadcast) {
    if (broadcast.service.type == type) {
      _events.add(BonsoirDiscoveryServiceFoundEvent(service: broadcast.service));
    }
  }

  void _lost(_Broadcast broadcast) {
    if (broadcast.service.type == type) {
      _events.add(BonsoirDiscoveryServiceLostEvent(service: broadcast.service));
    }
  }

  @override
  void resolveService(BonsoirService service) {
    if (_platform._broadcasts.any((_Broadcast broadcast) => broadcast.service.name == service.name)) {
      final bool hasAddress = service.hostAddresses.isNotEmpty || service.hostname != null;
      _events.add(BonsoirDiscoveryServiceResolvedEvent(
        service: hasAddress ? service : service.copyWith(hostAddresses: <String>['127.0.0.1']),
      ));
    }
  }

  @override
  bool supportsMdnsHostname() => false;
}
