import 'package:core_spaces/core_spaces.dart';
import 'package:core_spaces/testing.dart';
import 'package:test/test.dart';

void main() {
  dataSpaceDirectoryContract('InMemoryDataSpaceDirectory', create: InMemoryDataSpaceDirectory.new);

  dataSpaceStorageContract('InMemoryDataSpaceStorage', create: () {
    final InMemoryDataSpaceStorage storage = InMemoryDataSpaceStorage();
    return DataSpaceStorageHarness(
      storage: storage,
      create: (String name) async => storage.createDatabase(name),
      open: (String name) async => storage.openDatabase(name),
      close: (String name) async => storage.closeDatabase(name),
    );
  });

  group('DataSpace', () {
    final DateTime createdAt = DateTime.utc(2026, 10, 31);

    test('create usa la base space_<id>', () {
      final DataSpace space = DataSpace.create(id: 'abc', name: 'Casa', createdAt: createdAt);

      expect(space.databaseName, 'space_abc');
      expect(space.householdId, isNull);
      expect(space.isShared, isFalse);
    });

    test('compara por valor', () {
      expect(
        DataSpace.create(id: 'a', name: 'Casa', createdAt: createdAt),
        DataSpace.create(id: 'a', name: 'Casa', createdAt: createdAt),
      );
      expect(
        DataSpace.create(id: 'a', name: 'Casa', createdAt: createdAt),
        isNot(DataSpace.create(id: 'a', name: 'Piso', createdAt: createdAt)),
      );
    });

    test('guarda createdAt en UTC', () {
      final DateTime local = DateTime(2026, 10, 31, 12);

      expect(DataSpace.create(id: 'a', name: 'Casa', createdAt: local).createdAt, local.toUtc());
    });

    test('rechaza campos en blanco', () {
      expect(() => DataSpace.create(id: ' ', name: 'Casa', createdAt: createdAt), throwsArgumentError);
      expect(() => DataSpace.create(id: 'a', name: '', createdAt: createdAt), throwsArgumentError);
      expect(() => DataSpace(id: 'a', name: 'Casa', databaseName: ' ', createdAt: createdAt), throwsArgumentError);
      expect(
        () => DataSpace(id: 'a', name: 'Casa', databaseName: 'default', createdAt: createdAt, householdId: ''),
        throwsArgumentError,
      );
    });

    test('copyWith cambia el nombre y el hogar, y conserva lo demás', () {
      final DataSpace space = DataSpace.create(id: 'a', name: 'Casa', createdAt: createdAt);

      final DataSpace shared = space.copyWith(name: 'Piso', householdId: () => 'hogar');

      expect(shared.name, 'Piso');
      expect(shared.householdId, 'hogar');
      expect(shared.isShared, isTrue);
      expect(shared.databaseName, space.databaseName);
      expect(shared.copyWith().householdId, 'hogar');
      expect(shared.copyWith(householdId: () => null).householdId, isNull);
    });
  });

  group('excepciones', () {
    test('describen el problema', () {
      expect(const UnknownDataSpaceException('a').toString(), contains('a'));
      expect(
        const DuplicateHouseholdSpaceException(householdId: 'h', existingSpaceId: 'a').toString(),
        allOf(contains('h'), contains('a')),
      );
      expect(
        const DuplicateDatabaseNameException(databaseName: 'db', existingSpaceId: 'a').toString(),
        allOf(contains('db'), contains('a')),
      );
      expect(const ActiveDataSpaceRemovalException('a').toString(), contains('a'));
      expect(const DataSpaceInUseException('db').toString(), contains('db'));
    });
  });

  group('deleteOrphanDatabases', () {
    test('borra las bases de espacios que ya no están, salvo las abiertas y las sin prefijo', () async {
      final InMemoryDataSpaceDirectory directory = InMemoryDataSpaceDirectory();
      await directory.save(DataSpace(
        id: 'casa',
        name: 'Casa',
        databaseName: 'default',
        createdAt: DateTime.utc(2026, 10, 1),
      ));
      await directory.save(DataSpace.create(id: 'oficina', name: 'Oficina', createdAt: DateTime.utc(2026, 10, 2)));
      final InMemoryDataSpaceStorage storage = InMemoryDataSpaceStorage(
        databases: <String>['default', 'otra', 'space_oficina', 'space_borrado', 'space_abierto'],
      )..openDatabase('space_abierto');

      final Set<String> deleted = await deleteOrphanDatabases(directory: directory, storage: storage);

      expect(deleted, <String>{'space_borrado'});
      expect(await storage.databaseNames(), <String>{'default', 'otra', 'space_oficina', 'space_abierto'});
    });
  });
}
