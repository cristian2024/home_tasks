import 'package:equatable/equatable.dart';

import 'change_record.dart';
import 'json.dart';

/// Qué cambios se tienen de cada dispositivo: `{deviceId: último seq}`, con
/// todos los anteriores incluidos. Un dispositivo ausente vale 0.
class VersionVector extends Equatable {
  /// Lanza [ArgumentError] si algún seq es negativo o algún id está vacío.
  /// Las entradas a 0 se descartan.
  VersionVector([Map<String, int> seqs = const <String, int>{}])
      : seqs = Map<String, int>.unmodifiable(<String, int>{
          for (final MapEntry<String, int> entry in seqs.entries)
            if (entry.value != 0) checkNotEmpty(entry.key, 'deviceId'): _checkSeq(entry.value),
        });

  /// Lee un vector escrito con [toJson]. Lanza [FormatException] si no lo es.
  factory VersionVector.fromJson(Object? source) {
    final Map<String, Object?> json = asJsonMap(source);
    return parseJson(
      source,
      () => VersionVector(<String, int>{
        for (final String deviceId in json.keys) deviceId: readJson<int>(json, deviceId),
      }),
    );
  }

  static final VersionVector empty = VersionVector();

  final Map<String, int> seqs;

  /// Último seq de [deviceId] (0 si no hay ninguno).
  int operator [](String deviceId) => seqs[deviceId] ?? 0;

  /// Si ya incluye [record].
  bool includes(ChangeRecord record) => this[record.deviceId] >= record.seq;

  /// Si incluye todo lo de [other].
  bool covers(VersionVector other) =>
      other.seqs.entries.every((MapEntry<String, int> entry) => this[entry.key] >= entry.value);

  /// Copia con [seq] para [deviceId], si es mayor que el actual.
  VersionVector advance(String deviceId, int seq) =>
      seq <= this[deviceId] ? this : VersionVector(<String, int>{...seqs, deviceId: seq});

  /// Máximo por dispositivo de los dos vectores.
  VersionVector merge(VersionVector other) {
    VersionVector merged = this;
    for (final MapEntry<String, int> entry in other.seqs.entries) {
      merged = merged.advance(entry.key, entry.value);
    }
    return merged;
  }

  /// Cuántos cambios tiene este vector que [other] no tiene.
  int countAhead(VersionVector other) => seqs.entries.fold(
        0,
        (int total, MapEntry<String, int> entry) =>
            total + (entry.value > other[entry.key] ? entry.value - other[entry.key] : 0),
      );

  Map<String, int> toJson() => Map<String, int>.of(seqs);

  static int _checkSeq(int seq) {
    if (seq < 0) {
      throw ArgumentError.value(seq, 'seq', 'No puede ser negativo');
    }
    return seq;
  }

  @override
  List<Object?> get props => <Object?>[seqs];
}
