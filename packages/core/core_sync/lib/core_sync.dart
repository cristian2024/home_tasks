/// Contratos y modelo de la sincronización entre dispositivos: registros de
/// cambio, vector de versiones, metadatos por campo, hogar y conflictos. Los
/// dominios de las funcionalidades dependen de este paquete; el motor está en
/// `sync_engine` y las implementaciones en los adaptadores.
library;

export 'package:hlc/hlc.dart';

export 'src/contracts/change_log.dart';
export 'src/contracts/conflict_repository.dart';
export 'src/contracts/sync_cipher.dart';
export 'src/contracts/sync_participant.dart';
export 'src/contracts/sync_state_repository.dart';
export 'src/contracts/sync_transport.dart';
export 'src/model/blob_ref.dart';
export 'src/model/change_record.dart';
export 'src/model/field_change.dart';
export 'src/model/household.dart';
export 'src/model/sync_conflict.dart';
export 'src/model/sync_metadata.dart';
export 'src/model/version_vector.dart';
export 'src/sync_exception.dart';
