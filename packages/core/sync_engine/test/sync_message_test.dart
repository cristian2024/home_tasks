import 'dart:convert';
import 'dart:typed_data';

import 'package:sync_engine/src/engine/sync_message.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

void main() {
  final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 255]);

  T roundTrip<T extends SyncMessage>(T message) => SyncMessage.decode(message.encode()) as T;

  test('cada mensaje se codifica y se lee igual', () {
    final HelloMessage hello =
        roundTrip(HelloMessage(protocol: 1, deviceId: 'a', deviceName: 'Teléfono', nonce: bytes));
    final RecordsMessage records = roundTrip(RecordsMessage(<SealedRecord>[
      SealedRecord(deviceId: 'a', seq: 3, ciphertext: bytes),
    ]));

    expect(<Object?>[hello.protocol, hello.deviceId, hello.deviceName, hello.nonce], <Object?>[1, 'a', 'Teléfono', bytes]);
    expect(roundTrip(ProofMessage(bytes)).mac, bytes);
    expect(roundTrip(VectorMessage(bytes)).ciphertext, bytes);
    expect(records.records.single.deviceId, 'a');
    expect(records.records.single.seq, 3);
    expect(records.records.single.ciphertext, bytes);
    expect(roundTrip(const DoneMessage()), isA<DoneMessage>());
  });

  test('decode rechaza lo que no sigue el protocolo', () {
    for (final String text in <String>[
      'no es json',
      '[1]',
      '{"t":"otro"}',
      '{"t":"proof"}',
      '{"t":"hello","v":1,"device":"a"}',
      '{"t":"records","items":[{"d":"a"}]}',
    ]) {
      expect(
        () => SyncMessage.decode(Uint8List.fromList(utf8.encode(text))),
        throwsA(isA<SyncProtocolException>()),
        reason: text,
      );
    }
  });
}
