# Changelog

## 0.1.0 - 2026-10-31

### Añadido

- `AppShortcutService`: contrato para los accesos rápidos del icono de la app. `setShortcuts` reemplaza los accesos en orden (rechaza ids repetidos), `clear` los quita y `selections` emite el `id` de cada acceso pulsado. Una pulsación sin oyente (arranque en frío) se guarda y se entrega una sola vez, al primer oyente.
- `AppShortcut`: acceso con `id`, `title` ya traducido e `iconName` opcional (recurso nativo).
- `ShortcutSelectionBuffer` y `checkUniqueShortcutIds`, para que las implementaciones cumplan esas reglas sin repetirlas.
- `package:core_app_shortcuts/testing.dart`: tests de contrato `appShortcutServiceContract` y `FakeAppShortcutService`, que guarda los accesos y simula pulsaciones.
