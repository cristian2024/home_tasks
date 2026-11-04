import 'package:equatable/equatable.dart';
import 'package:hlc/hlc.dart';

import 'blob_ref.dart';
import 'field_change.dart';
import 'json.dart';

/// Cambio inmutable de una entidad, hecho en un dispositivo. Es lo único que
/// intercambia la sincronización.
///
/// No lleva el hogar: se registra también antes de pertenecer a uno, y el
/// hogar va en los datos asociados del cifrado al enviarlo.
class ChangeRecord extends Equatable {
  /// Lanza [ArgumentError] si falta algún identificador, [seq] es menor que
  /// 1, [changes] está vacío o [hlc] no es de [deviceId].
  ChangeRecord({
    required this.opId,
    required this.deviceId,
    required this.seq,
    required this.collection,
    required this.entityId,
    required this.hlc,
    required List<FieldChange> changes,
    List<BlobRef> blobs = const <BlobRef>[],
  })  : changes = List<FieldChange>.unmodifiable(changes),
        blobs = List<BlobRef>.unmodifiable(blobs) {
    checkNotEmpty(opId, 'opId');
    checkNotEmpty(deviceId, 'deviceId');
    checkNotEmpty(collection, 'collection');
    checkNotEmpty(entityId, 'entityId');
    if (seq < 1) {
      throw ArgumentError.value(seq, 'seq', 'Empieza en 1');
    }
    if (changes.isEmpty) {
      throw ArgumentError.value(changes, 'changes', 'No puede estar vacío');
    }
    if (hlc.deviceId != deviceId) {
      throw ArgumentError.value(hlc, 'hlc', 'Debe ser del dispositivo $deviceId');
    }
  }

  /// Lee un registro escrito con [toJson]. Lanza [FormatException] si no lo
  /// es.
  factory ChangeRecord.fromJson(Object? source) {
    final Map<String, Object?> json = asJsonMap(source);
    return parseJson(
      source,
      () => ChangeRecord(
        opId: readJson<String>(json, 'opId'),
        deviceId: readJson<String>(json, 'deviceId'),
        seq: readJson<int>(json, 'seq'),
        collection: readJson<String>(json, 'collection'),
        entityId: readJson<String>(json, 'entityId'),
        hlc: Hlc.parse(readJson<String>(json, 'hlc')),
        changes: readJson<List<Object?>>(json, 'changes').map(FieldChange.fromJson).toList(),
        blobs: readJson<List<Object?>>(json, 'blobs').map(BlobRef.fromJson).toList(),
      ),
    );
  }

  /// UUID v4 del cambio.
  final String opId;

  /// Dispositivo que hizo el cambio.
  final String deviceId;

  /// Posición del cambio entre los de [deviceId]: 1, 2, 3… sin huecos.
  final int seq;

  final String collection;
  final String entityId;

  /// Marca del cambio; vale para todos los de [changes].
  final Hlc hlc;

  final List<FieldChange> changes;

  /// Binarios referenciados (reservado).
  final List<BlobRef> blobs;

  Map<String, Object?> toJson() => <String, Object?>{
        'opId': opId,
        'deviceId': deviceId,
        'seq': seq,
        'collection': collection,
        'entityId': entityId,
        'hlc': hlc.encode(),
        'changes': changes.map((FieldChange change) => change.toJson()).toList(),
        'blobs': blobs.map((BlobRef blob) => blob.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[opId, deviceId, seq, collection, entityId, hlc, changes, blobs];
}
