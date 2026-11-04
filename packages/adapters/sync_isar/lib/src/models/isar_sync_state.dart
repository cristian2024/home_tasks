import 'package:storage_isar/adapter.dart';

part 'isar_sync_state.g.dart';

/// Estado local de la sincronización. Hay un solo objeto ([singletonId]). La
/// clave del hogar no se guarda aquí: va en el almacén seguro.
@collection
class IsarSyncState {
  static const int singletonId = 1;

  Id isarId = singletonId;

  String? deviceId;
  String? deviceName;

  String? householdId;
  int? householdEpoch;
  String? householdCreatorDeviceId;

  /// Última marca del reloj, codificada con `Hlc.encode`.
  String? lastHlc;
}
