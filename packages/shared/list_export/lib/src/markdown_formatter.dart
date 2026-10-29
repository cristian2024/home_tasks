import 'export_document.dart';
import 'export_formatter.dart';

/// Documento Markdown: título `#`, secciones `##`, entradas como viñetas
/// `- ` y las resaltadas en `**negrita**`. Escapa los caracteres con
/// significado en Markdown y termina en salto de línea.
class MarkdownFormatter implements ExportFormatter {
  const MarkdownFormatter();

  static final RegExp _special = RegExp(r'([\\`*_\[\]<>#|~])');

  @override
  String format(ExportDocument document) {
    final List<String> blocks = <String>['# ${escape(document.title)}'];
    for (final ExportSection section in document.sections) {
      if (section.entries.isEmpty) {
        continue;
      }
      if (section.heading != null) {
        blocks.add('## ${escape(section.heading!)}');
      }
      blocks.add(section.entries.map(_entry).join('\n'));
    }
    if (document.footer != null) {
      blocks.add('_${escape(document.footer!)}_');
    }
    return '${blocks.join('\n\n')}\n';
  }

  /// [text] con los caracteres especiales de Markdown escapados.
  static String escape(String text) => text.replaceAllMapped(_special, (Match match) => '\\${match[1]}');

  String _entry(ExportEntry entry) {
    final String text = entry.emphasized ? '**${escape(entry.text)}**' : escape(entry.text);
    return entry.detail == null ? '- $text' : '- $text$exportDetailSeparator${escape(entry.detail!)}';
  }
}
