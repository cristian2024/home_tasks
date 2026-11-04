/// Contrato para los accesos rápidos del icono de la app: los que aparecen al
/// mantener pulsado el icono en el lanzador de Android o iOS. La app pide
/// [AppShortcutService] al `ServiceLocator`; la implementación la elige quien
/// compone (p. ej. `app_shortcuts_quick_actions`).
library;

export 'src/app_shortcut.dart';
export 'src/app_shortcut_service.dart';
export 'src/shortcut_selection_buffer.dart';
