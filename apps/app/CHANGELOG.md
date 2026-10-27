# Changelog

## 1.3.0+4 - 2026-10-26

### Añadido

- Vista de accesos rápidos en el inicio: los plugins activos en una grilla (icono y título, 4 columnas en móvil), con «Añadir» siempre al final para abrir el catálogo. Un botón de la barra superior alterna entre lista y grilla.
- Al tocar un acceso rápido se abre la tarjeta del plugin en una hoja inferior, con todas sus acciones. Un plugin que no pudo iniciarse se ve con error y al tocarlo se reintenta.
- La vista elegida se guarda (`app.home_layout`) aparte de los plugins: cambiarla no modifica cuáles están activos ni su orden.

### Cambiado

- Usa design_system 0.1.1 (`AppShortcutTile`, `AppShortcutGrid`).

## 1.2.0+3 - 2026-10-24

### Cambiado

- La app define todos los textos de core_ui e item_tracker en `assets/i18n/<paquete>/<idioma>.json`, no solo los que cambian. Los inyecta con `injectTranslations` de core_ui 0.1.1.

### Interno

- Un test falla si a la app le falta un texto de un paquete, le sobra uno o cambia sus parámetros.

## 1.1.0+2 - 2026-10-24

### Añadido

- Los textos de core_ui e item_tracker se pueden reemplazar desde `assets/i18n/<paquete>/<idioma>.json`, solo con las claves que cambian (por ahora vacíos). Si un archivo no es válido se ignora y el paquete usa sus propios textos.

### Cambiado

- item_tracker 1.1.0.

### Interno

- Tipos explícitos en toda la app.
- Un test comprueba que cada clave reemplazada existe en el paquete, con el mismo tipo y los mismos parámetros.

## 1.0.0+1 - 2026-10-22

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- Pantalla de inicio con los módulos activos y catálogo para activarlos o desactivarlos.
- Las rutas de un módulo desactivado se bloquean.
- Configuración con tema, idioma y módulos, guardados en el dispositivo.
- Plugin item_tracker con persistencia local en Isar.
