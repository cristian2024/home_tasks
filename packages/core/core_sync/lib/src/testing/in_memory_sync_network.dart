import 'dart:async';
import 'dart:typed_data';

import '../contracts/sync_transport.dart';
import '../sync_exception.dart';
import 'watch.dart';

/// Red en memoria que une varios [InMemorySyncTransport]. Permite cortar la
/// comunicación entre dos dispositivos ([partition]) para simular que no se
/// ven.
class InMemorySyncNetwork {
  final List<InMemorySyncTransport> _transports = <InMemorySyncTransport>[];
  final List<_MemoryChannel> _channels = <_MemoryChannel>[];
  final Set<String> _partitions = <String>{};
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);

  /// Transporte nuevo en esta red.
  InMemorySyncTransport transport({String id = 'memory'}) {
    final InMemorySyncTransport transport = InMemorySyncTransport._(this, id, 'memory://${_transports.length + 1}');
    _transports.add(transport);
    return transport;
  }

  /// Deja de verse y de poder conectar [deviceA] con [deviceB]. Cierra los
  /// canales abiertos entre ellos.
  void partition(String deviceA, String deviceB) {
    _partitions.add(_pairKey(deviceA, deviceB));
    for (final _MemoryChannel channel in List<_MemoryChannel>.of(_channels)) {
      if (_pairKey(channel.localDeviceId, channel.remoteDeviceId) == _pairKey(deviceA, deviceB)) {
        unawaited(channel.close());
      }
    }
    _changes.add(null);
  }

  /// Vuelven a verse [deviceA] y [deviceB].
  void heal(String deviceA, String deviceB) {
    _partitions.remove(_pairKey(deviceA, deviceB));
    _changes.add(null);
  }

  /// Quita todos los cortes.
  void healAll() {
    _partitions.clear();
    _changes.add(null);
  }

  bool _reachable(String deviceA, String deviceB) => !_partitions.contains(_pairKey(deviceA, deviceB));

  List<SyncEndpoint> _endpointsFor(InMemorySyncTransport viewer) {
    final SyncAdvertisement? own = viewer._advertisement;
    if (own == null) {
      return const <SyncEndpoint>[];
    }
    return <SyncEndpoint>[
      for (final InMemorySyncTransport other in _transports)
        if (other._advertisement case final SyncAdvertisement ad
            when other != viewer &&
                ad.discoveryId == own.discoveryId &&
                ad.deviceId != own.deviceId &&
                _reachable(own.deviceId, ad.deviceId))
          other._endpoint(ad),
    ];
  }

  static String _pairKey(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
}

/// [SyncTransport] sobre un [InMemorySyncNetwork]. Cumple
/// `syncTransportContract`.
class InMemorySyncTransport implements SyncTransport {
  InMemorySyncTransport._(this._network, this.id, this._address);

  final InMemorySyncNetwork _network;
  final String _address;
  final StreamController<SyncChannel> _incoming = StreamController<SyncChannel>.broadcast();
  SyncAdvertisement? _advertisement;

  @override
  final String id;

  @override
  Stream<SyncChannel> get incoming => _incoming.stream;

  @override
  Future<void> start(SyncAdvertisement advertisement) async {
    _advertisement = advertisement;
    _network._changes.add(null);
  }

  @override
  Future<void> stop() async {
    _advertisement = null;
    _network._changes.add(null);
  }

  /// Se detiene y deja de emitir canales entrantes.
  Future<void> dispose() async {
    await stop();
    await _incoming.close();
  }

  @override
  Stream<List<SyncEndpoint>> watchEndpoints() => watchValue(_network._changes.stream, () => _network._endpointsFor(this));

  @override
  Future<SyncChannel> connect(SyncEndpoint endpoint) async {
    final SyncAdvertisement? own = _advertisement;
    if (own == null) {
      throw const SyncTransportException('El transporte no ha empezado');
    }
    final InMemorySyncTransport? target = _network._transports
        .where((InMemorySyncTransport other) => other._address == endpoint.address)
        .firstOrNull;
    final SyncAdvertisement? remote = target?._advertisement;
    if (target == null || remote == null || !_network._reachable(own.deviceId, remote.deviceId)) {
      throw SyncTransportException('${endpoint.address} no responde');
    }
    final _MemoryChannel local = _MemoryChannel(_network, own.deviceId, remote.deviceId);
    final _MemoryChannel other = _MemoryChannel(_network, remote.deviceId, own.deviceId);
    local._peer = other;
    other._peer = local;
    _network._channels.addAll(<_MemoryChannel>[local, other]);
    target._incoming.add(other);
    return local;
  }

  SyncEndpoint _endpoint(SyncAdvertisement ad) =>
      SyncEndpoint(transportId: id, deviceId: ad.deviceId, deviceName: ad.deviceName, address: _address);
}

class _MemoryChannel implements SyncChannel {
  _MemoryChannel(this._network, this.localDeviceId, this.remoteDeviceId);

  final InMemorySyncNetwork _network;
  final String localDeviceId;
  final String remoteDeviceId;
  final StreamController<Uint8List> _inbox = StreamController<Uint8List>();
  late final _MemoryChannel _peer;
  bool _closed = false;

  @override
  Stream<Uint8List> get messages => _inbox.stream;

  @override
  Future<void> send(Uint8List message) async {
    if (_closed) {
      throw const SyncTransportException('Canal cerrado');
    }
    _peer._inbox.add(Uint8List.fromList(message));
  }

  @override
  Future<void> close() async {
    _closeSide();
    _peer._closeSide();
  }

  void _closeSide() {
    if (_closed) {
      return;
    }
    _closed = true;
    _network._channels.remove(this);
    // No se espera: el futuro solo se completa cuando alguien escucha.
    unawaited(_inbox.close());
  }
}
