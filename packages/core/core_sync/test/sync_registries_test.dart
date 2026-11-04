import 'package:core_di/core_di.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:test/test.dart';

class _Participant implements SyncParticipant {
  _Participant(this.collections);

  @override
  final Set<String> collections;

  @override
  Future<List<SyncConflict>> applyRemote(List<ChangeRecord> records) async => <SyncConflict>[];

  @override
  Future<void> resolveConflict(SyncConflict conflict, String optionId) async {}
}

void main() {
  late ServiceLocator services;

  setUp(() => services = ServiceLocator());

  tearDown(() => services.reset());

  group('SyncParticipants', () {
    test('of crea el registro una vez y lo devuelve', () {
      final SyncParticipants participants = SyncParticipants.of(services);

      expect(SyncParticipants.of(services), same(participants));
      expect(participants.all, isEmpty);
    });

    test('add los guarda y forCollection encuentra el de cada colección', () {
      final SyncParticipants participants = SyncParticipants.of(services);
      final _Participant items = _Participant(<String>{'items', 'identifiers'});
      final _Participant shopping = _Participant(<String>{'shopping'});

      participants
        ..add(items)
        ..add(shopping);

      expect(participants.all, <SyncParticipant>[items, shopping]);
      expect(participants.forCollection('identifiers'), same(items));
      expect(participants.forCollection('shopping'), same(shopping));
      expect(participants.forCollection('otra'), isNull);
      expect(() => participants.all.add(items), throwsUnsupportedError);
    });

    test('rechaza un participante con una colección que ya tiene otro', () {
      final SyncParticipants participants = SyncParticipants.of(services)..add(_Participant(<String>{'items'}));

      expect(() => participants.add(_Participant(<String>{'otra', 'items'})), throwsArgumentError);
      expect(participants.all, hasLength(1));
    });
  });

  group('SyncTransports', () {
    test('of crea el registro una vez; add rechaza ids repetidos', () async {
      final InMemorySyncNetwork network = InMemorySyncNetwork();
      final SyncTransports transports = SyncTransports.of(services);
      final InMemorySyncTransport lan = network.transport(id: 'lan');

      transports.add(lan);

      expect(SyncTransports.of(services), same(transports));
      expect(transports.all, <SyncTransport>[lan]);
      expect(() => transports.add(network.transport(id: 'lan')), throwsArgumentError);
      expect(() => transports.all.add(lan), throwsUnsupportedError);
    });
  });
}
