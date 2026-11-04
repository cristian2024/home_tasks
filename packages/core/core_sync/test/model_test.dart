import 'dart:convert';

import 'package:core_sync/core_sync.dart';
import 'package:test/test.dart';

void main() {
  Hlc hlc(int wallTime, [String deviceId = 'a', int counter = 0]) =>
      Hlc(wallTime: wallTime, counter: counter, deviceId: deviceId);

  ChangeRecord record({
    String deviceId = 'a',
    int seq = 1,
    Hlc? stamp,
    List<FieldChange>? changes,
    List<BlobRef> blobs = const <BlobRef>[],
  }) =>
      ChangeRecord(
        opId: 'op-1',
        deviceId: deviceId,
        seq: seq,
        collection: 'items',
        entityId: 'item-1',
        hlc: stamp ?? hlc(10, deviceId),
        changes: changes ?? <FieldChange>[ValueChange('name', 'Leche')],
        blobs: blobs,
      );

  Object? jsonRoundTrip(Object? json) => jsonDecode(jsonEncode(json));

  group('FieldChange', () {
    test('ValueChange admite valores JSON y rechaza el resto', () {
      expect(ValueChange('a', <String, Object?>{'n': 1.5, 'l': <Object?>[true, null, 'x']}).value, isA<Map<String, Object?>>());
      expect(() => ValueChange('a', DateTime.utc(2026)), throwsArgumentError);
      expect(() => ValueChange('a', <Object?>[DateTime.utc(2026)]), throwsArgumentError);
      expect(() => ValueChange('a', <String, Object?>{'d': DateTime.utc(2026)}), throwsArgumentError);
      expect(() => ValueChange('a', <int, Object?>{1: 'x'}), throwsArgumentError);
      expect(() => ValueChange('', 'x'), throwsArgumentError);
    });

    test('ElementChange rechaza un elemento vacío', () {
      expect(() => ElementChange('tags', '', present: true), throwsArgumentError);
    });

    test('toJson y fromJson son inversos', () {
      final List<FieldChange> changes = <FieldChange>[
        ValueChange('name', 'Leche'),
        ValueChange('deletedAt', null),
        ElementChange('categoryIds', 'dairy', present: false),
      ];

      for (final FieldChange change in changes) {
        expect(FieldChange.fromJson(jsonRoundTrip(change.toJson())), change);
      }
      expect(ValueChange('a', 1), isNot(ValueChange('a', 2)));
      expect(ElementChange('a', 'x', present: true), isNot(ElementChange('a', 'x', present: false)));
    });

    test('fromJson rechaza lo que no es un cambio', () {
      for (final Object? json in <Object?>[
        'x',
        <String, Object?>{'kind': 'value'},
        <String, Object?>{'kind': 'otro', 'field': 'a'},
        <String, Object?>{'kind': 'element', 'field': 'a', 'element': 'x'},
        <String, Object?>{'kind': 'element', 'field': 'a', 'element': '', 'present': true},
      ]) {
        expect(() => FieldChange.fromJson(json), throwsFormatException, reason: '$json');
      }
    });
  });

  group('BlobRef', () {
    test('exige un sha256 hexadecimal en minúscula', () {
      expect(BlobRef('0f' * 32).sha256, hasLength(64));
      expect(() => BlobRef('0F' * 32), throwsArgumentError);
      expect(() => BlobRef('0f'), throwsArgumentError);
      expect(BlobRef.fromJson(jsonRoundTrip(BlobRef('a' * 64).toJson())), BlobRef('a' * 64));
      expect(() => BlobRef.fromJson(<String, Object?>{'sha256': 'x'}), throwsFormatException);
    });
  });

  group('ChangeRecord', () {
    test('valida sus campos', () {
      expect(() => record(seq: 0), throwsArgumentError);
      expect(() => record(changes: <FieldChange>[]), throwsArgumentError);
      expect(() => record(stamp: hlc(10, 'b')), throwsArgumentError);
      expect(() => record(deviceId: ''), throwsA(anything));
      expect(
        () => ChangeRecord(opId: '', deviceId: 'a', seq: 1, collection: 'c', entityId: 'e', hlc: hlc(1), changes: <FieldChange>[ValueChange('f', 1)]),
        throwsArgumentError,
      );
    });

    test('sus listas no se pueden modificar', () {
      final List<FieldChange> changes = <FieldChange>[ValueChange('name', 'Leche')];
      final ChangeRecord value = record(changes: changes);

      changes.add(ValueChange('name', 'Pan'));

      expect(value.changes, hasLength(1));
      expect(() => value.changes.add(ValueChange('x', 1)), throwsUnsupportedError);
      expect(() => value.blobs.add(BlobRef('a' * 64)), throwsUnsupportedError);
    });

    test('toJson y fromJson son inversos', () {
      final ChangeRecord value = record(
        stamp: hlc(1761827400000, 'a', 7),
        changes: <FieldChange>[ValueChange('name', 'Leche'), ElementChange('categoryIds', 'dairy', present: true)],
        blobs: <BlobRef>[BlobRef('b' * 64)],
      );

      expect(ChangeRecord.fromJson(jsonRoundTrip(value.toJson())), value);
    });

    test('fromJson rechaza lo que no es un registro', () {
      final Map<String, Object?> json = record().toJson();

      expect(() => ChangeRecord.fromJson(<String, Object?>{...json, 'seq': '1'}), throwsFormatException);
      expect(() => ChangeRecord.fromJson(<String, Object?>{...json, 'seq': 0}), throwsFormatException);
      expect(() => ChangeRecord.fromJson(<String, Object?>{...json, 'hlc': 'x'}), throwsFormatException);
      expect(() => ChangeRecord.fromJson(<Object?>[]), throwsFormatException);
    });
  });

  group('VersionVector', () {
    final VersionVector vector = VersionVector(<String, int>{'a': 3, 'b': 1, 'c': 0});

    test('descarta los ceros y vale 0 para los ausentes', () {
      expect(vector.seqs, <String, int>{'a': 3, 'b': 1});
      expect(vector['c'], 0);
      expect(vector, VersionVector(<String, int>{'b': 1, 'a': 3}));
      expect(() => VersionVector(<String, int>{'a': -1}), throwsArgumentError);
      expect(() => VersionVector(<String, int>{'': 1}), throwsArgumentError);
    });

    test('includes y covers', () {
      expect(vector.includes(record(seq: 3)), isTrue);
      expect(vector.includes(record(seq: 4)), isFalse);
      expect(vector.covers(VersionVector(<String, int>{'a': 2, 'b': 1})), isTrue);
      expect(vector.covers(VersionVector(<String, int>{'c': 1})), isFalse);
      expect(vector.covers(VersionVector.empty), isTrue);
    });

    test('advance solo sube, merge toma el máximo y countAhead cuenta la diferencia', () {
      final VersionVector other = VersionVector(<String, int>{'a': 1, 'b': 4, 'd': 2});

      expect(vector.advance('a', 2), same(vector));
      expect(vector.advance('d', 2), VersionVector(<String, int>{'a': 3, 'b': 1, 'd': 2}));
      expect(vector.merge(other), VersionVector(<String, int>{'a': 3, 'b': 4, 'd': 2}));
      expect(vector.countAhead(other), 2);
      expect(other.countAhead(vector), 5);
      expect(vector.countAhead(vector), 0);
    });

    test('toJson y fromJson son inversos', () {
      expect(VersionVector.fromJson(jsonRoundTrip(vector.toJson())), vector);
      expect(() => VersionVector.fromJson(<String, Object?>{'a': 'x'}), throwsFormatException);
      expect(() => VersionVector.fromJson(<String, Object?>{'a': -2}), throwsFormatException);
    });
  });

  group('SyncMetadata', () {
    test('gana el cambio de mayor HLC por campo y el repetido no gana', () {
      final SyncMerge first = SyncMetadata.empty.apply(<FieldChange>[ValueChange('name', 'Leche')], hlc(10));
      final SyncMerge older = first.metadata.apply(<FieldChange>[ValueChange('name', 'Pan')], hlc(5, 'b'));
      final SyncMerge repeated = first.metadata.apply(<FieldChange>[ValueChange('name', 'Leche')], hlc(10));
      final SyncMerge newer = first.metadata.apply(
        <FieldChange>[ValueChange('name', 'Leche entera'), ValueChange('quantity', 2)],
        hlc(10, 'b'),
      );

      expect(first.changed, isTrue);
      expect(first.metadata.hlcOf('name'), hlc(10));
      expect(older.changed, isFalse);
      expect(older.metadata.hlcOf('name'), hlc(10));
      expect(repeated.changed, isFalse);
      expect(newer.winning, <FieldChange>[ValueChange('name', 'Leche entera'), ValueChange('quantity', 2)]);
      expect(newer.metadata.hlcOf('quantity'), hlc(10, 'b'));
      expect(SyncMetadata.empty.hlcOf('name'), isNull);
    });

    test('los conjuntos se fusionan por elemento', () {
      final SyncMetadata added = SyncMetadata.empty
          .apply(<FieldChange>[ElementChange('tags', 'x', present: true), ElementChange('tags', 'y', present: true)], hlc(10))
          .metadata;
      final SyncMerge removedLater = added.apply(<FieldChange>[ElementChange('tags', 'x', present: false)], hlc(20, 'b'));
      final SyncMerge addedBefore = removedLater.metadata.apply(<FieldChange>[ElementChange('tags', 'x', present: true)], hlc(15));

      expect(added.presentElements('tags'), <String>{'x', 'y'});
      expect(removedLater.metadata.presentElements('tags'), <String>{'y'});
      expect(addedBefore.changed, isFalse);
      expect(SyncMetadata.empty.presentElements('tags'), isEmpty);
      expect(added.elements['tags']!['x'], ElementStamp(hlc(10), present: true));
    });

    test('createdHlc es la menor marca aplicada, en cualquier orden', () {
      final SyncMetadata ab = SyncMetadata.empty
          .apply(<FieldChange>[ValueChange('a', 1)], hlc(20, 'b'))
          .metadata
          .apply(<FieldChange>[ValueChange('b', 1)], hlc(10, 'a'))
          .metadata;
      final SyncMetadata ba = SyncMetadata.empty
          .apply(<FieldChange>[ValueChange('b', 1)], hlc(10, 'a'))
          .metadata
          .apply(<FieldChange>[ValueChange('a', 1)], hlc(20, 'b'))
          .metadata;

      expect(ab, ba);
      expect(ab.createdHlc, hlc(10, 'a'));
      expect(ab.originDeviceId, 'a');
      expect(SyncMetadata.empty.originDeviceId, isNull);
    });

    test('merge aplica los cambios y la marca de un registro', () {
      final ChangeRecord value = record(stamp: hlc(30));

      expect(SyncMetadata.empty.merge(value), SyncMetadata.empty.apply(value.changes, value.hlc));
    });

    test('sus mapas no se pueden modificar', () {
      final SyncMetadata metadata = SyncMetadata.empty.apply(<FieldChange>[ElementChange('tags', 'x', present: true)], hlc(1)).metadata;

      expect(() => metadata.fields['x'] = hlc(1), throwsUnsupportedError);
      expect(() => metadata.elements['tags']!['y'] = ElementStamp(hlc(1), present: true), throwsUnsupportedError);
      expect(() => SyncMerge(metadata, <FieldChange>[]).winning.add(ValueChange('a', 1)), throwsUnsupportedError);
    });

    test('toJson y fromJson son inversos', () {
      final SyncMetadata metadata = SyncMetadata.empty
          .apply(<FieldChange>[ValueChange('name', 'Leche'), ElementChange('tags', 'x', present: false)], hlc(10, 'a', 2))
          .metadata;

      expect(SyncMetadata.fromJson(jsonRoundTrip(metadata.toJson())), metadata);
      expect(SyncMetadata.fromJson(jsonRoundTrip(SyncMetadata.empty.toJson())), SyncMetadata.empty);
      expect(() => SyncMetadata.fromJson(<String, Object?>{'fields': <String, Object?>{'a': 'x'}, 'elements': <String, Object?>{}}),
          throwsFormatException);
      expect(() => SyncMetadata.fromJson(<String, Object?>{'fields': 1}), throwsFormatException);
    });
  });

  group('Household y dispositivos', () {
    test('Household valida, sabe quién es el creador y pasa de época', () {
      final Household household = Household(id: 'h', epoch: 1, creatorDeviceId: 'a');

      expect(household.isCreator('a'), isTrue);
      expect(household.isCreator('b'), isFalse);
      expect(household.nextEpoch(), Household(id: 'h', epoch: 2, creatorDeviceId: 'a'));
      expect(() => Household(id: 'h', epoch: 0, creatorDeviceId: 'a'), throwsArgumentError);
      expect(() => Household(id: '', epoch: 1, creatorDeviceId: 'a'), throwsArgumentError);
      expect(() => Household(id: 'h', epoch: 1, creatorDeviceId: ''), throwsArgumentError);
    });

    test('DeviceIdentity y SyncPeer validan el id; SyncPeer guarda la fecha en UTC', () {
      final DateTime local = DateTime(2026, 10, 30, 9);

      expect(() => DeviceIdentity(deviceId: '', name: 'x'), throwsArgumentError);
      expect(() => SyncPeer(deviceId: '', name: 'x', lastSyncedAt: local), throwsArgumentError);
      expect(SyncPeer(deviceId: 'b', name: 'x', lastSyncedAt: local).lastSyncedAt, local.toUtc());
    });

    test('SyncAdvertisement y SyncEndpoint validan sus ids', () {
      expect(() => SyncAdvertisement(discoveryId: '', deviceId: 'a', deviceName: 'x'), throwsArgumentError);
      expect(() => SyncAdvertisement(discoveryId: 'd', deviceId: '', deviceName: 'x'), throwsArgumentError);
      expect(() => SyncEndpoint(transportId: '', deviceId: 'a', deviceName: 'x', address: 'y'), throwsArgumentError);
      expect(() => SyncEndpoint(transportId: 't', deviceId: '', deviceName: 'x', address: 'y'), throwsArgumentError);
      expect(SyncAdvertisement(discoveryId: 'd', deviceId: 'a', deviceName: 'x'),
          isNot(SyncAdvertisement(discoveryId: 'd', deviceId: 'a', deviceName: 'y')));
      expect(SyncEndpoint(transportId: 't', deviceId: 'a', deviceName: 'x', address: 'y'),
          SyncEndpoint(transportId: 't', deviceId: 'a', deviceName: 'x', address: 'y'));
    });
  });

  group('SyncConflict', () {
    SyncConflict conflict({List<String> entityIds = const <String>['i1'], String provisional = 'a', String? resolved}) =>
        SyncConflict(
          id: 'c',
          collection: 'items',
          kind: 'k',
          entityIds: entityIds,
          options: <ConflictOption>[ConflictOption('a'), ConflictOption('b', details: <String, String>{'name': 'Caja'})],
          provisionalOptionId: provisional,
          detectedAt: DateTime(2026, 10, 30, 9),
          resolvedOptionId: resolved,
        );

    test('valida entidades y opciones', () {
      expect(() => conflict(entityIds: <String>[]), throwsArgumentError);
      expect(() => conflict(provisional: 'x'), throwsArgumentError);
      expect(() => conflict(resolved: 'x'), throwsArgumentError);
      expect(() => ConflictOption(''), throwsArgumentError);
      expect(conflict().detectedAt.isUtc, isTrue);
    });

    test('resolve devuelve el conflicto resuelto con la opción elegida', () {
      expect(conflict().isResolved, isFalse);
      expect(conflict().resolve('b'), conflict(resolved: 'b'));
      expect(conflict().resolve('b').isResolved, isTrue);
      expect(() => conflict().resolve('x'), throwsArgumentError);
    });
  });

  test('las excepciones describen el error', () {
    expect(const SyncTransportException('sin red').toString(), 'SyncTransportException: sin red');
    expect(const SyncCipherException('alterado').message, 'alterado');
    expect(const SyncCipherException('alterado').toString(), 'SyncCipherException: alterado');
  });
}
