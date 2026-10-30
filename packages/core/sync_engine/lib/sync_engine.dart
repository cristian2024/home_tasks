/// Motor de la sincronización entre dispositivos: sesiones cifradas con
/// gossip, aplicación de cambios con los participantes, hogar (crear, unirse,
/// salir, expulsar), bandeja de conflictos y planificación con su estado.
/// [SyncModule] lo compone a partir de lo que registran los adaptadores.
library;

export 'src/controller/sync_controller.dart';
export 'src/controller/sync_status.dart';
export 'src/engine/local_recorder.dart';
export 'src/engine/record_applier.dart';
export 'src/engine/sync_engine.dart';
export 'src/engine/sync_session.dart' show SyncSession, SyncSessionResult;
export 'src/household/household_invitation.dart';
export 'src/household/household_keys.dart';
export 'src/household/household_service.dart';
export 'src/inbox/conflict_inbox.dart';
export 'src/sync_engine_exception.dart';
export 'src/sync_module.dart';
