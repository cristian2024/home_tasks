import 'share_file.dart';

/// Resultado de [ShareService.saveFile].
enum SaveFileResult {
  saved,

  /// El usuario cerró el diálogo sin guardar.
  cancelled,
}

/// Saca contenido de la app. Toda implementación pasa `shareServiceContract`
/// (`package:core_share/testing.dart`).
abstract interface class ShareService {
  /// Abre la hoja de compartir del sistema con [text]. Lanza [ArgumentError]
  /// si [text] está en blanco.
  Future<void> shareText(String text, {String? subject});

  /// Abre WhatsApp con [text] listo para enviar. Devuelve `false` si WhatsApp
  /// no está instalado. Lanza [ArgumentError] si [text] está en blanco.
  Future<bool> openWhatsApp(String text);

  /// Abre la hoja de compartir del sistema con [file].
  Future<void> shareFile(ShareFile file, {String? subject});

  /// Abre el diálogo del sistema para elegir dónde guardar [file].
  Future<SaveFileResult> saveFile(ShareFile file);
}
