import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:storage_isar/adapter.dart';
import 'package:storage_isar/storage_isar.dart';
import 'package:sync_isar/sync_isar.dart';

/// La sincronización sobre Isar tal como la compone una app: [IsarStorage]
/// con [SyncIsar], en un locator propio y un directorio temporal. [close]
/// cierra la base y borra el directorio.
class SyncStorage {
  SyncStorage._(this.services, this.isar, this._directory);

  final ServiceLocator services;

  /// La base abierta, para escribir en la misma transacción que el writer.
  final Isar isar;
  final Directory _directory;

  static Future<SyncStorage> open() async {
    final Directory directory = Directory.systemTemp.createTempSync('sync_isar_test');
    final ServiceLocator services = ServiceLocator();
    final _CapturingFeature feature = _CapturingFeature();
    await IsarStorage(directory: directory.path, features: <IsarFeature>[feature]).register(services);
    return SyncStorage._(services, feature.isar!, directory);
  }

  Future<void> close() async {
    await services.reset();
    _directory.deleteSync(recursive: true);
  }
}

/// [SyncIsar] que además guarda la base con la que lo conectan.
class _CapturingFeature implements IsarFeature {
  static const SyncIsar _feature = SyncIsar();

  Isar? isar;

  @override
  List<CollectionSchema<dynamic>> get schemas => _feature.schemas;

  @override
  void register(ServiceLocator services, Isar isar) {
    this.isar = isar;
    _feature.register(services, isar);
  }
}
