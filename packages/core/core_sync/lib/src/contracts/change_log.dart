import '../model/change_record.dart';
import '../model/version_vector.dart';

/// Registros de cambio de este dispositivo: los propios y los recibidos de
/// otros. Se guardan todos y se reenvían (gossip).
abstract interface class ChangeLog {
  /// Guarda [records] de forma atómica. Ignora los que ya tiene (mismo
  /// `opId`). Lanza [ArgumentError], sin guardar ninguno, si alguno ocupa el
  /// `seq` de otro registro distinto del mismo dispositivo.
  Future<void> append(List<ChangeRecord> records);

  /// Por dispositivo, el mayor `seq` hasta el que se tienen todos sus
  /// registros desde el 1. El siguiente `seq` propio es el de este
  /// dispositivo más uno.
  Future<VersionVector> vector();

  /// Emite [vector] al escuchar y cada vez que cambia.
  Stream<VersionVector> watchVector();

  /// Registros que [remote] no incluye, ordenados por `deviceId` y `seq`. Con
  /// [limit], como mucho esa cantidad.
  Future<List<ChangeRecord>> missingFor(VersionVector remote, {int? limit});
}
