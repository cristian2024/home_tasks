import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_spaces/core_spaces.dart';
import 'package:core_sync/core_sync.dart';
import 'package:core_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_utility_app/bootstrap.dart';
import 'package:home_utility_app/navigation/app_router.dart';
import 'package:home_utility_app/spaces/space_defaults.dart';
import 'package:home_utility_app/spaces/space_switcher.dart';
import 'package:home_utility_app/spaces/space_title_cubit.dart';
import 'package:home_utility_app/spaces/spaces_cubit.dart';
import 'package:home_utility_app/sync/join_household_cubit.dart';
import 'package:plugin_shopping_list/plugin_shopping_list.dart';
import 'package:storage_isar/adapter.dart' show Isar;
import 'package:sync_engine/sync_engine.dart';

import 'helpers/space_phone.dart';

/// Espacios de datos de extremo a extremo, con Isar real y el arranque real:
/// migración desde la base de siempre, cambios de espacio sin mezclar datos,
/// crear un hogar o unirse en otro espacio y borrar espacios.
void main() {
  late InMemorySyncNetwork network;
  final List<SpacePhone> phones = <SpacePhone>[];

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    // bootstrapApp lee de rootBundle; el binding se inicia después de
    // descargar libisar (ver ac02_persistence_test).
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  setUp(() => network = InMemorySyncNetwork());
  tearDown(() async {
    for (final SpacePhone phone in phones) {
      await phone.dispose();
    }
    phones.clear();
  });

  SpacePhone phone(String name) {
    final SpacePhone created = SpacePhone(name, network: network);
    phones.add(created);
    return created;
  }

  Future<void> addItem(AppEnvironment app, String name) =>
      app.locator.get<ShoppingListDependencies>().createItem(name: name);

  Future<List<String>> itemNames(AppEnvironment app) async =>
      (await app.locator.get<ShoppingListRepository>().getItems()).map((ShoppingItem item) => item.name).toList();

  group('migración', () {
    test('el primer arranque crea un espacio sobre la base de siempre y conserva sus datos', () async {
      final SpacePhone ana = phone('ana');
      // Una versión anterior: sin espacios, con datos en la base de siempre.
      final AppEnvironment legacy = await ana.open(
        DataSpace(id: 'previo', name: 'x', databaseName: SpaceDefaults.legacyDatabaseName, createdAt: DateTime.utc(2026)),
      );
      await addItem(legacy, 'Huevos');
      await legacy.dispose();

      await ana.start();

      final DataSpace active = (await ana.spaces.active())!;
      expect(active.databaseName, SpaceDefaults.legacyDatabaseName);
      expect(active.name, 'Mi espacio');
      expect(active.householdId, isNull);
      expect(await itemNames(ana.app), <String>['Huevos']);
    });

    test('anota el hogar de la base de siempre en su espacio', () async {
      final SpacePhone ana = phone('ana');
      final AppEnvironment legacy = await ana.open(
        DataSpace(id: 'previo', name: 'x', databaseName: SpaceDefaults.legacyDatabaseName, createdAt: DateTime.utc(2026)),
      );
      final HouseholdInvitation invitation = await legacy.sync!.households.create();
      await legacy.dispose();

      await ana.start();

      expect((await ana.spaces.active())!.householdId, invitation.household.id);
      expect(await ana.app.sync!.households.keys(), isNotNull);
    });

    test('borra al arrancar las bases de espacios que ya no están en la lista', () async {
      final SpacePhone ana = phone('ana');
      final AppEnvironment orphan = await ana.open(DataSpace.create(id: 'huerfano', name: 'x', createdAt: DateTime.utc(2026)));
      await orphan.dispose();
      expect(await ana.device.spaceStorage.databaseNames(), contains('space_huerfano'));

      await ana.start();

      expect(await ana.device.spaceStorage.databaseNames(), isNot(contains('space_huerfano')));
    });
  });

  group('cambiar de espacio', () {
    test('cada espacio tiene sus datos y sus plugins, y el activo se recuerda', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      final String first = switcher.activeSpaceId;
      await addItem(ana.app, 'Huevos');
      await ana.app.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: false);

      expect(await switcher.createAndSwitch(), isTrue);

      expect(switcher.state.notice, SpaceNotice.created);
      expect(switcher.activeSpaceId, isNot(first));
      expect((await ana.spaces.active())!.id, switcher.activeSpaceId);
      expect(await itemNames(ana.app), isEmpty);
      expect(ana.app.plugins.stateOf(ShoppingListPlugin.pluginId)?.preference.isEnabled, isTrue);

      expect(await switcher.switchTo(first), isTrue);

      expect(switcher.state.notice, SpaceNotice.switched);
      expect(await itemNames(ana.app), <String>['Huevos']);
      expect(ana.app.plugins.stateOf(ShoppingListPlugin.pluginId)?.preference.isEnabled, isFalse);
    });

    test('los accesos rápidos son del dispositivo: el mismo servicio publica los plugins de cada espacio', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      await ana.app.plugins.setEnabled(ShoppingListPlugin.pluginId, enabled: false);
      expect(ana.shortcuts.shortcuts, isEmpty);

      await switcher.createAndSwitch();

      expect(ana.shortcuts.shortcuts.map((AppShortcut shortcut) => shortcut.id), <String>[ShoppingListPlugin.pluginId]);
      expect(ana.app.shortcuts, isNotNull);
    });

    test('si el espacio no se abre, vuelve a abrir el anterior y avisa', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      final String first = switcher.activeSpaceId;
      await addItem(ana.app, 'Huevos');
      final DataSpace broken = await switcher.createSpace(name: 'Roto');
      ana.failingSpaces.add(broken.id);

      expect(await switcher.switchTo(broken.id), isFalse);

      expect(switcher.state.notice, SpaceNotice.failed);
      expect(switcher.state.switching, isFalse);
      expect(switcher.activeSpaceId, first);
      expect((await ana.spaces.active())!.id, first);
      expect(await itemNames(ana.app), <String>['Huevos']);
    });

    test('un espacio desconocido no cambia nada', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      final AppEnvironment before = ana.app;

      expect(await switcher.switchTo('nadie'), isFalse);
      expect(ana.app, same(before));
    });

    test('el nombre del dispositivo pasa a la base nueva', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      await ana.app.sync!.households.renameDevice('Teléfono de Ana');

      await switcher.createAndSwitch();

      expect((await ana.app.sync!.state.readDevice())!.name, 'Teléfono de Ana');
    });
  });

  group('hogares en espacios', () {
    test('crear un hogar en un espacio nuevo deja el anterior local, con sus datos', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      final String first = switcher.activeSpaceId;
      await addItem(ana.app, 'Huevos');

      expect(await switcher.createHouseholdInNewSpace(), isTrue);

      expect(switcher.state.location, AppRoutes.syncInvitation);
      final Household household = (await ana.app.sync!.households.current())!;
      await ana.until(() async => (await ana.spaces.active())!.householdId == household.id);
      expect(await itemNames(ana.app), isEmpty);
      final DataSpace previous = (await ana.spaces.spaces()).firstWhere((DataSpace space) => space.id == first);
      expect(previous.householdId, isNull);
    });

    test('unirse en un espacio nuevo, y con el mismo código otra vez, al espacio de ese hogar', () async {
      final SpacePhone ana = phone('ana');
      final SpacePhone ben = phone('ben');
      await ana.start();
      final HouseholdInvitation invitation = await ana.app.sync!.households.create();
      // Ben no usa la base de siempre: Isar comparte instancias por nombre en
      // todo el proceso.
      await ben.spaces.save(DataSpace.create(id: 'ben-1', name: 'Ben', createdAt: DateTime.utc(2026)));
      final SpaceSwitcher switcher = await ben.start();

      expect(await switcher.joinInSpace(invitation), isTrue);

      final String joined = switcher.activeSpaceId;
      expect(joined, isNot('ben-1'));
      expect(switcher.state.location, AppRoutes.sync);
      expect((await ben.app.sync!.households.current())?.id, invitation.household.id);
      await ben.until(() async => (await ben.spaces.active())!.householdId == invitation.household.id);
      expect(await switcher.spaceOfHousehold(invitation.household.id), joined);

      await switcher.switchTo('ben-1');
      final JoinHouseholdCubit join = JoinHouseholdCubit(households: ben.app.sync!.households, spaces: switcher);
      await join.submit(invitation.encode());

      expect(switcher.activeSpaceId, joined);
      await join.close();
    });

    test('al unirse desde un espacio local, el usuario elige si lleva sus datos', () async {
      final SpacePhone ana = phone('ana');
      final SpacePhone ben = phone('ben');
      await ana.start();
      final HouseholdInvitation invitation = await ana.app.sync!.households.create();
      await ben.spaces.save(DataSpace.create(id: 'ben-1', name: 'Ben', createdAt: DateTime.utc(2026)));
      final SpaceSwitcher switcher = await ben.start();
      await addItem(ben.app, 'Pan');

      final JoinHouseholdCubit join = JoinHouseholdCubit(households: ben.app.sync!.households, spaces: switcher);
      await join.submit(invitation.encode());
      expect(join.state.phase, JoinPhase.choosingData);
      expect(await join.activeSpaceName(), 'Ben');

      join.cancelChoice();
      expect(join.state.phase, JoinPhase.starting);
      await join.submit(invitation.encode());
      await join.chooseData(bringData: true);

      expect(join.state.phase, JoinPhase.joined);
      expect(switcher.activeSpaceId, 'ben-1', reason: 'se une en el mismo espacio, con sus datos');
      expect((await ben.app.sync!.households.current())?.id, invitation.household.id);
      expect(await itemNames(ben.app), <String>['Pan']);
      await join.close();
    });

    test('al unirse sin llevar los datos, el espacio local se queda como estaba', () async {
      final SpacePhone ana = phone('ana');
      final SpacePhone ben = phone('ben');
      await ana.start();
      final HouseholdInvitation invitation = await ana.app.sync!.households.create();
      await ben.spaces.save(DataSpace.create(id: 'ben-1', name: 'Ben', createdAt: DateTime.utc(2026)));
      final SpaceSwitcher switcher = await ben.start();
      await addItem(ben.app, 'Pan');

      final JoinHouseholdCubit join = JoinHouseholdCubit(households: ben.app.sync!.households, spaces: switcher);
      await join.submit(invitation.encode());
      await join.chooseData(bringData: false);
      await join.close();

      expect(switcher.activeSpaceId, isNot('ben-1'));
      expect(await itemNames(ben.app), isEmpty);
      await switcher.switchTo('ben-1');
      expect(await itemNames(ben.app), <String>['Pan']);
      expect(await ben.app.sync!.households.current(), isNull);
    });

    test('desde el espacio de otro hogar, unirse va a un espacio nuevo sin preguntar', () async {
      final SpacePhone ana = phone('ana');
      final SpacePhone ben = phone('ben');
      await ana.start();
      final HouseholdInvitation invitation = await ana.app.sync!.households.create();
      await ben.spaces.save(DataSpace.create(id: 'ben-1', name: 'Ben', createdAt: DateTime.utc(2026)));
      final SpaceSwitcher switcher = await ben.start();
      await ben.app.sync!.households.create();

      final JoinHouseholdCubit join = JoinHouseholdCubit(households: ben.app.sync!.households, spaces: switcher);
      await join.submit(invitation.encode());
      await join.close();

      expect(switcher.activeSpaceId, isNot('ben-1'));
      expect((await ben.app.sync!.households.current())?.id, invitation.household.id);
    });

    test('dos hogares en el mismo teléfono conservan cada uno su clave', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      final String first = switcher.activeSpaceId;
      final HouseholdInvitation home = await ana.app.sync!.households.create();
      await switcher.createHouseholdInNewSpace();
      final HouseholdInvitation office = await ana.app.sync!.households.invitation();

      await switcher.switchTo(first);

      expect(await ana.app.sync!.households.invitation(), home);
      expect(office.household.id, isNot(home.household.id));
    });
  });

  group('SpacesCubit', () {
    test('renombra, crea y borra espacios; el abierto no se borra', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();
      final String first = switcher.activeSpaceId;
      final DataSpace other = await switcher.createSpace(name: 'Oficina');
      await switcher.switchTo(other.id);
      await ana.app.sync!.households.create();
      final String householdId = (await ana.app.sync!.households.current())!.id;
      await ana.until(() async => (await ana.spaces.active())!.householdId == householdId);
      await switcher.switchTo(first);
      final SpacesCubit cubit = SpacesCubit(switcher);

      expect(await cubit.rename(first, 'Casa'), isTrue);
      expect((await switcher.activeSpace()).name, 'Casa');
      expect(await cubit.delete(first), isFalse, reason: 'es el abierto');
      expect(await cubit.delete(other.id), isTrue);

      expect((await ana.spaces.spaces()).map((DataSpace space) => space.id), <String>[first]);
      expect(await ana.device.spaceStorage.databaseNames(), isNot(contains(other.databaseName)));
      expect(ana.secrets.values.keys, isNot(contains(HouseholdService.secretKeyFor(householdId))));

      expect(await cubit.create('Taller'), isTrue);
      expect((await switcher.activeSpace()).name, 'Taller');
      await cubit.close();
    });
  });

  group('SpaceTitleCubit', () {
    test('el inicio usa el nombre del espacio abierto, al día, salvo en el espacio inicial', () async {
      final SpacePhone ana = phone('ana');
      final SpaceSwitcher switcher = await ana.start();

      final SpaceTitleCubit initial = SpaceTitleCubit(switcher);
      await ana.until(() async => (await switcher.activeSpace()).databaseName == SpaceDefaults.legacyDatabaseName);
      await Future<void>.delayed(Duration.zero);
      expect(initial.state, isNull, reason: 'el espacio inicial conserva el título de la app');
      await initial.close();

      final DataSpace office = await switcher.createSpace(name: 'Oficina');
      expect(await switcher.switchTo(office.id), isTrue);
      final SpaceTitleCubit title = SpaceTitleCubit(switcher);
      await expectLater(title.stream, emitsThrough('Oficina'));

      final Future<void> renamed = expectLater(title.stream, emitsThrough('Taller'));
      await switcher.rename(office.id, 'Taller');
      await renamed;
      await title.close();

      expect(SpaceTitleCubit(null).state, isNull, reason: 'sin espacios, el título de la app');
    });
  });
}
