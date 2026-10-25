# Changelog

## 1.1.0 - 2026-10-24

### Añadido

- La app puede reemplazar los textos del plugin: `registerLocalization()` registra en `LocalizationCoordinator` cómo aplicar los reemplazos. Las claves que la app no reemplaza siguen saliendo de los JSON del plugin.

### Interno

- Tipos explícitos en todo el paquete y en su app de ejemplo.
- Las dependencias de otros paquetes del workspace se declaran con `any`.

## 1.0.0 - 2026-10-22

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- Registro de objetos con identificadores de cámara (QR y códigos de barras), NFC o entrada manual.
- Listado, detalle y edición de objetos.
- Añadir y quitar identificadores desde el objeto.
- Contenedores: objetos dentro de objetos, con un máximo de niveles configurable (`ITEM_TRACKER_MAX_DEPTH`).
