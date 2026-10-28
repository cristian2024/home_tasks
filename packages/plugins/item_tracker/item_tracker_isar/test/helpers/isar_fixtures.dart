import 'dart:io';

import 'package:core_di/core_di.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:storage_isar/adapter.dart';
import 'package:storage_isar/storage_isar.dart';

final DateTime t0 = DateTime.utc(2026, 10, 21, 14, 30);

HouseholdItem item({
  String id = 'item-1',
  String name = 'Caja A',
  String description = '',
  ItemMetadata metadata = const ItemMetadata.empty(),
  DateTime? updatedAt,
  String? parentId,
}) =>
    HouseholdItem(
      id: id,
      name: name,
      description: description,
      metadata: metadata,
      createdAt: t0,
      updatedAt: updatedAt ?? t0,
      parentId: parentId,
    );

PhysicalIdentifier identifier({
  String id = 'ident-1',
  String rawValue = 'QR-123',
  IdentifierType type = IdentifierType.qr,
  String itemId = 'item-1',
}) =>
    PhysicalIdentifier(id: id, rawValue: rawValue, type: type, itemId: itemId, boundAt: t0);

ItemEvent event(String id, {String itemId = 'item-1', ItemEventKind kind = ItemEventKind.note}) =>
    ItemEvent(id: id, itemId: itemId, kind: kind, title: id, description: '', timestamp: t0);

/// item_tracker sobre Isar tal como lo compone una app: [IsarStorage] con
/// [ItemTrackerIsar], en un locator propio y un directorio temporal. [close]
/// cierra la base y borra el directorio.
class TestStorage {
  TestStorage._(this.services, this.isar, this._directory);

  final ServiceLocator services;

  /// La base abierta, para comprobar cómo quedan guardados los datos.
  final Isar isar;
  final Directory _directory;

  HouseholdItemRepository get repository => services.get<HouseholdItemRepository>();

  static Future<TestStorage> open() async {
    final Directory directory = Directory.systemTemp.createTempSync('item_tracker_isar_test');
    final ServiceLocator services = ServiceLocator();
    final _CapturingFeature feature = _CapturingFeature();
    await IsarStorage(directory: directory.path, features: <IsarFeature>[feature]).register(services);
    return TestStorage._(services, feature.isar!, directory);
  }

  Future<void> close() async {
    await services.reset();
    _directory.deleteSync(recursive: true);
  }
}

/// [ItemTrackerIsar] que además guarda la base con la que lo conectan.
class _CapturingFeature implements IsarFeature {
  static const ItemTrackerIsar _feature = ItemTrackerIsar();

  Isar? isar;

  @override
  List<CollectionSchema<dynamic>> get schemas => _feature.schemas;

  @override
  void register(ServiceLocator services, Isar isar) {
    this.isar = isar;
    _feature.register(services, isar);
  }
}
