import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:test/test.dart';

import '../contracts/sync_transport.dart';
import '../sync_exception.dart';

/// Crea dos transportes que se pueden ver (la misma red) para un test. La
/// batería los detiene al terminar; [dispose], si se da, libera lo demás.
typedef SyncTransportPairFactory = FutureOr<(SyncTransport, SyncTransport)> Function();

/// Tests de contrato de [SyncTransport] y [SyncChannel]. Toda implementación
/// debe pasarlos. [timeout] limita cada espera (descubrimiento, mensajes).
void syncTransportContract(
  String implementation, {
  required SyncTransportPairFactory create,
  FutureOr<void> Function()? dispose,
  Duration timeout = const Duration(seconds: 10),
}) {
  group('SyncTransport ($implementation)', () {
    late SyncTransport a;
    late SyncTransport b;
    SyncAdvertisement ad(String deviceId, {String discoveryId = 'house-key-1'}) =>
        SyncAdvertisement(discoveryId: discoveryId, deviceId: deviceId, deviceName: 'Dispositivo $deviceId');

    Future<SyncEndpoint> endpointOf(SyncTransport viewer, String deviceId) => viewer
        .watchEndpoints()
        .expand((List<SyncEndpoint> endpoints) => endpoints)
        .firstWhere((SyncEndpoint endpoint) => endpoint.deviceId == deviceId)
        .timeout(timeout);

    Future<(SyncChannel, SyncChannel)> connectAToB() async {
      final Future<SyncChannel> accepted = b.incoming.first.timeout(timeout);
      final SyncChannel opened = await a.connect(await endpointOf(a, 'device-b'));
      return (opened, await accepted);
    }

    Uint8List bytes(List<int> values) => Uint8List.fromList(values);

    setUp(() async => (a, b) = await create());

    tearDown(() async {
      await a.stop();
      await b.stop();
      await dispose?.call();
    });

    test('dos dispositivos con el mismo discoveryId se ven, sin verse a sí mismos', () async {
      await a.start(ad('device-a'));
      await b.start(ad('device-b'));

      final SyncEndpoint seenByA = await endpointOf(a, 'device-b');
      final SyncEndpoint seenByB = await endpointOf(b, 'device-a');

      expect(seenByA.transportId, a.id);
      expect(seenByA.deviceName, 'Dispositivo device-b');
      expect(seenByB.deviceName, 'Dispositivo device-a');
      expect(await a.watchEndpoints().first, isNot(contains(predicate((SyncEndpoint e) => e.deviceId == 'device-a'))));
    });

    test('con distinto discoveryId no se ven', () async {
      await a.start(ad('device-a'));
      await b.start(ad('device-b', discoveryId: 'house-key-2'));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(await a.watchEndpoints().first, isEmpty);
      expect(await b.watchEndpoints().first, isEmpty);
    });

    test('al detenerse deja de verse', () async {
      await a.start(ad('device-a'));
      await b.start(ad('device-b'));
      await endpointOf(a, 'device-b');
      final StreamQueue<List<SyncEndpoint>> seen = StreamQueue<List<SyncEndpoint>>(a.watchEndpoints());

      await b.stop();

      await expectLater(seen, emitsThrough(isEmpty));
      await seen.cancel();
    });

    test('connect abre un canal que el otro recibe y los mensajes van y vuelven en orden', () async {
      await a.start(ad('device-a'));
      await b.start(ad('device-b'));
      final (SyncChannel opened, SyncChannel accepted) = await connectAToB();
      final StreamQueue<Uint8List> atA = StreamQueue<Uint8List>(opened.messages);
      final StreamQueue<Uint8List> atB = StreamQueue<Uint8List>(accepted.messages);
      final Uint8List large = Uint8List.fromList(List<int>.generate(256 * 1024, (int i) => i % 251));

      await opened.send(bytes(<int>[1, 2, 3]));
      await opened.send(large);
      await opened.send(Uint8List(0));
      await accepted.send(bytes(<int>[9]));

      expect(await atB.next.timeout(timeout), <int>[1, 2, 3]);
      expect(await atB.next.timeout(timeout), large);
      expect(await atB.next.timeout(timeout), isEmpty);
      expect(await atA.next.timeout(timeout), <int>[9]);
      await opened.close();
      await atA.cancel();
      await atB.cancel();
    });

    test('al cerrar un lado, el otro deja de recibir y enviar falla', () async {
      await a.start(ad('device-a'));
      await b.start(ad('device-b'));
      final (SyncChannel opened, SyncChannel accepted) = await connectAToB();

      await accepted.close();
      await accepted.close();

      await expectLater(opened.messages.toList().timeout(timeout), completion(isEmpty));
      await expectLater(opened.send(bytes(<int>[1])), throwsA(isA<SyncTransportException>()));
      await expectLater(accepted.send(bytes(<int>[1])), throwsA(isA<SyncTransportException>()));
    });

    test('connect falla si el otro ya se detuvo', () async {
      await a.start(ad('device-a'));
      await b.start(ad('device-b'));
      final SyncEndpoint endpoint = await endpointOf(a, 'device-b');

      await b.stop();

      await expectLater(a.connect(endpoint).timeout(timeout), throwsA(isA<SyncTransportException>()));
    });
  });
}
