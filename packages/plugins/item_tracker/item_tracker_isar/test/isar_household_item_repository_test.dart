import 'package:flutter_test/flutter_test.dart';
import 'package:item_tracker_domain/item_tracker_domain.dart';
import 'package:item_tracker_domain/testing.dart';
import 'package:item_tracker_isar/item_tracker_isar.dart';
import 'package:item_tracker_isar/src/models/isar_physical_identifier.dart';
import 'package:item_tracker_isar/src/repositories/isar_household_item_repository.dart';
import 'package:storage_isar/adapter.dart';

import 'helpers/isar_fixtures.dart';

void main() {
  setUpAll(() => Isar.initializeIsarCore(download: true));

  final Map<HouseholdItemRepository, TestStorage> storages = <HouseholdItemRepository, TestStorage>{};
  householdItemRepositoryContract(
    'Isar',
    create: () async {
      final TestStorage storage = await TestStorage.open();
      storages[storage.repository] = storage;
      return storage.repository;
    },
    dispose: (HouseholdItemRepository repository) => storages.remove(repository)!.close(),
  );

  group('ItemTrackerIsar', () {
    late TestStorage storage;

    setUp(() async => storage = await TestStorage.open());
    tearDown(() => storage.close());

    test('aporta las colecciones de item_tracker y registra su repositorio Isar', () {
      expect(
        const ItemTrackerIsar().schemas.map((CollectionSchema<dynamic> schema) => schema.name),
        <String>['IsarHouseholdItem', 'IsarPhysicalIdentifier', 'IsarItemEvent'],
      );
      expect(storage.repository, isA<IsarHouseholdItemRepository>());
    });

    // Lo propio de Isar: cómo queda guardado un identificador quitado.
    group('borrado lógico (spec §10.3)', () {
      setUp(() => storage.repository.createItem(item(), identifier: identifier(id: 'i1'), events: const <ItemEvent>[]));

      test('quitar un identificador lo conserva marcado como borrado', () async {
        final DateTime deletedAt = t0.add(const Duration(hours: 1));

        await storage.repository.unbindIdentifier('i1', deletedAt: deletedAt, event: event('e1'));

        final IsarPhysicalIdentifier? stored = await storage.isar.isarPhysicalIdentifiers.getById('i1');
        expect(stored?.isDeleted, isTrue);
        expect(stored?.deletedAt?.toUtc(), deletedAt);
      });

      test('cada asociación del mismo valor es un registro distinto', () async {
        final HouseholdItemRepository repository = storage.repository;
        await repository.unbindIdentifier('i1', deletedAt: t0, event: event('e1'));
        await repository.bindIdentifier(identifier(id: 'i2'), event('e2'));
        await repository.unbindIdentifier('i2', deletedAt: t0, event: event('e3'));
        await repository.bindIdentifier(identifier(id: 'i3'), event('e4'));

        expect(await storage.isar.isarPhysicalIdentifiers.count(), 3);
        expect((await repository.findIdentifier('QR-123', IdentifierType.qr))?.id, 'i3');
      });
    });
  });
}
