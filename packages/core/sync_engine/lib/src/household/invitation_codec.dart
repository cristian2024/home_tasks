import 'dart:convert';
import 'dart:typed_data';

/// Base32 (RFC 4648) sin relleno: solo `A-Z` y `2-7`, así el QR usa el modo
/// alfanumérico y el texto se puede dictar o pegar sin confundir mayúsculas.
abstract final class Base32 {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String encode(List<int> bytes) {
    final StringBuffer out = StringBuffer();
    int buffer = 0;
    int bits = 0;
    for (final int byte in bytes) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(_alphabet[(buffer >> bits) & 31]);
      }
    }
    if (bits > 0) {
      out.write(_alphabet[(buffer << (5 - bits)) & 31]);
    }
    return out.toString();
  }

  /// Lanza [FormatException] con un carácter fuera del alfabeto.
  static Uint8List decode(String text) {
    final BytesBuilder out = BytesBuilder(copy: false);
    int buffer = 0;
    int bits = 0;
    for (final int char in text.codeUnits) {
      final int value = _alphabet.indexOf(String.fromCharCode(char));
      if (value < 0) {
        throw FormatException('Carácter fuera de base32', text);
      }
      buffer = ((buffer << 5) | value) & 0xFFF;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.addByte((buffer >> bits) & 0xFF);
      }
    }
    return out.takeBytes();
  }
}

/// Escribe los campos de una invitación en binario.
class InvitationWriter {
  final BytesBuilder _bytes = BytesBuilder(copy: false);

  void byte(int value) => _bytes.addByte(value);

  /// Entero sin signo en varint (LEB128).
  void varint(int value) {
    int rest = value;
    while (rest >= 0x80) {
      _bytes.addByte((rest & 0x7F) | 0x80);
      rest >>= 7;
    }
    _bytes.addByte(rest);
  }

  void bytes(List<int> value) => _bytes.add(value);

  /// Un UUID canónico (minúsculas) ocupa 16 bytes tras un `0`; cualquier otro
  /// texto, su longitud en UTF-8 y sus bytes.
  void id(String value) {
    final Uint8List? uuid = _uuidBytes(value);
    if (uuid != null) {
      byte(0);
      bytes(uuid);
      return;
    }
    final List<int> text = utf8.encode(value);
    varint(text.length);
    bytes(text);
  }

  /// Texto con su longitud delante.
  void text(String value) {
    final List<int> text = utf8.encode(value);
    varint(text.length);
    bytes(text);
  }

  Uint8List takeBytes() => _bytes.takeBytes();
}

/// Lee lo que escribe [InvitationWriter]. Lanza [FormatException] si los datos
/// se acaban antes de tiempo.
class InvitationReader {
  InvitationReader(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  bool get isAtEnd => _offset >= _bytes.length;

  int byte() {
    if (isAtEnd) {
      throw const FormatException('Invitación incompleta');
    }
    return _bytes[_offset++];
  }

  int varint() {
    int value = 0;
    int shift = 0;
    while (true) {
      final int part = byte();
      value |= (part & 0x7F) << shift;
      if (part < 0x80) {
        return value;
      }
      shift += 7;
      if (shift > 35) {
        throw const FormatException('Número demasiado largo en la invitación');
      }
    }
  }

  Uint8List bytes(int length) {
    if (_offset + length > _bytes.length) {
      throw const FormatException('Invitación incompleta');
    }
    final Uint8List value = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return value;
  }

  String id() {
    final int length = varint();
    return length == 0 ? _uuidText(bytes(16)) : utf8.decode(bytes(length));
  }

  String text() => utf8.decode(bytes(varint()));
}

final RegExp _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

Uint8List? _uuidBytes(String value) {
  if (!_uuid.hasMatch(value)) {
    return null;
  }
  final String hex = value.replaceAll('-', '');
  return Uint8List.fromList(<int>[
    for (int i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}

String _uuidText(Uint8List bytes) {
  final String hex = bytes.map((int byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
