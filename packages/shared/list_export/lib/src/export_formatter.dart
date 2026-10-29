import 'export_document.dart';

/// Convierte un [ExportDocument] en texto. Las secciones sin entradas no se
/// escriben.
abstract interface class ExportFormatter {
  String format(ExportDocument document);
}

/// Separador entre el texto de una entrada y su detalle.
const String exportDetailSeparator = ' — ';
