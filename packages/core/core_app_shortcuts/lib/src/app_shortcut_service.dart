import 'app_shortcut.dart';

/// Accesos rápidos del icono de la app. Toda implementación pasa
/// `appShortcutServiceContract` (`package:core_app_shortcuts/testing.dart`).
abstract interface class AppShortcutService {
  /// Reemplaza los accesos que muestra el lanzador por [shortcuts], en ese
  /// orden. Lanza [ArgumentError], sin cambiar nada, si dos tienen el mismo
  /// `id`.
  Future<void> setShortcuts(List<AppShortcut> shortcuts);

  /// Quita todos los accesos.
  Future<void> clear();

  /// `id` de cada acceso que pulsa el usuario. Si se pulsa sin nadie
  /// escuchando (p. ej. al abrir la app en frío), se guarda la última
  /// pulsación y se entrega una sola vez, al primer oyente.
  Stream<String> get selections;
}

/// Comprueba que [shortcuts] no repite ningún `id`. Lanza [ArgumentError] si
/// lo hace. Para las implementaciones de [AppShortcutService.setShortcuts].
void checkUniqueShortcutIds(List<AppShortcut> shortcuts) {
  final Set<String> ids = <String>{};
  for (final AppShortcut shortcut in shortcuts) {
    if (!ids.add(shortcut.id)) {
      throw ArgumentError.value(shortcut.id, 'shortcuts', 'Acceso repetido');
    }
  }
}
