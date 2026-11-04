import 'dart:async';

import 'package:test/test.dart';

import '../app_shortcut.dart';
import '../app_shortcut_service.dart';

/// Una implementación de [AppShortcutService] con su lanzador simulado.
class AppShortcutServiceHarness {
  AppShortcutServiceHarness({required this.service, required this.published, required this.select});

  final AppShortcutService service;

  /// Accesos que muestra ahora el lanzador simulado.
  final FutureOr<List<AppShortcut>> Function() published;

  /// Simula que el usuario pulsa el acceso [id] en el lanzador.
  final FutureOr<void> Function(String id) select;
}

typedef AppShortcutServiceFactory = FutureOr<AppShortcutServiceHarness> Function();

/// Tests de contrato de [AppShortcutService]. Toda implementación debe
/// pasarlos, con el lanzador simulado que devuelve [create].
///
/// ```dart
/// appShortcutServiceContract('Fake', create: () {
///   final FakeAppShortcutService fake = FakeAppShortcutService();
///   return AppShortcutServiceHarness(
///     service: fake,
///     published: () => fake.shortcuts,
///     select: fake.simulateSelection,
///   );
/// });
/// ```
void appShortcutServiceContract(String implementation, {required AppShortcutServiceFactory create}) {
  group('AppShortcutService ($implementation)', () {
    final AppShortcut objects = AppShortcut(id: 'item_tracker', title: 'Objetos', iconName: 'shortcut_items');
    final AppShortcut shopping = AppShortcut(id: 'shopping_list', title: 'Compras');

    test('empieza sin accesos', () async {
      final AppShortcutServiceHarness harness = await create();

      expect(await harness.published(), isEmpty);
    });

    test('setShortcuts publica los accesos en orden', () async {
      final AppShortcutServiceHarness harness = await create();

      await harness.service.setShortcuts(<AppShortcut>[shopping, objects]);

      expect(await harness.published(), <AppShortcut>[shopping, objects]);
    });

    test('setShortcuts reemplaza los accesos anteriores', () async {
      final AppShortcutServiceHarness harness = await create();

      await harness.service.setShortcuts(<AppShortcut>[shopping, objects]);
      await harness.service.setShortcuts(<AppShortcut>[objects]);

      expect(await harness.published(), <AppShortcut>[objects]);
    });

    test('setShortcuts rechaza ids repetidos sin cambiar nada', () async {
      final AppShortcutServiceHarness harness = await create();
      await harness.service.setShortcuts(<AppShortcut>[objects]);

      await expectLater(
        harness.service.setShortcuts(<AppShortcut>[shopping, AppShortcut(id: 'shopping_list', title: 'Otra')]),
        throwsArgumentError,
      );
      expect(await harness.published(), <AppShortcut>[objects]);
    });

    test('clear quita todos los accesos', () async {
      final AppShortcutServiceHarness harness = await create();
      await harness.service.setShortcuts(<AppShortcut>[shopping, objects]);

      await harness.service.clear();

      expect(await harness.published(), isEmpty);
    });

    test('selections emite cada pulsación', () async {
      final AppShortcutServiceHarness harness = await create();
      await harness.service.setShortcuts(<AppShortcut>[shopping, objects]);
      final List<String> selected = <String>[];
      final StreamSubscription<String> subscription = harness.service.selections.listen(selected.add);

      await harness.select('shopping_list');
      await harness.select('item_tracker');
      await pumpEventQueue();

      expect(selected, <String>['shopping_list', 'item_tracker']);
      await subscription.cancel();
    });

    test('una pulsación sin oyente llega una sola vez, al primero', () async {
      final AppShortcutServiceHarness harness = await create();
      await harness.select('shopping_list');
      final List<String> first = <String>[];
      final List<String> second = <String>[];

      final StreamSubscription<String> firstSubscription = harness.service.selections.listen(first.add);
      await pumpEventQueue();
      final StreamSubscription<String> secondSubscription = harness.service.selections.listen(second.add);
      await pumpEventQueue();

      expect(first, <String>['shopping_list']);
      expect(second, isEmpty);
      await firstSubscription.cancel();
      await secondSubscription.cancel();
    });

    test('de varias pulsaciones sin oyente solo se guarda la última', () async {
      final AppShortcutServiceHarness harness = await create();
      await harness.select('shopping_list');
      await harness.select('item_tracker');
      final List<String> selected = <String>[];

      final StreamSubscription<String> subscription = harness.service.selections.listen(selected.add);
      await pumpEventQueue();

      expect(selected, <String>['item_tracker']);
      await subscription.cancel();
    });
  });
}
