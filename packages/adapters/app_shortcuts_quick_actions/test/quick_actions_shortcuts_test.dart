import 'package:app_shortcuts_quick_actions/app_shortcuts_quick_actions.dart';
import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_app_shortcuts/testing.dart';
import 'package:core_di/core_di.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:quick_actions_platform_interface/quick_actions_platform_interface.dart';

/// Lanzador simulado: guarda los accesos y el manejador de pulsaciones.
class _FakeQuickActionsPlatform extends QuickActionsPlatform with MockPlatformInterfaceMixin {
  List<ShortcutItem> items = <ShortcutItem>[];
  QuickActionHandler? handler;
  int clears = 0;

  @override
  Future<void> initialize(QuickActionHandler handler) async => this.handler = handler;

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async => this.items = items;

  @override
  Future<void> clearShortcutItems() async {
    clears++;
    items = <ShortcutItem>[];
  }

  void select(String type) => handler!(type);
}

void main() {
  late _FakeQuickActionsPlatform platform;

  setUp(() {
    platform = _FakeQuickActionsPlatform();
    QuickActionsPlatform.instance = platform;
  });

  appShortcutServiceContract('QuickActionsShortcutService', create: () async {
    final QuickActionsShortcutService service = QuickActionsShortcutService();
    await service.initialize();
    return AppShortcutServiceHarness(
      service: service,
      published: () => <AppShortcut>[
        for (final ShortcutItem item in platform.items)
          AppShortcut(id: item.type, title: item.localizedTitle, iconName: item.icon),
      ],
      select: platform.select,
    );
  });

  test('una lista vacía quita los accesos del lanzador', () async {
    final QuickActionsShortcutService service = QuickActionsShortcutService();
    await service.initialize();

    await service.setShortcuts(<AppShortcut>[]);

    expect(platform.clears, 1);
  });

  test('tras dispose ignora las pulsaciones', () async {
    final QuickActionsShortcutService service = QuickActionsShortcutService();
    await service.initialize();

    await service.dispose();

    expect(() => platform.select('shopping_list'), returnsNormally);
  });

  test('QuickActionsShortcuts registra el servicio inicializado y lo libera con el locator', () async {
    final ServiceLocator locator = ServiceLocator();

    await const QuickActionsShortcuts().register(locator);

    expect(locator.get<AppShortcutService>(), isA<QuickActionsShortcutService>());
    expect(platform.handler, isNotNull);
    await locator.reset();
    expect(() => platform.select('shopping_list'), returnsNormally);
  });
}
