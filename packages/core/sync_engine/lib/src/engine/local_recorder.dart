import 'package:core_sync/core_sync.dart';
import 'package:core_utils/core_utils.dart';

/// Registra cambios propios del motor (p. ej. la resolución de un conflicto)
/// con el siguiente `seq` de este dispositivo.
class LocalRecorder {
  LocalRecorder({required ChangeLog log, required HlcClock hlcClock, IdGenerator ids = const UuidV4Generator()})
      : _log = log,
        _hlcClock = hlcClock,
        _ids = ids;

  static const int _attempts = 3;

  final ChangeLog _log;
  final HlcClock _hlcClock;
  final IdGenerator _ids;

  /// Guarda un registro de [changes] sobre [entityId]. Si otro escritor ocupa
  /// el `seq` a la vez, lo reintenta con el siguiente.
  Future<ChangeRecord> record(String collection, String entityId, List<FieldChange> changes) async {
    for (int attempt = 1;; attempt++) {
      final ChangeRecord record = ChangeRecord(
        opId: _ids.newId(),
        deviceId: _hlcClock.deviceId,
        seq: (await _log.vector())[_hlcClock.deviceId] + 1,
        collection: collection,
        entityId: entityId,
        hlc: _hlcClock.now(),
        changes: changes,
      );
      try {
        await _log.append(<ChangeRecord>[record]);
        return record;
      } on ArgumentError {
        if (attempt == _attempts) {
          rethrow;
        }
      }
    }
  }
}
