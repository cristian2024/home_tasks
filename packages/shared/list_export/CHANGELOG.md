# Changelog

## 0.1.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.0 - 2026-10-28

### Añadido

- `ExportDocument`, `ExportSection` y `ExportEntry`: modelo neutro de una lista para exportar. Quien exporta lo arma con sus textos ya traducidos.
- `WhatsAppFormatter`: texto para WhatsApp, con título y encabezados en `*negrita*`, viñetas `- ` y las entradas resaltadas en negrita.
- `MarkdownFormatter`: documento Markdown (`#`, `##`, viñetas y `**negrita**`) que escapa los caracteres especiales (`MarkdownFormatter.escape`).
- Los dos omiten las secciones sin entradas y separan el detalle de cada entrada con ` — `.
