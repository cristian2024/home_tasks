import 'dart:convert';
import 'dart:typed_data';

import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

import 'invitation_codec.dart';

/// Lo que lleva el QR para unirse a un hogar: el hogar, su época, su clave y,
/// en la fase 2, la URL del relay.
class HouseholdInvitation extends Equatable {
  HouseholdInvitation({required this.household, required Uint8List key, this.relayUrl})
      : key = Uint8List.fromList(key) {
    if (key.length != SyncCipher.keyLength) {
      throw ArgumentError.value(key.length, 'key', 'Se esperaban ${SyncCipher.keyLength} bytes');
    }
  }

  /// Lee el texto de [encode], también el de la versión 1. Ignora espacios,
  /// saltos de línea y mayúsculas o minúsculas en el código. Lanza
  /// [FormatException] si no es una invitación de una versión conocida.
  factory HouseholdInvitation.parse(String text) {
    final String compact = text.replaceAll(RegExp(r'\s'), '');
    if (compact.toUpperCase().startsWith(_prefix)) {
      return _parseCompact(compact.substring(_prefix.length).toUpperCase(), text);
    }
    if (compact.startsWith(_legacyPrefix)) {
      return _parseLegacy(compact.substring(_legacyPrefix.length), text);
    }
    throw FormatException('No es una invitación a un hogar', text);
  }

  static HouseholdInvitation _parseCompact(String code, String text) {
    try {
      final InvitationReader reader = InvitationReader(Base32.decode(code));
      if (reader.byte() != version) {
        throw FormatException('Versión de invitación desconocida', text);
      }
      final int epoch = reader.varint();
      final String id = reader.id();
      final String creator = reader.id();
      final Uint8List key = reader.bytes(SyncCipher.keyLength);
      final String? relayUrl = reader.isAtEnd ? null : reader.text();
      if (!reader.isAtEnd) {
        throw FormatException('Sobran datos en la invitación', text);
      }
      return HouseholdInvitation(
        household: Household(id: id, epoch: epoch, creatorDeviceId: creator),
        key: key,
        relayUrl: relayUrl,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invitación inválida: $error', text);
    }
  }

  /// Versión 1: JSON en base64url.
  static HouseholdInvitation _parseLegacy(String code, String text) {
    try {
      final Object? decoded = jsonDecode(utf8.decode(base64Url.decode(code)));
      if (decoded is! Map<String, Object?> || decoded['v'] != 1) {
        throw FormatException('Versión de invitación desconocida', text);
      }
      final Object? relayUrl = decoded['relay'];
      return HouseholdInvitation(
        household: Household(
          id: decoded['id']! as String,
          epoch: decoded['epoch']! as int,
          creatorDeviceId: decoded['creator']! as String,
        ),
        key: base64Url.decode(decoded['key']! as String),
        relayUrl: relayUrl is String ? relayUrl : null,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invitación inválida: $error', text);
    }
  }

  /// Versión del formato que escribe [encode].
  static const int version = 2;

  static const String _prefix = 'HOMETASKS:';
  static const String _legacyPrefix = 'hometasks-sync:';

  final Household household;
  final Uint8List key;

  /// Relay de la fase 2 (reservado).
  final String? relayUrl;

  /// Texto para el QR y para copiar: `HOMETASKS:` seguido de los campos en
  /// binario y en base32. Todo son mayúsculas, dígitos y `:`, así que el QR
  /// usa el modo alfanumérico, el más compacto para este texto.
  String encode() {
    final InvitationWriter writer = InvitationWriter()
      ..byte(version)
      ..varint(household.epoch)
      ..id(household.id)
      ..id(household.creatorDeviceId)
      ..bytes(key);
    final String? relay = relayUrl;
    if (relay != null) {
      writer.text(relay);
    }
    return '$_prefix${Base32.encode(writer.takeBytes())}';
  }

  @override
  List<Object?> get props => <Object?>[household, key, relayUrl];
}
