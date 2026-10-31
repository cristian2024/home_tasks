# app_shortcuts_quick_actions

Adaptador de `core_app_shortcuts` con [quick_actions](https://pub.dev/packages/quick_actions): los accesos rápidos que aparecen al mantener pulsado el icono de la app (`ShortcutManager` en Android, `UIApplicationShortcutItem` en iOS).

## Uso

Quien compone la app solo lo elige:

```dart
const List<DependencyModule> appAdapters = <DependencyModule>[
  // ...
  QuickActionsShortcuts(),
];
```

Al registrarse inicializa quick_actions y registra `AppShortcutService` en el `ServiceLocator`. La app pide el servicio al locator. Con `locator.reset()` deja de entregar pulsaciones; los accesos siguen en el lanzador hasta que se publiquen otros.

## Configuración nativa

- **Iconos:** `AppShortcut.iconName` es el nombre de un recurso de la app: un drawable en `android/app/src/main/res/drawable` y una imagen en `ios/Runner/Assets.xcassets`. Sin él, el acceso sale sin icono.
- **Límite:** iOS muestra como mucho 4 accesos dinámicos y cada lanzador Android tiene el suyo (normalmente 4 o 5). La app decide cuántos publica.

## Tests

Pasa `appShortcutServiceContract` con un `QuickActionsPlatform` simulado:

```sh
flutter test
```
