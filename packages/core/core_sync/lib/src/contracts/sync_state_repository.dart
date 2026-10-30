import 'package:hlc/hlc.dart';

import '../model/household.dart';

/// Estado local de la sincronización: identidad del dispositivo, hogar, último
/// HLC y dispositivos con los que ya se sincronizó.
abstract interface class SyncStateRepository {
  Future<DeviceIdentity?> readDevice();

  Future<void> saveDevice(DeviceIdentity device);

  Future<Household?> readHousehold();

  /// Emite el hogar al escuchar y cada vez que cambia (`null` sin hogar).
  Stream<Household?> watchHousehold();

  Future<void> saveHousehold(Household household);

  /// Sale del hogar: borra el hogar y los dispositivos conocidos.
  Future<void> clearHousehold();

  /// Última marca del `HlcClock`, para continuar tras un reinicio.
  Future<Hlc?> readLastHlc();

  Future<void> saveLastHlc(Hlc hlc);

  /// Dispositivos conocidos, ordenados por `deviceId`.
  Future<List<SyncPeer>> peers();

  /// Guarda [peer] y reemplaza el que tenga su `deviceId`.
  Future<void> savePeer(SyncPeer peer);

  /// Olvida un dispositivo. No falla si no existe.
  Future<void> removePeer(String deviceId);
}
