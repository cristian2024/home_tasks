import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:core_sync/core_sync.dart';

import 'web_socket_sync_channel.dart';

/// [SyncTransport] de la red local:
/// - se anuncia por mDNS (bonsoir) con [serviceType]. El registro TXT lleva el
///   `discoveryId`, el id y el nombre del dispositivo, nunca el id del hogar;
/// - acepta conexiones WebSocket en un puerto libre (`ws://<ip>:<puerto>/sync`);
/// - el servidor rechaza a quien no presenta el mismo `discoveryId`. La
///   autenticación real la hace el motor con la clave del hogar.
///
/// Pensado para primer plano: la app lo detiene al pasar a segundo plano.
class LanTransport implements SyncTransport {
  /// [bindAddress] es la interfaz en la que escucha (todas, por defecto).
  LanTransport({
    this.serviceType = defaultServiceType,
    InternetAddress? bindAddress,
    this.connectTimeout = const Duration(seconds: 5),
  }) : _bindAddress = bindAddress ?? InternetAddress.anyIPv4;

  static const String defaultServiceType = '_hometasks._tcp';
  static const String _path = '/sync';
  static const String _discoveryHeader = 'x-sync-discovery';
  static const String _discoveryAttribute = 'd';
  static const String _deviceIdAttribute = 'id';
  static const String _deviceNameAttribute = 'n';

  /// Tipo de servicio mDNS que se anuncia y se busca.
  final String serviceType;

  /// Tiempo máximo para abrir un canal con [connect].
  final Duration connectTimeout;

  final InternetAddress _bindAddress;
  final StreamController<SyncChannel> _incoming = StreamController<SyncChannel>.broadcast();
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);

  /// Servicios resueltos del mismo tipo, por nombre.
  final Map<String, BonsoirService> _services = <String, BonsoirService>{};
  SyncAdvertisement? _advertisement;
  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoveryEvents;

  @override
  String get id => 'lan';

  @override
  Stream<SyncChannel> get incoming => _incoming.stream;

  @override
  Future<void> start(SyncAdvertisement advertisement) async {
    if (advertisement == _advertisement) {
      return;
    }
    _advertisement = advertisement;
    final HttpServer server = _server ??= await _serve();
    await _broadcast?.stop();
    final BonsoirBroadcast broadcast = _broadcast = BonsoirBroadcast(
      printLogs: false,
      service: BonsoirService(
        name: advertisement.deviceId,
        type: serviceType,
        port: server.port,
        attributes: <String, String>{
          _discoveryAttribute: advertisement.discoveryId,
          _deviceIdAttribute: advertisement.deviceId,
          _deviceNameAttribute: advertisement.deviceName,
        },
      ),
    );
    await broadcast.initialize();
    await broadcast.start();
    if (_discovery == null) {
      await _discover();
    }
    _changes.add(null);
  }

  @override
  Future<void> stop() async {
    _advertisement = null;
    await _broadcast?.stop();
    _broadcast = null;
    await _discoveryEvents?.cancel();
    _discoveryEvents = null;
    await _discovery?.stop();
    _discovery = null;
    // Deja de aceptar conexiones; los canales abiertos siguen.
    await _server?.close();
    _server = null;
    _services.clear();
    _changes.add(null);
  }

  /// Se detiene y deja de emitir canales entrantes.
  Future<void> dispose() async {
    await stop();
    await _incoming.close();
    await _changes.close();
  }

  @override
  Stream<List<SyncEndpoint>> watchEndpoints() {
    late final StreamController<List<SyncEndpoint>> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<List<SyncEndpoint>>(
      onListen: () {
        controller.add(_endpoints());
        subscription = _changes.stream.listen((_) => controller.add(_endpoints()));
      },
      // No devuelve el futuro de cancel(): `first` lo esperaría.
      onCancel: () {
        unawaited(subscription?.cancel());
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }

  @override
  Future<SyncChannel> connect(SyncEndpoint endpoint) async {
    final SyncAdvertisement? own = _advertisement;
    if (own == null) {
      throw const SyncTransportException('El transporte no ha empezado');
    }
    final HttpClient client = HttpClient();
    client.connectionTimeout = connectTimeout;
    try {
      // El canal es dueño del WebSocket y lo cierra.
      return WebSocketSyncChannel(await WebSocket.connect(
        endpoint.address,
        headers: <String, String>{_discoveryHeader: own.discoveryId},
        customClient: client,
      ).timeout(connectTimeout));
    } on Exception catch (error) {
      throw SyncTransportException('${endpoint.address} no responde: $error');
    } finally {
      // El WebSocket ya se separó del cliente; cerrarlo no lo corta.
      client.close();
    }
  }

  Future<HttpServer> _serve() async {
    final HttpServer server = await HttpServer.bind(_bindAddress, 0);
    server.listen(_onRequest);
    return server;
  }

  Future<void> _onRequest(HttpRequest request) async {
    final String? discoveryId = _advertisement?.discoveryId;
    if (request.uri.path != _path || !WebSocketTransformer.isUpgradeRequest(request)) {
      await _reject(request, HttpStatus.notFound);
    } else if (discoveryId == null || request.headers.value(_discoveryHeader) != discoveryId) {
      await _reject(request, HttpStatus.forbidden);
    } else {
      _incoming.add(WebSocketSyncChannel(await WebSocketTransformer.upgrade(request)));
    }
  }

  Future<void> _reject(HttpRequest request, int status) async {
    request.response.statusCode = status;
    await request.response.close();
  }

  Future<void> _discover() async {
    final BonsoirDiscovery discovery = _discovery = BonsoirDiscovery(type: serviceType, printLogs: false);
    await discovery.initialize();
    _discoveryEvents = discovery.eventStream?.listen((BonsoirDiscoveryEvent event) => _onDiscovery(discovery, event));
    await discovery.start();
  }

  void _onDiscovery(BonsoirDiscovery discovery, BonsoirDiscoveryEvent event) {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent(:final BonsoirService service):
        unawaited(Future<void>.sync(() => discovery.serviceResolver.resolveService(service)));
      case BonsoirDiscoveryServiceResolvedEvent(:final BonsoirService service) ||
            BonsoirDiscoveryServiceUpdatedEvent(:final BonsoirService service):
        _services[service.name] = service;
        _changes.add(null);
      case BonsoirDiscoveryServiceLostEvent(:final BonsoirService service):
        _services.remove(service.name);
        _changes.add(null);
      default:
        break;
    }
  }

  List<SyncEndpoint> _endpoints() {
    final SyncAdvertisement? own = _advertisement;
    if (own == null) {
      return const <SyncEndpoint>[];
    }
    return <SyncEndpoint>[
      for (final BonsoirService service in _services.values)
        if (_endpointOf(service) case final SyncEndpoint endpoint
            when service.attributes[_discoveryAttribute] == own.discoveryId && endpoint.deviceId != own.deviceId)
          endpoint,
    ];
  }

  SyncEndpoint? _endpointOf(BonsoirService service) {
    final String? deviceId = service.attributes[_deviceIdAttribute];
    final String? host = service.hostAddresses
            .where((String address) => InternetAddress.tryParse(address)?.type == InternetAddressType.IPv4)
            .firstOrNull ??
        service.hostAddress ??
        service.hostname;
    if (deviceId == null || deviceId.isEmpty || host == null) {
      return null;
    }
    return SyncEndpoint(
      transportId: id,
      deviceId: deviceId,
      deviceName: service.attributes[_deviceNameAttribute] ?? '',
      address: Uri(scheme: 'ws', host: host, port: service.port, path: _path).toString(),
    );
  }
}
