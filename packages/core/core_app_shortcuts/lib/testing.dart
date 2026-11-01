/// Doble de prueba y tests de contrato de `core_app_shortcuts`.
library;

import 'core_app_shortcuts.dart';

export 'src/testing/app_shortcut_service_contract.dart';

/// [AppShortcutService] sin lanzador: guarda los accesos publicados y simula
/// pulsaciones. Cumple `appShortcutServiceContract`.
class FakeAppShortcutService implements AppShortcutService {
  final ShortcutSelectionBuffer _selections = ShortcutSelectionBuffer();
  List<AppShortcut> _shortcuts = const <AppShortcut>[];

  /// Accesos que mostraría el lanzador.
  List<AppShortcut> get shortcuts => _shortcuts;

  /// Veces que se publicaron accesos (`setShortcuts` o `clear`).
  int updates = 0;

  @override
  Future<void> setShortcuts(List<AppShortcut> shortcuts) async {
    checkUniqueShortcutIds(shortcuts);
    _shortcuts = List<AppShortcut>.unmodifiable(shortcuts);
    updates++;
  }

  @override
  Future<void> clear() => setShortcuts(const <AppShortcut>[]);

  @override
  Stream<String> get selections => _selections.stream;

  /// Simula que el usuario pulsa el acceso [id] en el lanzador.
  void simulateSelection(String id) => _selections.add(id);

  Future<void> dispose() => _selections.close();
}
