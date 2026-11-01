import 'package:core_app_shortcuts/core_app_shortcuts.dart';
import 'package:core_di/core_di.dart';
import 'package:quick_actions/quick_actions.dart';

/// Registra [QuickActionsShortcutService] como `AppShortcutService`, ya
/// inicializado para recibir pulsaciones, y lo libera con el locator. Quien
/// compone la app solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[QuickActionsShortcuts()]
/// ```
///
/// Los iconos son recursos nativos de la app (Android `res/drawable`, iOS
/// `Assets.xcassets`) con el nombre de `AppShortcut.iconName`.
class QuickActionsShortcuts implements DependencyModule {
  const QuickActionsShortcuts();

  @override
  Future<void> register(ServiceLocator services) async {
    final QuickActionsShortcutService service = QuickActionsShortcutService();
    await service.initialize();
    services.registerSingleton<AppShortcutService>(service, dispose: (_) => service.dispose());
  }
}

/// [AppShortcutService] con los accesos dinámicos del lanzador
/// (`ShortcutManager` en Android, `UIApplicationShortcutItem` en iOS).
class QuickActionsShortcutService implements AppShortcutService {
  /// [quickActions] permite usar otra plataforma en los tests.
  QuickActionsShortcutService({QuickActions quickActions = const QuickActions()}) : _quickActions = quickActions;

  final QuickActions _quickActions;
  final ShortcutSelectionBuffer _selections = ShortcutSelectionBuffer();
  bool _disposed = false;

  /// Empieza a recibir pulsaciones, también la que abrió la app en frío.
  /// Se llama una vez, antes de usar el servicio.
  Future<void> initialize() => _quickActions.initialize(_onSelected);

  @override
  Future<void> setShortcuts(List<AppShortcut> shortcuts) async {
    checkUniqueShortcutIds(shortcuts);
    if (shortcuts.isEmpty) {
      return clear();
    }
    await _quickActions.setShortcutItems(<ShortcutItem>[
      for (final AppShortcut shortcut in shortcuts)
        ShortcutItem(type: shortcut.id, localizedTitle: shortcut.title, icon: shortcut.iconName),
    ]);
  }

  @override
  Future<void> clear() => _quickActions.clearShortcutItems();

  @override
  Stream<String> get selections => _selections.stream;

  /// Deja de entregar pulsaciones. Los accesos siguen en el lanzador.
  Future<void> dispose() {
    _disposed = true;
    return _selections.close();
  }

  void _onSelected(String type) {
    if (!_disposed) {
      _selections.add(type);
    }
  }
}
