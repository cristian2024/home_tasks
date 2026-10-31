import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_lan/sync_lan.dart';

import 'helpers/loopback_bonsoir.dart';

const Duration _timeout = Duration(seconds: 10);

LanTransport _transport() => LanTransport(bindAddress: InternetAddress.loopbackIPv4);

SyncAdvertisement _ad(String deviceId, {String discoveryId = 'house-key-1'}) =>
    SyncAdvertisement(discoveryId: discoveryId, deviceId: deviceId, deviceName: 'Dispositivo $deviceId');

Future<SyncEndpoint> _endpointOf(SyncTransport viewer, String deviceId) => viewer
    .watchEndpoints()
    .expand((List<SyncEndpoint> endpoints) => endpoints)
    .firstWhere((SyncEndpoint endpoint) => endpoint.deviceId == deviceId)
    .timeout(_timeout);

void main() {
  late LoopbackBonsoir bonsoir;

  setUp(() => BonsoirPlatformInterface.instance = bonsoir = LoopbackBonsoir());

  syncTransportContract('LanTransport', create: () => (_transport(), _transport()));

  group('LanTransport', () {
    final List<LanTransport> created = <LanTransport>[];

    LanTransport transport() {
      final LanTransport transport = _transport();
      created.add(transport);
      return transport;
    }

    tearDown(() async {
      for (final LanTransport transport in created) {
        await transport.dispose();
      }
      created.clear();
    });

    test('anuncia el discoveryId, el dispositivo y su nombre, nunca el hogar', () async {
      final LanTransport a = transport();
      final LanTransport b = transport();
      await a.start(_ad('device-a'));
      await b.start(_ad('device-b'));

      final SyncEndpoint endpoint = await _endpointOf(a, 'device-b');

      expect(a.id, 'lan');
      expect(bonsoir.announced.map((BonsoirService service) => service.attributes), contains(equals(<String, String>{
        'd': 'house-key-1',
        'id': 'device-b',
        'n': 'Dispositivo device-b',
      })));
      expect(endpoint.address, matches(RegExp(r'^ws://127\.0\.0\.1:\d+/sync$')));
    });

    test('al cambiar el anuncio deja de verse con el discoveryId anterior', () async {
      final LanTransport a = transport();
      final LanTransport b = transport();
      await a.start(_ad('device-a'));
      await b.start(_ad('device-b'));
      await _endpointOf(a, 'device-b');
      final StreamQueue<List<SyncEndpoint>> seen = StreamQueue<List<SyncEndpoint>>(a.watchEndpoints());

      await b.start(_ad('device-b', discoveryId: 'house-key-2'));
      await b.start(_ad('device-b', discoveryId: 'house-key-2'));

      await expectLater(seen, emitsThrough(isEmpty));
      await seen.cancel();
    });

    test('ignora servicios sin dispositivo y sin anuncio no ve a nadie', () async {
      final LanTransport a = transport();
      bonsoir.announce(BonsoirService(
        name: 'other',
        type: LanTransport.defaultServiceType,
        port: 1,
        attributes: const <String, String>{'d': 'house-key-1'},
      ));

      expect(await a.watchEndpoints().first, isEmpty);
      await a.start(_ad('device-a'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(await a.watchEndpoints().first, isEmpty);
    });

    test('prefiere una IPv4; si no hay, usa la IPv6 o el nombre del host', () async {
      final LanTransport a = transport();
      BonsoirService other(String deviceId, {List<String> hostAddresses = const <String>[], String? hostname}) =>
          BonsoirService(
            name: deviceId,
            type: LanTransport.defaultServiceType,
            port: 4040,
            hostAddresses: hostAddresses,
            hostname: hostname,
            attributes: <String, String>{'d': 'house-key-1', 'id': deviceId, 'n': deviceId},
          );
      bonsoir
        ..announce(other('dual', hostAddresses: <String>['fe80::1', '192.168.1.20']))
        ..announce(other('ipv6', hostAddresses: <String>['fe80::2']))
        ..announce(other('named', hostname: 'phone.local'));
      await a.start(_ad('device-a'));

      expect((await _endpointOf(a, 'dual')).address, 'ws://192.168.1.20:4040/sync');
      expect((await _endpointOf(a, 'ipv6')).address, 'ws://[fe80::2]:4040/sync');
      expect((await _endpointOf(a, 'named')).address, 'ws://phone.local:4040/sync');
    });

    test('el servidor rechaza a quien no presenta el mismo discoveryId', () async {
      final LanTransport a = transport();
      final LanTransport b = transport();
      final LanTransport stranger = transport();
      await a.start(_ad('device-a'));
      await b.start(_ad('device-b'));
      await stranger.start(_ad('device-c', discoveryId: 'house-key-2'));
      final SyncEndpoint endpoint = await _endpointOf(a, 'device-b');

      await expectLater(stranger.connect(endpoint), throwsA(isA<SyncTransportException>()));
    });

    test('el servidor responde 404 a lo que no es el WebSocket de la sincronización', () async {
      final LanTransport a = transport();
      final LanTransport b = transport();
      await a.start(_ad('device-a'));
      await b.start(_ad('device-b'));
      final Uri address = Uri.parse((await _endpointOf(a, 'device-b')).address).replace(scheme: 'http');
      final HttpClient client = HttpClient();
      addTearDown(client.close);

      final HttpClientResponse response = await (await client.getUrl(address)).close();

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('connect falla si el transporte no ha empezado', () async {
      final LanTransport a = transport();

      await expectLater(
        a.connect(SyncEndpoint(transportId: 'lan', deviceId: 'b', deviceName: 'B', address: 'ws://127.0.0.1:1/sync')),
        throwsA(isA<SyncTransportException>()),
      );
    });

    test('stop sin haber empezado no falla', () async {
      final LanTransport a = transport();

      await a.stop();

      expect(await a.watchEndpoints().first, isEmpty);
    });

    test('ignora los mensajes de texto', () async {
      final LanTransport a = transport();
      final LanTransport b = transport();
      await a.start(_ad('device-a'));
      await b.start(_ad('device-b'));
      final SyncEndpoint endpoint = await _endpointOf(a, 'device-b');
      final Future<SyncChannel> accepted = b.incoming.first.timeout(_timeout);
      final WebSocket raw = await WebSocket.connect(endpoint.address, headers: <String, String>{
        'x-sync-discovery': 'house-key-1',
      });
      final StreamQueue<Uint8List> received = StreamQueue<Uint8List>((await accepted).messages);

      raw
        ..add('texto')
        ..add(<int>[7]);

      expect(await received.next.timeout(_timeout), <int>[7]);
      await raw.close();
      await received.cancel();
    });
  });

  test('LanSyncTransport añade un LanTransport a SyncTransports y lo libera con reset', () async {
    final ServiceLocator services = ServiceLocator();

    await const LanSyncTransport().register(services);

    final LanTransport transport = services.get<LanTransport>();
    expect(SyncTransports.of(services).all, <SyncTransport>[transport]);
    expect(transport.serviceType, LanTransport.defaultServiceType);
    await services.reset();
  });
}
