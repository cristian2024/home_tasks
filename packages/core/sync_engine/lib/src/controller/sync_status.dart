import 'package:core_sync/core_sync.dart';
import 'package:equatable/equatable.dart';

/// En qué está la sincronización.
enum SyncPhase {
  /// Sin hogar o detenida.
  disabled,

  /// Esperando: anunciándose y atenta a los demás.
  idle,

  /// Con al menos una sesión en curso.
  syncing,
}

/// Tipo del último error, para explicarlo en la UI.
enum SyncErrorKind {
  /// Sin red, el otro no responde o cerró la conexión.
  transport,

  /// El otro no conoce la clave del hogar (p. ej. un dispositivo expulsado o
  /// de una época anterior).
  authentication,

  /// El otro envió algo que no sigue el protocolo (p. ej. otra versión de la
  /// app).
  protocol,

  /// Cualquier otro.
  unknown,
}

/// Estado visible de la sincronización.
class SyncStatus extends Equatable {
  SyncStatus({
    this.phase = SyncPhase.disabled,
    DateTime? lastSyncAt,
    this.pendingChanges,
    List<SyncEndpoint> visibleDevices = const <SyncEndpoint>[],
    this.lastError,
  })  : lastSyncAt = lastSyncAt?.toUtc(),
        visibleDevices = List<SyncEndpoint>.unmodifiable(visibleDevices);

  final SyncPhase phase;

  /// Última sesión terminada bien, en UTC.
  final DateTime? lastSyncAt;

  /// Cambios propios que aún no tiene ningún dispositivo con el que se haya
  /// sincronizado desde que arrancó la app; `null` si aún no se sabe.
  final int? pendingChanges;

  /// Dispositivos del hogar visibles ahora.
  final List<SyncEndpoint> visibleDevices;

  /// Error de la última sesión, o `null` si terminó bien.
  final SyncErrorKind? lastError;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncAt,
    int? pendingChanges,
    List<SyncEndpoint>? visibleDevices,
    SyncErrorKind? Function()? lastError,
  }) =>
      SyncStatus(
        phase: phase ?? this.phase,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        pendingChanges: pendingChanges ?? this.pendingChanges,
        visibleDevices: visibleDevices ?? this.visibleDevices,
        lastError: lastError == null ? this.lastError : lastError(),
      );

  @override
  List<Object?> get props => <Object?>[phase, lastSyncAt, pendingChanges, visibleDevices, lastError];
}
