import 'dart:typed_data';

import 'package:sync_engine/src/household/invitation_codec.dart';
import 'package:test/test.dart';

void main() {
  test('Base32 es reversible para cualquier longitud y no usa relleno', () {
    for (int length = 0; length <= 12; length++) {
      final Uint8List bytes = Uint8List.fromList(List<int>.generate(length, (int i) => 255 - i * 19));
      final String text = Base32.encode(bytes);

      expect(text, matches(RegExp(r'^[A-Z2-7]*$')), reason: '$length bytes');
      expect(Base32.decode(text), bytes, reason: '$length bytes');
    }
  });

  test('Base32 coincide con los vectores del RFC 4648', () {
    expect(Base32.encode('foobar'.codeUnits), 'MZXW6YTBOI');
    expect(Base32.decode('MZXW6YTBOI'), 'foobar'.codeUnits);
  });

  test('Base32 rechaza caracteres fuera del alfabeto', () {
    expect(() => Base32.decode('MZXW1'), throwsFormatException);
    expect(() => Base32.decode('mzxw'), throwsFormatException);
  });

  test('los campos se leen como se escribieron: UUID en 16 bytes y otros ids como texto', () {
    final InvitationWriter writer = InvitationWriter()
      ..byte(2)
      ..varint(0)
      ..varint(127)
      ..varint(128)
      ..varint(1 << 30)
      ..id('f47ac10b-58cc-4372-a567-0e02b2c3d479')
      ..id('F47AC10B-58CC-4372-A567-0E02B2C3D479')
      ..id('device-1')
      ..text('https://relay.example');
    final Uint8List bytes = writer.takeBytes();
    final InvitationReader reader = InvitationReader(bytes);

    expect(reader.byte(), 2);
    expect(reader.varint(), 0);
    expect(reader.varint(), 127);
    expect(reader.varint(), 128);
    expect(reader.varint(), 1 << 30);
    expect(reader.id(), 'f47ac10b-58cc-4372-a567-0e02b2c3d479');
    expect(reader.id(), 'F47AC10B-58CC-4372-A567-0E02B2C3D479');
    expect(reader.id(), 'device-1');
    expect(reader.text(), 'https://relay.example');
    expect(reader.isAtEnd, isTrue);
  });

  test('leer más allá del final o un varint sin fin lanza FormatException', () {
    expect(() => InvitationReader(Uint8List(0)).byte(), throwsFormatException);
    expect(() => InvitationReader(Uint8List(2)).bytes(3), throwsFormatException);
    expect(() => InvitationReader(Uint8List.fromList(List<int>.filled(8, 0xFF))).varint(), throwsFormatException);
  });
}
