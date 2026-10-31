# Changelog

## 0.1.1 - 2026-10-30

### Añadido

- `SyncedEntity`: copia sincronizada de una entidad (último valor y marca de cada campo), que se fusiona con `apply` / `merge`. Un conjunto se guarda como la lista ordenada de sus elementos presentes.
- `FieldDiff.between`: cambios entre dos versiones de los campos. Un valor `Set<String>` se compara elemento a elemento (`ElementChange`); mapas y listas, por contenido.
- `LocalSyncRecorder` (con `LocalSyncWrite` y `LocalSyncChanges`): convierte una escritura local de un repositorio en registros de cambio con la misma marca y en sus copias sincronizadas nuevas.

## 0.1.0 - 2026-10-30

### Añadido

- Modelo de la sincronización: `ChangeRecord`, `FieldChange` (`ValueChange` y `ElementChange`), `VersionVector`, `SyncMetadata` con su fusión por campo y por elemento (`apply`, `merge`, `SyncMerge`), `Household`, `DeviceIdentity`, `SyncPeer`, `SyncConflict`, `ConflictOption` y `BlobRef` (reservado). Los que viajan o se guardan como texto tienen `toJson` / `fromJson`.
- Contratos `ChangeLog`, `SyncStateRepository`, `ConflictRepository`, `SyncCipher`, `SyncTransport` / `SyncChannel` y `SyncParticipant`.
- Registros `SyncParticipants` y `SyncTransports` (`of(services)`), donde los adaptadores apuntan sus participantes y transportes.
- Errores `SyncTransportException` y `SyncCipherException`, bajo el `sealed` `SyncException`.
- `package:core_sync/testing.dart`: una batería de contrato por contrato, implementaciones en memoria, `InMemorySyncNetwork` con cortes de red y `FakeSyncCipher` (no seguro).
- README del paquete.
