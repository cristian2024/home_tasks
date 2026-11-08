# task_list_example

App anfitriona mínima del plugin de lista de tareas, para probarlo en un dispositivo real. Arranca igual que `apps/app`:

1. Registra los servicios base (`EventBus`, `IdGenerator`, `Clock`).
2. Registra el adaptador que elige: `IsarStorage(features: <IsarFeature>[TaskListIsar()])`, con su propio archivo de base de datos, separado del de `apps/app`.
3. Inyecta todos los textos desde `assets/i18n/`.
4. Inicializa el plugin.

«Cargar datos de ejemplo» crea una tarea de cada grupo (atrasada, hoy, próxima y sin fecha), una que se repite (limpiar la nevera, cada 10 a 14 días) y una hecha. Las fechas se calculan desde hoy.

## Configuración nativa

- Android: minSdk 24 y compileSdk 37.
- iOS: `isar_community_flutter_libs` todavía no admite Swift Package Manager, así que Flutter genera un `Podfile` solo para él en la primera compilación de iOS; se versionan `Podfile` y `Podfile.lock`.

```sh
flutter run -d <id>
```
