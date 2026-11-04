import 'dart:async';

import '../contracts/change_log.dart';
import '../model/change_record.dart';
import '../model/version_vector.dart';
import 'watch.dart';

/// [ChangeLog] en memoria. Cumple `changeLogContract`.
class InMemoryChangeLog implements ChangeLog {
  final Map<String, Map<int, ChangeRecord>> _byDevice = <String, Map<int, ChangeRecord>>{};
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);

  /// Todos los registros guardados, ordenados por `deviceId` y `seq`.
  List<ChangeRecord> get records => _missingFor(VersionVector.empty);

  @override
  Future<void> append(List<ChangeRecord> records) async {
    final List<ChangeRecord> added = <ChangeRecord>[];
    for (final ChangeRecord record in records) {
      final ChangeRecord? existing = _byDevice[record.deviceId]?[record.seq] ??
          added.where((ChangeRecord other) => other.deviceId == record.deviceId && other.seq == record.seq).firstOrNull;
      if (existing == null) {
        added.add(record);
      } else if (existing.opId != record.opId) {
        throw ArgumentError.value(record, 'records', 'El seq ${record.seq} de ${record.deviceId} ya es de otro registro');
      }
    }
    if (added.isEmpty) {
      return;
    }
    for (final ChangeRecord record in added) {
      _byDevice.putIfAbsent(record.deviceId, () => <int, ChangeRecord>{})[record.seq] = record;
    }
    _changes.add(null);
  }

  @override
  Future<VersionVector> vector() async => _vector();

  @override
  Stream<VersionVector> watchVector() => watchValue(_changes.stream, _vector);

  @override
  Future<List<ChangeRecord>> missingFor(VersionVector remote, {int? limit}) async {
    final List<ChangeRecord> missing = _missingFor(remote);
    return limit == null || missing.length <= limit ? missing : missing.sublist(0, limit);
  }

  VersionVector _vector() {
    final Map<String, int> seqs = <String, int>{};
    for (final MapEntry<String, Map<int, ChangeRecord>> device in _byDevice.entries) {
      int seq = 0;
      while (device.value.containsKey(seq + 1)) {
        seq++;
      }
      seqs[device.key] = seq;
    }
    return VersionVector(seqs);
  }

  List<ChangeRecord> _missingFor(VersionVector remote) {
    final List<String> devices = _byDevice.keys.toList()..sort();
    return <ChangeRecord>[
      for (final String device in devices)
        ...(_byDevice[device]!.values.where((ChangeRecord record) => !remote.includes(record)).toList()
          ..sort((ChangeRecord a, ChangeRecord b) => a.seq.compareTo(b.seq))),
    ];
  }
}
