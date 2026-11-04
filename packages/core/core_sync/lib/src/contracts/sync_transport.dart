import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../model/json.dart';

/// Lo que anuncia un dispositivo para que lo encuentren los de su hogar.
class SyncAdvertisement extends Equatable {
  SyncAdvertisement({required this.discoveryId, required this.deviceId, required this.deviceName}) {
    checkNotEmpty(discoveryId, 'discoveryId');
    checkNotEmpty(deviceId, 'deviceId');
  }

  /// Identificador derivado de la clave de la época, nunca el id del hogar.
  /// Solo se ven los dispositivos que anuncian el mismo.
  final String discoveryId;

  final String deviceId;
  final String deviceName;

  @override
  List<Object?> get props => <Object?>[discoveryId, deviceId, deviceName];
}

/// Otro dispositivo visible en un transporte.
class SyncEndpoint extends Equatable {
  SyncEndpoint({required this.transportId, required this.deviceId, required this.deviceName, required this.address}) {
    checkNotEmpty(transportId, 'transportId');
    checkNotEmpty(deviceId, 'deviceId');
  }

  final String transportId;
  final String deviceId;
  final String deviceName;

  /// Dirección propia del transporte (p. ej. `ws://192.168.1.20:4040`).
  final String address;

  @override
  List<Object?> get props => <Object?>[transportId, deviceId, deviceName, address];
}

/// Conexión bidireccional de mensajes binarios con otro dispositivo. Los
/// mensajes llegan completos y en orden.
abstract interface class SyncChannel {
  /// Mensajes recibidos. Una sola suscripción; termina cuando cualquiera de
  /// los dos lados cierra el canal.
  Stream<Uint8List> get messages;

  /// Lanza `SyncTransportException` si el canal está cerrado.
  Future<void> send(Uint8List message);

  /// Cierra el canal en los dos lados. No falla si ya estaba cerrado.
  Future<void> close();
}

/// Forma de encontrar y conectar con otros dispositivos (red local, relay…).
abstract interface class SyncTransport {
  /// Identificador del transporte (p. ej. `lan`).
  String get id;

  /// Empieza a anunciarse con [advertisement], a buscar y a aceptar
  /// conexiones. Si ya había empezado, cambia el anuncio.
  Future<void> start(SyncAdvertisement advertisement);

  /// Deja de anunciarse, de buscar y de aceptar conexiones. No falla si no
  /// había empezado.
  Future<void> stop();

  /// Emite al escuchar y cada vez que cambian los dispositivos visibles con
  /// el mismo `discoveryId`, sin incluir este.
  Stream<List<SyncEndpoint>> watchEndpoints();

  /// Canales que abren otros dispositivos con [connect].
  Stream<SyncChannel> get incoming;

  /// Abre un canal con [endpoint]. Lanza `SyncTransportException` si no
  /// responde.
  Future<SyncChannel> connect(SyncEndpoint endpoint);
}
