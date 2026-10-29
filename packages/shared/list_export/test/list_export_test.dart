import 'package:list_export/list_export.dart';
import 'package:test/test.dart';

void main() {
  const ExportDocument document = ExportDocument(
    title: 'Lista de compras',
    sections: <ExportSection>[
      ExportSection(
        heading: 'Comida',
        entries: <ExportEntry>[
          ExportEntry(text: 'Huevos', detail: '2 docenas', emphasized: true),
          ExportEntry(text: 'Pan'),
        ],
      ),
      ExportSection(heading: 'Vacía', entries: <ExportEntry>[]),
      ExportSection(entries: <ExportEntry>[ExportEntry(text: 'Pilas', detail: 'AA (Hogar)')]),
    ],
    footer: '28/10/2026',
  );

  group('ExportDocument', () {
    test('igualdad por valor', () {
      ExportDocument build(String detail) => ExportDocument(
            title: 'A',
            sections: <ExportSection>[
              ExportSection(heading: 'H', entries: <ExportEntry>[ExportEntry(text: 'x', detail: detail)]),
            ],
          );

      expect(build('1'), build('1'));
      expect(build('1'), isNot(build('2')));
    });

    test('isEmpty si ninguna sección tiene entradas', () {
      expect(const ExportDocument(title: 'A').isEmpty, isTrue);
      expect(
        const ExportDocument(title: 'A', sections: <ExportSection>[ExportSection(entries: <ExportEntry>[])]).isEmpty,
        isTrue,
      );
      expect(document.isEmpty, isFalse);
    });
  });

  group('WhatsAppFormatter', () {
    test('título y encabezados en negrita, viñetas, resaltado y pie en cursiva', () {
      expect(
        const WhatsAppFormatter().format(document),
        '*Lista de compras*\n'
        '\n'
        '*Comida*\n'
        '- *Huevos* — 2 docenas\n'
        '- Pan\n'
        '\n'
        '- Pilas — AA (Hogar)\n'
        '\n'
        '_28/10/2026_',
      );
    });

    test('un documento vacío es solo el título', () {
      expect(const WhatsAppFormatter().format(const ExportDocument(title: 'Compras')), '*Compras*');
    });
  });

  group('MarkdownFormatter', () {
    test('título, secciones, viñetas, resaltado y pie, terminado en salto de línea', () {
      expect(
        const MarkdownFormatter().format(document),
        '# Lista de compras\n'
        '\n'
        '## Comida\n'
        '\n'
        '- **Huevos** — 2 docenas\n'
        '- Pan\n'
        '\n'
        '- Pilas — AA (Hogar)\n'
        '\n'
        '_28/10/2026_\n',
      );
    });

    test('escapa los caracteres especiales de Markdown', () {
      expect(MarkdownFormatter.escape(r'a*b_c[d]e#f`g\h<i>j|k~l'), r'a\*b\_c\[d\]e\#f\`g\\h\<i\>j\|k\~l');
      expect(
        const MarkdownFormatter().format(const ExportDocument(
          title: '#1',
          sections: <ExportSection>[
            ExportSection(heading: 'A_B', entries: <ExportEntry>[ExportEntry(text: '*x*', detail: '[y]', emphasized: true)]),
          ],
          footer: 'z_',
        )),
        '# \\#1\n\n## A\\_B\n\n- **\\*x\\*** — \\[y\\]\n\n_z\\__\n',
      );
    });
  });
}
