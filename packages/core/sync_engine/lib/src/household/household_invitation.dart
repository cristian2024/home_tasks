import 'dart:convert';
import 'dart:typed_data';

import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

/// Lo que lleva el QR para unirse a un hogar: el hogar, su época, su clave y,
/// en la fase 2, la URL del relay.
class HouseholdInvitation extends Equatable {
  HouseholdInvitation({required this.household, required Uint8List key, this.relayUrl})
      : key = Uint8List.fromList(key) {
    if (key.length != SyncCipher.keyLength) {
      throw ArgumentError.value(key.length, 'key', 'Se esperaban ${SyncCipher.keyLength} bytes');
    }
  }

  /// Lee el texto de [encode]. Lanza [FormatException] si no es una
  /// invitación de una versión conocida.
  factory HouseholdInvitation.parse(String text) {
    if (!text.startsWith(_prefix)) {
      throw FormatException('No es una invitación a un hogar', text);
    }
    try {
      final Object? decoded = jsonDecode(utf8.decode(base64Url.decode(text.substring(_prefix.length))));
      if (decoded is! Map<String, Object?> || decoded['v'] != version) {
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

  /// Versión del formato.
  static const int version = 1;

  static const String _prefix = 'hometasks-sync:';

  final Household household;
  final Uint8List key;

  /// Relay de la fase 2 (reservado).
  final String? relayUrl;

  /// Texto para el QR: `hometasks-sync:` seguido del JSON en base64url.
  String encode() => '$_prefix${base64Url.encode(utf8.encode(jsonEncode(<String, Object?>{
        'v': version,
        'id': household.id,
        'epoch': household.epoch,
        'creator': household.creatorDeviceId,
        'key': base64Url.encode(key),
        if (relayUrl != null) 'relay': relayUrl,
      })))}';

  @override
  List<Object?> get props => <Object?>[household, key, relayUrl];
}
