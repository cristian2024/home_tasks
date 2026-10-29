/// Doble de prueba y tests de contrato de `core_share`.
library;

import 'core_share.dart';

export 'src/testing/share_service_contract.dart';

/// [ShareService] que no sale de la app: guarda lo que se comparte para
/// comprobarlo en los tests. Cumple `shareServiceContract`.
class FakeShareService implements ShareService {
  FakeShareService({this.whatsAppInstalled = true, this.userCancelsSave = false});

  /// Si `openWhatsApp` encuentra WhatsApp.
  bool whatsAppInstalled;

  /// Si el usuario cancela el diálogo de `saveFile`.
  bool userCancelsSave;

  final List<String> sharedTexts = <String>[];
  final List<String> whatsAppMessages = <String>[];
  final List<ShareFile> sharedFiles = <ShareFile>[];

  /// Archivos guardados (los cancelados no cuentan).
  final List<ShareFile> savedFiles = <ShareFile>[];

  @override
  Future<void> shareText(String text, {String? subject}) async {
    _checkText(text);
    sharedTexts.add(text);
  }

  @override
  Future<bool> openWhatsApp(String text) async {
    _checkText(text);
    if (!whatsAppInstalled) {
      return false;
    }
    whatsAppMessages.add(text);
    return true;
  }

  @override
  Future<void> shareFile(ShareFile file, {String? subject}) async => sharedFiles.add(file);

  @override
  Future<SaveFileResult> saveFile(ShareFile file) async {
    if (userCancelsSave) {
      return SaveFileResult.cancelled;
    }
    savedFiles.add(file);
    return SaveFileResult.saved;
  }

  void _checkText(String text) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'No puede estar en blanco');
    }
  }
}
