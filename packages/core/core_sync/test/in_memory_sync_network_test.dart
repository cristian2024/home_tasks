import 'dart:typed_data';

import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:test/test.dart';

void main() {
  late InMemorySyncNetwork network;
  late InMemorySyncTransport a;
  late InMemorySyncTransport b;

  SyncAdvertisement ad(String deviceId) =>
      SyncAdvertisement(discoveryId: 'house', deviceId: deviceId, deviceName: deviceId);

  setUp(() async {
    network = InMemorySyncNetwork();
    a = network.transport();
    b = network.transport(id: 'otro');
    await a.start(ad('a'));
    await b.start(ad('b'));
  });

  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  test('partition impide verse y conectar, y cierra los canales abiertos', () async {
    final SyncEndpoint endpoint = (await a.watchEndpoints().first).single;
    final SyncChannel channel = await a.connect(endpoint);

    network.partition('b', 'a');

    expect(await a.watchEndpoints().first, isEmpty);
    expect(await channel.messages.toList(), isEmpty);
    await expectLater(a.connect(endpoint), throwsA(isA<SyncTransportException>()));
  });

  test('heal y healAll vuelven a unirlos', () async {
    network.partition('a', 'b');
    network.heal('a', 'b');
    expect(await a.watchEndpoints().first, hasLength(1));

    network.partition('a', 'b');
    network.healAll();
    expect((await b.watchEndpoints().first).single.transportId, 'memory');
  });

  test('un dispositivo con el mismo deviceId no se ve a sí mismo en otro transporte', () async {
    final InMemorySyncTransport twin = network.transport();
    await twin.start(ad('a'));

    expect((await a.watchEndpoints().first).map((SyncEndpoint e) => e.deviceId), <String>['b']);
    await twin.dispose();
  });

  test('connect falla si este transporte no ha empezado o la dirección no existe', () async {
    final SyncEndpoint endpoint = (await a.watchEndpoints().first).single;
    await a.stop();

    expect(await a.watchEndpoints().first, isEmpty);
    await expectLater(a.connect(endpoint), throwsA(isA<SyncTransportException>()));

    await a.start(ad('a'));
    await expectLater(
      a.connect(SyncEndpoint(transportId: 'memory', deviceId: 'x', deviceName: 'x', address: 'memory://99')),
      throwsA(isA<SyncTransportException>()),
    );
  });

  test('los mensajes se copian al enviarse', () async {
    final Future<SyncChannel> accepted = b.incoming.first;
    final SyncChannel channel = await a.connect((await a.watchEndpoints().first).single);
    final Uint8List message = Uint8List.fromList(<int>[1, 2]);

    await channel.send(message);
    message[0] = 9;

    expect(await (await accepted).messages.first, <int>[1, 2]);
  });
}
