import 'package:core_di/core_di.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:core_spaces/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spaces_shared_preferences/spaces_shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  dataSpaceDirectoryContract('SharedPreferencesDataSpaceDirectory', create: () {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    return SharedPreferencesDataSpaceDirectory();
  });

  final DataSpace home = DataSpace(
    id: 'casa',
    name: 'Casa',
    databaseName: 'default',
    createdAt: DateTime.utc(2026, 10, 1, 8, 30),
    householdId: 'hogar-1',
  );
  final DataSpace office = DataSpace.create(id: 'oficina', name: 'Oficina', createdAt: DateTime.utc(2026, 10, 2));

  test('otra instancia lee lo guardado (persiste entre arranques)', () async {
    final SharedPreferencesDataSpaceDirectory first = SharedPreferencesDataSpaceDirectory();
    await first.save(home);
    await first.save(office);
    await first.setActive(office.id);

    final SharedPreferencesDataSpaceDirectory second = SharedPreferencesDataSpaceDirectory();

    expect(await second.spaces(), <DataSpace>[home, office]);
    expect(await second.active(), office);
  });

  test('guarda la lista y el activo en una sola clave', () async {
    await SharedPreferencesDataSpaceDirectory().save(home);

    expect((await SharedPreferences.getInstance()).getKeys(), <String>{SharedPreferencesDataSpaceDirectory.defaultKey});
  });

  test('los cambios simultáneos se aplican de uno en uno, sin perder ninguno', () async {
    final SharedPreferencesDataSpaceDirectory directory = SharedPreferencesDataSpaceDirectory();

    await Future.wait(<Future<void>>[
      for (int i = 0; i < 5; i++) directory.save(DataSpace.create(id: 'e$i', name: 'E$i', createdAt: DateTime.utc(2026))),
    ]);

    expect(await directory.spaces(), hasLength(5));
  });

  test('un cambio que falla no bloquea los siguientes', () async {
    final SharedPreferencesDataSpaceDirectory directory = SharedPreferencesDataSpaceDirectory();

    await expectLater(directory.setActive('nadie'), throwsA(isA<UnknownDataSpaceException>()));
    await directory.save(home);

    expect(await directory.active(), home);
  });

  test('una lista guardada ilegible falla en vez de leerse vacía', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{SharedPreferencesDataSpaceDirectory.defaultKey: '{roto'});

    await expectLater(SharedPreferencesDataSpaceDirectory().spaces(), throwsStateError);
  });

  test('SharedPreferencesSpaces registra el directorio', () async {
    final ServiceLocator locator = ServiceLocator();
    addTearDown(locator.reset);

    await const SharedPreferencesSpaces().register(locator);

    expect(locator.get<DataSpaceDirectory>(), isA<SharedPreferencesDataSpaceDirectory>());
  });
}
