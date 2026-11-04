# Changelog

## 0.1.0 - 2026-10-31

### Añadido

- `QuickActionsShortcuts`: `DependencyModule` que registra `AppShortcutService` con quick_actions, ya inicializado para recibir pulsaciones (también la del arranque en frío), y lo libera con el locator.
- `QuickActionsShortcutService`: accesos dinámicos del lanzador (`ShortcutManager` en Android, `UIApplicationShortcutItem` en iOS). `AppShortcut.iconName` es el nombre del recurso nativo del icono. Pasa `appShortcutServiceContract`.
