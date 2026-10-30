# Changelog

## 0.1.0 - 2026-10-30

### Añadido

- Modelo de la sincronización: `ChangeRecord`, `FieldChange` (`ValueChange` y `ElementChange`), `VersionVector`, `SyncMetadata` con su fusión por campo y por elemento (`apply`, `merge`, `SyncMerge`), `Household`, `DeviceIdentity`, `SyncPeer`, `SyncConflict`, `ConflictOption` y `BlobRef` (reservado). Los que viajan o se guardan como texto tienen `toJson` / `fromJson`.
- Contratos `ChangeLog`, `SyncStateRepository`, `ConflictRepository`, `SyncCipher`, `SyncTransport` / `SyncChannel` y `SyncParticipant`.
- Errores `SyncTransportException` y `SyncCipherException`, bajo el `sealed` `SyncException`.
- `package:core_sync/testing.dart`: una batería de contrato por contrato, implementaciones en memoria, `InMemorySyncNetwork` con cortes de red y `FakeSyncCipher` (no seguro).
- README del paquete.
