import 'dart:async';

import 'package:test/test.dart';

import '../data_space.dart';
import '../data_space_directory.dart';
import '../data_space_exception.dart';

/// Crea una implementación vacía para un test.
typedef DataSpaceDirectoryFactory = FutureOr<DataSpaceDirectory> Function();

/// Tests de contrato de [DataSpaceDirectory]. Toda implementación debe
/// pasarlos.
///
/// ```dart
/// dataSpaceDirectoryContract('InMemory', create: InMemoryDataSpaceDirectory.new);
/// ```
void dataSpaceDirectoryContract(String implementation, {required DataSpaceDirectoryFactory create}) {
  group('DataSpaceDirectory ($implementation)', () {
    final DataSpace home = DataSpace(
      id: 'space-casa',
      name: 'Casa',
      databaseName: 'default',
      createdAt: DateTime.utc(2026, 10, 1),
      householdId: 'hogar-1',
    );
    final DataSpace office = DataSpace.create(id: 'space-oficina', name: 'Oficina', createdAt: DateTime.utc(2026, 10, 2));
    final DataSpace personal = DataSpace.create(id: 'space-personal', name: 'Personal', createdAt: DateTime.utc(2026, 10, 2));

    test('empieza sin espacios ni activo', () async {
      final DataSpaceDirectory directory = await create();

      expect(await directory.spaces(), isEmpty);
      expect(await directory.active(), isNull);
    });

    test('el primer espacio que se guarda es el activo', () async {
      final DataSpaceDirectory directory = await create();

      await directory.save(home);
      await directory.save(office);

      expect(await directory.active(), home);
    });

    test('spaces los ordena por createdAt y después por id', () async {
      final DataSpaceDirectory directory = await create();

      await directory.save(personal);
      await directory.save(office);
      await directory.save(home);

      expect(await directory.spaces(), <DataSpace>[home, office, personal]);
    });

    test('save reemplaza el espacio con el mismo id', () async {
      final DataSpaceDirectory directory = await create();
      await directory.save(home);
      final DataSpace renamed = home.copyWith(name: 'Piso', householdId: () => null);

      await directory.save(renamed);

      expect(await directory.spaces(), <DataSpace>[renamed]);
      expect(await directory.active(), renamed);
    });

    test('save rechaza un hogar que ya tiene espacio, sin guardar nada', () async {
      final DataSpaceDirectory directory = await create();
      await directory.save(home);

      await expectLater(
        directory.save(office.copyWith(householdId: () => 'hogar-1')),
        throwsA(isA<DuplicateHouseholdSpaceException>()
            .having((DuplicateHouseholdSpaceException e) => e.existingSpaceId, 'existingSpaceId', home.id)),
      );
      expect(await directory.spaces(), <DataSpace>[home]);
    });

    test('save rechaza una base que ya es de otro espacio, sin guardar nada', () async {
      final DataSpaceDirectory directory = await create();
      await directory.save(home);

      await expectLater(
        directory.save(DataSpace(id: 'otro', name: 'Otro', databaseName: 'default', createdAt: DateTime.utc(2026, 10, 3))),
        throwsA(isA<DuplicateDatabaseNameException>()),
      );
      expect(await directory.spaces(), <DataSpace>[home]);
    });

    test('setActive cambia el espacio activo', () async {
      final DataSpaceDirectory directory = await create();
      await directory.save(home);
      await directory.save(office);

      await directory.setActive(office.id);

      expect(await directory.active(), office);
    });

    test('setActive de un espacio desconocido lanza sin cambiar el activo', () async {
      final DataSpaceDirectory directory = await create();
      await directory.save(home);

      await expectLater(directory.setActive('nadie'), throwsA(isA<UnknownDataSpaceException>()));
      expect(await directory.active(), home);
    });

    test('remove quita un espacio y no falla si no existe', () async {
      final DataSpaceDirectory directory = await create();
      await directory.save(home);
      await directory.save(office);

      await directory.remove(office.id);
      await directory.remove('nadie');

      expect(await directory.spaces(), <DataSpace>[home]);
    });

    test('remove del espacio activo lanza sin quitarlo', () async {
      final DataSpaceDirectory directory = await create();
      await directory.save(home);

      await expectLater(directory.remove(home.id), throwsA(isA<ActiveDataSpaceRemovalException>()));
      expect(await directory.spaces(), <DataSpace>[home]);
    });

    test('watchSpaces emite al escuchar y cada vez que cambian', () async {
      final DataSpaceDirectory directory = await create();
      final List<List<DataSpace>> emitted = <List<DataSpace>>[];
      final StreamSubscription<List<DataSpace>> subscription = directory.watchSpaces().listen(emitted.add);
      await pumpEventQueue();

      await directory.save(home);
      await pumpEventQueue();
      await directory.save(office);
      await pumpEventQueue();
      await directory.setActive(office.id);
      await directory.remove(home.id);
      await pumpEventQueue();

      expect(emitted, <List<DataSpace>>[
        <DataSpace>[],
        <DataSpace>[home],
        <DataSpace>[home, office],
        <DataSpace>[office],
      ]);
      await subscription.cancel();
    });
  });
}
