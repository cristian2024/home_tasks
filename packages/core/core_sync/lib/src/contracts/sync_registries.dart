import 'package:core_di/core_di.dart';

import 'sync_participant.dart';
import 'sync_transport.dart';

/// Funcionalidades que se sincronizan. Cada adaptador de funcionalidad añade
/// la suya al registrarse ([of] + [add]) y el motor las consulta al aplicar
/// cambios.
class SyncParticipants {
  final List<SyncParticipant> _all = <SyncParticipant>[];

  /// El registro de [services]. Lo crea en el scope activo si no existe, así
  /// que hay que llamarlo desde el scope raíz (en `DependencyModule.register`).
  static SyncParticipants of(ServiceLocator services) {
    if (!services.isRegistered<SyncParticipants>()) {
      services.registerSingleton<SyncParticipants>(SyncParticipants());
    }
    return services.get<SyncParticipants>();
  }

  List<SyncParticipant> get all => List<SyncParticipant>.unmodifiable(_all);

  /// Lanza [ArgumentError] si alguna de sus colecciones ya tiene participante.
  void add(SyncParticipant participant) {
    for (final String collection in participant.collections) {
      if (forCollection(collection) != null) {
        throw ArgumentError.value(collection, 'participant', 'La colección ya tiene participante');
      }
    }
    _all.add(participant);
  }

  /// Participante de [collection], o `null` si ninguno se encarga de ella.
  SyncParticipant? forCollection(String collection) =>
      _all.where((SyncParticipant participant) => participant.collections.contains(collection)).firstOrNull;
}

/// Transportes disponibles (red local, relay…). Cada adaptador de transporte
/// añade el suyo al registrarse ([of] + [add]).
class SyncTransports {
  final List<SyncTransport> _all = <SyncTransport>[];

  /// El registro de [services]. Lo crea en el scope activo si no existe.
  static SyncTransports of(ServiceLocator services) {
    if (!services.isRegistered<SyncTransports>()) {
      services.registerSingleton<SyncTransports>(SyncTransports());
    }
    return services.get<SyncTransports>();
  }

  List<SyncTransport> get all => List<SyncTransport>.unmodifiable(_all);

  /// Lanza [ArgumentError] si ya hay un transporte con su `id`.
  void add(SyncTransport transport) {
    if (_all.any((SyncTransport other) => other.id == transport.id)) {
      throw ArgumentError.value(transport.id, 'transport', 'Ya hay un transporte con ese id');
    }
    _all.add(transport);
  }
}
