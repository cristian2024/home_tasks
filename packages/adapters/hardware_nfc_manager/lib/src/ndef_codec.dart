import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

/// Codificación y decodificación de los registros NDEF que usa la app.
/// Funciones puras, sin acceso al hardware.
abstract final class NdefCodec {
  static final Uint8List _textType = Uint8List.fromList(<int>[0x54]); // 'T'
  static final Uint8List _uriType = Uint8List.fromList(<int>[0x55]); // 'U'

  // Prefijos del registro URI (NFC Forum URI RTD, tabla 3).
  static const List<String> _uriPrefixes = <String>[
    '', 'http://www.', 'https://www.', 'http://', 'https://', 'tel:', 'mailto:',
    'ftp://anonymous:anonymous@', 'ftp://ftp.', 'ftps://', 'sftp://', 'smb://',
    'nfs://', 'ftp://', 'dav://', 'news:', 'telnet://', 'imap:', 'rtsp://',
    'urn:', 'pop:', 'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://',
    'btgoep://', 'tcpobex://', 'irdaobex://', 'file://', 'urn:epc:id:',
    'urn:epc:tag:', 'urn:epc:pat:', 'urn:epc:raw:', 'urn:epc:', 'urn:nfc:',
  ];

  /// Registro NDEF Text (UTF-8) con [value] y el código de idioma [language].
  static NdefRecord encodeText(String value, {String language = 'es'}) {
    final Uint8List languageBytes = ascii.encode(language);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: _textType,
      identifier: Uint8List(0),
      payload: Uint8List.fromList(<int>[languageBytes.length, ...languageBytes, ...utf8.encode(value)]),
    );
  }

  /// Texto de un registro NDEF Text o URI; `null` para cualquier otro tipo o
  /// si el contenido está mal formado.
  static String? decode(NdefRecord record) {
    if (record.typeNameFormat != TypeNameFormat.wellKnown || record.payload.isEmpty) {
      return null;
    }
    try {
      if (_sameBytes(record.type, _textType)) {
        return _decodeText(record.payload);
      }
      if (_sameBytes(record.type, _uriType)) {
        return _decodeUri(record.payload);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  /// Valor que identifica un tag: el primer registro Text/URI legible de
  /// [message] o, si no hay ninguno, el UID del tag en hexadecimal mayúscula.
  static String? resolveRawValue({NdefMessage? message, Uint8List? uid}) {
    for (final NdefRecord record in message?.records ?? const <NdefRecord>[]) {
      final String? value = decode(record);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return <String>[for (final int byte in uid) byte.toRadixString(16).padLeft(2, '0')].join().toUpperCase();
  }

  static String _decodeText(Uint8List payload) {
    final int status = payload[0];
    final bool isUtf16 = status & 0x80 != 0;
    final int languageLength = status & 0x3F;
    if (1 + languageLength > payload.length) {
      throw const FormatException('Longitud de idioma inválida');
    }
    final Uint8List text = payload.sublist(1 + languageLength);
    return isUtf16 ? _decodeUtf16(text) : utf8.decode(text);
  }

  static String _decodeUtf16(Uint8List bytes) {
    bool littleEndian = false;
    int offset = 0;
    if (bytes.length >= 2) {
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        littleEndian = true;
        offset = 2;
      } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        offset = 2;
      }
    }
    if ((bytes.length - offset).isOdd) {
      throw const FormatException('UTF-16 con longitud impar');
    }
    final List<int> units = <int>[
      for (int i = offset; i < bytes.length; i += 2)
        littleEndian ? bytes[i] | bytes[i + 1] << 8 : bytes[i] << 8 | bytes[i + 1],
    ];
    return String.fromCharCodes(units);
  }

  static String _decodeUri(Uint8List payload) {
    final int code = payload[0];
    final String prefix = code < _uriPrefixes.length ? _uriPrefixes[code] : '';
    return prefix + utf8.decode(payload.sublist(1));
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
