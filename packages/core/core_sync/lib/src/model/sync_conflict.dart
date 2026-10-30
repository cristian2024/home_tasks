import 'package:equatable/equatable.dart';

import 'json.dart';

/// Una forma de resolver un [SyncConflict]. [details] son datos para
/// mostrarla (p. ej. el nombre de cada objeto), definidos por la
/// funcionalidad.
class ConflictOption extends Equatable {
  ConflictOption(this.id, {Map<String, String> details = const <String, String>{}})
      : details = Map<String, String>.unmodifiable(details) {
    checkNotEmpty(id, 'id');
  }

  final String id;
  final Map<String, String> details;

  @override
  List<Object?> get props => <Object?>[id, details];
}

/// Conflicto de reglas de negocio detectado al fusionar. Ya tiene aplicada una
/// resolución provisional ([provisionalOptionId]); queda en la bandeja hasta
/// que el usuario la confirma o elige otra.
///
/// Cada funcionalidad define sus [kind] y sus opciones. El [id] es
/// determinista: todos los dispositivos que detectan el mismo conflicto le dan
/// el mismo.
class SyncConflict extends Equatable {
  /// Lanza [ArgumentError] si falta algún id, no hay entidades u opciones, o
  /// [provisionalOptionId] o [resolvedOptionId] no están entre las opciones.
  SyncConflict({
    required this.id,
    required this.collection,
    required this.kind,
    required List<String> entityIds,
    required List<ConflictOption> options,
    required this.provisionalOptionId,
    required DateTime detectedAt,
    this.resolvedOptionId,
  })  : entityIds = List<String>.unmodifiable(entityIds),
        options = List<ConflictOption>.unmodifiable(options),
        detectedAt = detectedAt.toUtc() {
    checkNotEmpty(id, 'id');
    checkNotEmpty(collection, 'collection');
    checkNotEmpty(kind, 'kind');
    if (entityIds.isEmpty) {
      throw ArgumentError.value(entityIds, 'entityIds', 'No puede estar vacío');
    }
    _checkOption(provisionalOptionId, 'provisionalOptionId');
    final String? resolved = resolvedOptionId;
    if (resolved != null) {
      _checkOption(resolved, 'resolvedOptionId');
    }
  }

  final String id;
  final String collection;
  final String kind;
  final List<String> entityIds;
  final List<ConflictOption> options;

  /// Opción ya aplicada al detectar el conflicto.
  final String provisionalOptionId;

  /// Cuándo se detectó en este dispositivo, en UTC.
  final DateTime detectedAt;

  /// Opción elegida por el usuario, o `null` si sigue abierto.
  final String? resolvedOptionId;

  bool get isResolved => resolvedOptionId != null;

  /// El mismo conflicto, resuelto con [optionId]. Lanza [ArgumentError] si no
  /// es una de las opciones.
  SyncConflict resolve(String optionId) => SyncConflict(
        id: id,
        collection: collection,
        kind: kind,
        entityIds: entityIds,
        options: options,
        provisionalOptionId: provisionalOptionId,
        detectedAt: detectedAt,
        resolvedOptionId: optionId,
      );

  void _checkOption(String optionId, String name) {
    if (!options.any((ConflictOption option) => option.id == optionId)) {
      throw ArgumentError.value(optionId, name, 'No es una de las opciones');
    }
  }

  @override
  List<Object?> get props =>
      <Object?>[id, collection, kind, entityIds, options, provisionalOptionId, detectedAt, resolvedOptionId];
}
