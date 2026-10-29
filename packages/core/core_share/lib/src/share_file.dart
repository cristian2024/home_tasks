import 'package:equatable/equatable.dart';

/// Archivo de texto que se comparte o se guarda.
class ShareFile extends Equatable {
  /// Lanza [ArgumentError] si [fileName] está vacío, contiene `/` o `\`, o no
  /// tiene extensión.
  ShareFile({required this.fileName, required this.content, required this.mimeType}) {
    if (!_validName.hasMatch(fileName)) {
      throw ArgumentError.value(fileName, 'fileName', 'Debe tener nombre y extensión, sin separadores de ruta');
    }
  }

  /// Archivo Markdown `<baseName>.md`.
  ShareFile.markdown({required String baseName, required String content})
      : this(fileName: '$baseName.md', content: content, mimeType: markdownMimeType);

  static const String markdownMimeType = 'text/markdown';

  static final RegExp _validName = RegExp(r'^[^/\\]*[^/\\.][^/\\]*\.[^/\\.]+$');

  final String fileName;
  final String content;
  final String mimeType;

  @override
  List<Object?> get props => <Object?>[fileName, content, mimeType];
}
