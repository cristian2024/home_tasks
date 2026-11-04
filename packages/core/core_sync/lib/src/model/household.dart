import 'package:equatable/equatable.dart';

import 'json.dart';

/// Hogar: el grupo de dispositivos que comparten datos. Su clave no está aquí:
/// va en el almacén de secretos.
class Household extends Equatable {
  /// Lanza [ArgumentError] si falta algún id o [epoch] es menor que 1.
  Household({required this.id, required this.epoch, required this.creatorDeviceId}) {
    checkNotEmpty(id, 'id');
    checkNotEmpty(creatorDeviceId, 'creatorDeviceId');
    if (epoch < 1) {
      throw ArgumentError.value(epoch, 'epoch', 'Empieza en 1');
    }
  }

  /// UUID v4 del hogar.
  final String id;

  /// Época de la clave: sube cada vez que el creador expulsa un dispositivo.
  final int epoch;

  /// Único dispositivo que puede expulsar a otros.
  final String creatorDeviceId;

  bool isCreator(String deviceId) => deviceId == creatorDeviceId;

  /// El mismo hogar en la época siguiente.
  Household nextEpoch() => Household(id: id, epoch: epoch + 1, creatorDeviceId: creatorDeviceId);

  @override
  List<Object?> get props => <Object?>[id, epoch, creatorDeviceId];
}

/// Identidad de este dispositivo.
class DeviceIdentity extends Equatable {
  DeviceIdentity({required this.deviceId, required this.name}) {
    checkNotEmpty(deviceId, 'deviceId');
  }

  /// UUID v4, generado una vez por instalación.
  final String deviceId;

  /// Nombre que ven los demás dispositivos (p. ej. «Teléfono de Ana»).
  final String name;

  @override
  List<Object?> get props => <Object?>[deviceId, name];
}

/// Otro dispositivo del hogar con el que ya se sincronizó.
class SyncPeer extends Equatable {
  SyncPeer({required this.deviceId, required this.name, required DateTime lastSyncedAt})
      : lastSyncedAt = lastSyncedAt.toUtc() {
    checkNotEmpty(deviceId, 'deviceId');
  }

  final String deviceId;
  final String name;

  /// Última sincronización con él, en UTC.
  final DateTime lastSyncedAt;

  @override
  List<Object?> get props => <Object?>[deviceId, name, lastSyncedAt];
}
