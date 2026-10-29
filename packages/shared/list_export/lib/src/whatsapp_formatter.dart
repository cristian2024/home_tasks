import 'export_document.dart';
import 'export_formatter.dart';

/// Texto para WhatsApp: título y encabezados en `*negrita*`, entradas como
/// viñetas `- ` y las resaltadas en negrita.
///
/// WhatsApp no tiene forma de escapar sus marcas (`*`, `_`, `~`), así que el
/// texto va tal cual.
class WhatsAppFormatter implements ExportFormatter {
  const WhatsAppFormatter();

  @override
  String format(ExportDocument document) {
    final List<String> blocks = <String>['*${document.title}*'];
    for (final ExportSection section in document.sections) {
      if (section.entries.isEmpty) {
        continue;
      }
      blocks.add(<String>[
        if (section.heading != null) '*${section.heading}*',
        for (final ExportEntry entry in section.entries) _entry(entry),
      ].join('\n'));
    }
    if (document.footer != null) {
      blocks.add('_${document.footer}_');
    }
    return blocks.join('\n\n');
  }

  String _entry(ExportEntry entry) {
    final String text = entry.emphasized ? '*${entry.text}*' : entry.text;
    return entry.detail == null ? '- $text' : '- $text$exportDetailSeparator${entry.detail}';
  }
}
