import 'package:storage_isar/adapter.dart';

part 'isar_sync_peer.g.dart';

/// Un dispositivo con el que ya se sincronizó.
@collection
class IsarSyncPeer {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String deviceId;

  late String name;

  late DateTime lastSyncedAt;
}
