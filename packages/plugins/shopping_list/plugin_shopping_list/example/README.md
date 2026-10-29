# shopping_list_example

App anfitriona mínima del plugin de lista de compras, para probarlo en un dispositivo real. Arranca igual que `apps/app`:

1. Registra los servicios base (`EventBus`, `IdGenerator`, `Clock`).
2. Registra los adaptadores que elige: `IsarStorage(features: <IsarFeature>[ShoppingListIsar()])` (su propio archivo de base de datos, separado del de `apps/app`) y `NativeShare()` para exportar.
3. Inyecta todos los textos desde `assets/i18n/`.
4. Inicializa el plugin.

«Cargar datos de ejemplo» crea items con distintas urgencias, varias categorías y una compra que se repite (huevos, cada 8 a 15 días).

## Configuración nativa

- Android: minSdk 24 y compileSdk 37. Para que «Enviar por WhatsApp» detecte la app, el `AndroidManifest.xml` declara el esquema `whatsapp` en `<queries>`.
- iOS: `Info.plist` declara `whatsapp` en `LSApplicationQueriesSchemes`. `isar_community_flutter_libs` todavía no admite Swift Package Manager, así que Flutter genera un `Podfile` solo para él en la primera compilación de iOS; se versionan `Podfile` y `Podfile.lock`.

```sh
flutter run -d <id>
```
