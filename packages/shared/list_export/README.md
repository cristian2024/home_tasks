# list_export

Exporta listas (compras, tareas…) como texto para WhatsApp o Markdown. Dart puro.

## Contenido

- **Modelo neutro**, que arma quien exporta con sus textos ya traducidos:
  - `ExportDocument`: título, secciones y pie opcional (p. ej. la fecha).
  - `ExportSection`: encabezado opcional (p. ej. una categoría) y entradas.
  - `ExportEntry`: texto, detalle opcional (p. ej. la cantidad) y `emphasized` para resaltar lo urgente.
- **Formateadores** (`ExportFormatter.format(document)`):
  - `WhatsAppFormatter`: título y encabezados en `*negrita*` y viñetas `- `. WhatsApp no permite escapar sus marcas, así que el texto va tal cual.
  - `MarkdownFormatter`: título `#`, secciones `##` y viñetas `- `, con lo resaltado en `**negrita**`. Escapa los caracteres especiales (`MarkdownFormatter.escape`).

Las secciones sin entradas no se escriben.

## Uso

```dart
const ExportDocument document = ExportDocument(
  title: 'Lista de compras',
  sections: <ExportSection>[
    ExportSection(heading: 'Comida', entries: <ExportEntry>[
      ExportEntry(text: 'Huevos', detail: '12', emphasized: true),
    ]),
  ],
);
final String text = const WhatsAppFormatter().format(document);
```

El texto se comparte con `ShareService` de `core_share`.

## Tests

```sh
dart test
```

Cobertura: 100 %.
