# Changelog

## 0.1.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.0 - 2026-10-28

### Añadido

- `NativeShare`: `DependencyModule` que registra `NativeShareService` como `ShareService` de `core_share`. Quien compone la app solo lo elige.
- `NativeShareService`:
  - comparte texto y archivos con la hoja de compartir del sistema (share_plus);
  - abre WhatsApp con `whatsapp://send` (url_launcher) y devuelve `false` si no está instalado;
  - guarda archivos con el diálogo de guardar del sistema (file_picker).
- Pasa la batería `shareServiceContract`.
