import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_app_shortcuts/testing.dart';
import 'package:test/test.dart';

void main() {
  appShortcutServiceContract('FakeAppShortcutService', create: () {
    final FakeAppShortcutService fake = FakeAppShortcutService();
    return AppShortcutServiceHarness(service: fake, published: () => fake.shortcuts, select: fake.simulateSelection);
  });

  group('AppShortcut', () {
    test('rechaza id, título o icono en blanco', () {
      expect(() => AppShortcut(id: ' ', title: 'Compras'), throwsArgumentError);
      expect(() => AppShortcut(id: 'shopping_list', title: ''), throwsArgumentError);
      expect(() => AppShortcut(id: 'shopping_list', title: 'Compras', iconName: ' '), throwsArgumentError);
    });

    test('compara por valor', () {
      expect(
        AppShortcut(id: 'shopping_list', title: 'Compras', iconName: 'cart'),
        AppShortcut(id: 'shopping_list', title: 'Compras', iconName: 'cart'),
      );
      expect(AppShortcut(id: 'shopping_list', title: 'Compras'), isNot(AppShortcut(id: 'shopping_list', title: 'Lista')));
    });
  });

  group('FakeAppShortcutService', () {
    test('cuenta las publicaciones y se libera', () async {
      final FakeAppShortcutService fake = FakeAppShortcutService();

      await fake.setShortcuts(<AppShortcut>[AppShortcut(id: 'a', title: 'A')]);
      await fake.clear();
      await fake.dispose();

      expect(fake.updates, 2);
      expect(fake.shortcuts, isEmpty);
    });
  });
}
