# plugin_task_list

Plugin de lista de tareas (ID `task_list`, rutas bajo `/task-list`). Implementa `HomePlugin` y `HomePluginEntryRoute`, así que desde la grilla del inicio se abre directamente la lista.

## Qué hace

- **Tareas** con título, urgencia, categorías y, o una fecha límite, o una recurrencia aproximada («cada 10 a 14 días»). Se crean, editan, marcan como hechas y borran.
- **Completar:** la tarea queda marcada en su sitio 5 s, con un aviso para deshacer. Después pasa a «Hechas»; si se repite, queda «En espera» hasta que vuelva a tocar.
- **Lista** agrupada por fecha (atrasadas, hoy, próximas, sin fecha) o por categoría, y filtrable por categorías, urgencia y estado (panel plegable).
- **Fecha límite** desde una hoja con atajos (hoy, mañana, sábado, en una semana), escrita a mano o en el calendario. Se guarda como día de calendario.
- **Hechas:** lista aparte, desde la que una tarea vuelve a pendiente. «Borrar hechas», en el menú ⋮, pide confirmación.
- **Categorías:** cinco por defecto (Limpieza, Cocina, Jardín, Pagos y Reparaciones), que se pueden crear, renombrar, reordenar y borrar.
- **Tarjeta de inicio** con lo que hay por hacer y lo atrasado (o lo urgente, si nada está atrasado).

## Integración

El plugin pide sus dependencias al `ServiceLocator`:
- `TaskListRepository` (obligatorio): lo registra el adaptador de almacenamiento que elige la app, p. ej. `TaskListIsar`.
- `IdGenerator` y `Clock` (opcionales): si faltan, usa los suyos.

La app registra el plugin con `TaskListPlugin(locator: locator)..registerLocalization()` e inyecta sus textos desde `assets/i18n/task_list/`.

## Accesibilidad

- Cada casilla dice qué hace («Marcar «Sacar la basura» como hecha») y la línea de datos se lee con la fecha completa.
- Se anuncian la carga, los resultados al filtrar, la fecha elegida y los caracteres que quedan en el título.
- Con un error de validación, el foco vuelve al título.
- Probado con las guías de Flutter (tamaño táctil, etiquetas, contraste) y con el texto al 200 %.

## Tests

- Casos de uso al 100 % (`test/domain/`).
- Pantallas con el plugin real y repositorio en memoria (`test/presentation/`).

## App de ejemplo

`example/` prueba el plugin en un dispositivo real. Consulta su README.
