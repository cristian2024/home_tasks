# home_tasks

App de utilidades del hogar hecha con Flutter y organizada por plugins: cada funcionalidad (seguimiento de objetos, lista de compras…) es un plugin que la app instala y que el usuario puede activar o desactivar. El diseño completo está en [`specs/app_spec.md`](specs/app_spec.md).

## Estructura

| Carpeta | Contenido |
| :--- | :--- |
| `apps/app` | La app. Elige los adaptadores y los plugins, e inyecta todos los textos. |
| `packages/core/` | Contratos y servicios base: plugins (`core_contracts`), inyección de dependencias (`core_di`), eventos entre plugins (`core_events`), hardware (`core_hardware`) y compartir (`core_share`). |
| `packages/shared/` | Paquetes comunes en Dart puro o de UI base: `core_ui`, `core_utils`, `urgency`, `recurrence`, `list_export`. |
| `packages/design_system` | Tokens, temas y componentes accesibles. |
| `packages/contracts/` | Lo que un plugin expone a otros (eventos y capacidades), en Dart puro. |
| `packages/adapters/` | Tecnologías reemplazables: `storage_isar` (base de datos) y `share_native` (compartir). |
| `packages/plugins/<funcionalidad>/` | Una funcionalidad con datos, en tres paquetes: `<funcionalidad>_domain` (Dart puro), `plugin_<funcionalidad>` (casos de uso, UI y su app de `example/`) y su adaptador (p. ej. `item_tracker_isar`). |

Los paquetes dependen de contratos, no de implementaciones. Cambiar de tecnología (p. ej. de Isar a SQLite) solo requiere adaptadores nuevos que pasen la batería de tests de contrato, y cambiar la lista de adaptadores de la app.

## Requisitos

- Flutter 3.47.7 (la versión de la CI) o superior a 3.27.
- Melos 8: `dart pub global activate melos`.

## Primeros pasos

```sh
melos bs        # resuelve el workspace y genera el código (Isar y Slang)
```

El código generado (`*.g.dart`) no se versiona. Después de cambiar de rama o de tocar un modelo Isar o un JSON de traducciones, ejecuta `melos run gen`.

## Comandos

| Comando | Qué hace |
| :--- | :--- |
| `melos run verify` | Verificación completa: análisis, reglas de arquitectura y todas las pruebas. |
| `melos run analyze` | Análisis estático de todo el workspace. |
| `melos run verify:arch` | Reglas de importación entre paquetes (§5.2 de la spec). |
| `melos run test` | Pruebas de todos los paquetes y del tooling. |
| `melos run test:changed` | Pruebas de los paquetes que cambian respecto a `origin/main` y de los que dependen de ellos. |
| `melos run gen` | Genera el código de Isar y de Slang. |
| `melos run build:apk` | APK de release de `apps/app`. |

## Antes de abrir un PR

1. `melos run verify` debe terminar sin errores (o, para ir más rápido, `melos run analyze`, `melos run verify:arch` y `melos run test:changed`). La CI (`.github/workflows/ci.yml`) bloquea el PR si falla:
   - en un PR, analiza todo el workspace, comprueba las reglas de arquitectura y prueba los paquetes cambiados y los que dependen de ellos. Si cambia algo fuera de `packages/` y `apps/` (salvo documentación), prueba todo;
   - en `main`, después de cada merge, ejecuta `melos run verify` completo.
2. La cobertura debe quedar al 100 % en los casos de uso, en los paquetes `<funcionalidad>_domain` y en los mappers de los adaptadores (`flutter test --coverage` en el paquete).
3. Una rama cambia un solo proyecto: un paquete, una app o la raíz. Los paquetes de una misma funcionalidad (`packages/plugins/<funcionalidad>/`) cuentan como uno. Excepciones: un cambio incompatible actualiza la restricción en todos los dependientes, y una clave de traducción nueva se añade en la misma rama a todos los consumidores (`apps/app` y los ejemplos).
4. Cada paquete que cambia sube su `version:` (SemVer) y añade una entrada a su `CHANGELOG.md`.

Las convenciones de código y las trampas conocidas están en [`CLAUDE.md`](CLAUDE.md).
