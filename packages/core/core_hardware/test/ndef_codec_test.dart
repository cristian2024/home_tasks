import 'dart:convert';
import 'dart:typed_data';

import 'package:core_hardware/src/nfc/ndef_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/ndef_record.dart';

NdefRecord wellKnown(String type, List<int> payload) => NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList(ascii.encode(type)),
      identifier: Uint8List(0),
      payload: Uint8List.fromList(payload),
    );

void main() {
  group('Text', () {
    test('encodeText y decode son inversos (UTF-8)', () {
      final record = NdefCodec.encodeText('NFC-BED ñ');

      expect(record.payload.first, 2); // UTF-8, idioma de 2 bytes
      expect(NdefCodec.decode(record), 'NFC-BED ñ');
    });

    test('decodifica UTF-16 big endian y con BOM little endian', () {
      expect(NdefCodec.decode(wellKnown('T', [0x82, ...ascii.encode('es'), 0x00, 0x41, 0x00, 0x42])), 'AB');
      expect(NdefCodec.decode(wellKnown('T', [0x82, ...ascii.encode('es'), 0xFF, 0xFE, 0x41, 0x00])), 'A');
    });

    test('devuelve null si el payload está mal formado', () {
      expect(NdefCodec.decode(wellKnown('T', [0x3F, 0x65])), isNull);
      expect(NdefCodec.decode(wellKnown('T', [0x02, ...ascii.encode('es'), 0xC3])), isNull);
    });
  });

  group('URI', () {
    test('expande el prefijo abreviado', () {
      expect(NdefCodec.decode(wellKnown('U', [0x04, ...utf8.encode('example.com')])), 'https://example.com');
      expect(NdefCodec.decode(wellKnown('U', [0x00, ...utf8.encode('urn:x')])), 'urn:x');
    });
  });

  test('ignora tipos no soportados', () {
    final media = NdefRecord(
      typeNameFormat: TypeNameFormat.media,
      type: Uint8List.fromList(ascii.encode('text/plain')),
      identifier: Uint8List(0),
      payload: Uint8List.fromList(utf8.encode('x')),
    );
    expect(NdefCodec.decode(media), isNull);
  });

  group('resolveRawValue', () {
    final uid = Uint8List.fromList([0x04, 0xa2, 0x0f]);

    test('prefiere el primer registro de texto legible', () {
      final message = NdefMessage(records: [
        wellKnown('Sp', [0x00]),
        NdefCodec.encodeText('NFC-BED'),
        NdefCodec.encodeText('OTRO'),
      ]);

      expect(NdefCodec.resolveRawValue(message: message, uid: uid), 'NFC-BED');
    });

    test('usa el UID en hexadecimal si no hay registros legibles', () {
      expect(NdefCodec.resolveRawValue(uid: uid), '04A20F');
      expect(
        NdefCodec.resolveRawValue(message: NdefMessage(records: [NdefCodec.encodeText('')]), uid: uid),
        '04A20F',
      );
    });

    test('devuelve null sin contenido ni UID', () {
      expect(NdefCodec.resolveRawValue(), isNull);
    });
  });
}
