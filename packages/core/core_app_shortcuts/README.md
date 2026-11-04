# core_app_shortcuts

Contrato para los accesos rápidos del icono de la app: los que aparecen al mantener pulsado el icono en el lanzador de Android o iOS. Es Dart puro; la implementación la elige quien compone (p. ej. `app_shortcuts_quick_actions`).

## Contenido

- **`AppShortcutService`**:
  - `setShortcuts(shortcuts)`: reemplaza los accesos, en ese orden. Rechaza ids repetidos con `ArgumentError`, sin cambiar nada.
  - `clear()`: quita todos.
  - `selections`: `id` de cada acceso pulsado. Una pulsación sin nadie escuchando (al abrir la app en frío desde un acceso) se guarda y se entrega una sola vez, al primer oyente; si hay varias, solo la última.
- **`AppShortcut`**: `id`, `title` (ya traducido) e `iconName` opcional, el nombre del recurso nativo (Android `res/drawable`, iOS `Assets.xcassets`).
- **`ShortcutSelectionBuffer`** y **`checkUniqueShortcutIds`**: ayudan a las implementaciones a cumplir el contrato.

## Uso

```dart
final AppShortcutService shortcuts = locator.get<AppShortcutService>();
await shortcuts.setShortcuts(<AppShortcut>[
  AppShortcut(id: 'shopping_list', title: 'Compras', iconName: 'shortcut_shopping_list'),
]);
shortcuts.selections.listen((String id) => router.go(routeOf(id)));
```

## Tests

`package:core_app_shortcuts/testing.dart` trae los tests de contrato `appShortcutServiceContract`, que toda implementación debe pasar con su lanzador simulado (`AppShortcutServiceHarness`), y `FakeAppShortcutService`, que guarda los accesos publicados y simula pulsaciones con `simulateSelection`.

```sh
dart test
```
