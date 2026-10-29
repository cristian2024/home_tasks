/// Contrato para sacar contenido de la app: compartir texto, abrir WhatsApp y
/// compartir o guardar archivos. Los plugins piden [ShareService] al
/// `ServiceLocator`; la implementación la elige la app (p. ej. `share_native`).
library;

export 'src/share_file.dart';
export 'src/share_service.dart';
