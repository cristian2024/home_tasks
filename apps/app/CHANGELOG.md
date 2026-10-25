# Changelog

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
