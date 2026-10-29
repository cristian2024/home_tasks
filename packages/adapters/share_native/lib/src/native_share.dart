import 'dart:convert';
import 'dart:typed_data';

import 'package:core_di/core_di.dart';
import 'package:core_share/core_share.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Registra [NativeShareService] como `ShareService`. Quien compone la app
/// solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[NativeShare()]
/// ```
///
/// Para que `openWhatsApp` detecte WhatsApp, la app declara el esquema
/// `whatsapp` (`<queries>` en Android y `LSApplicationQueriesSchemes` en iOS).
class NativeShare implements DependencyModule {
  const NativeShare();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerSingleton<ShareService>(NativeShareService());
}

/// [ShareService] con la hoja de compartir del sistema (share_plus), WhatsApp
/// por su esquema `whatsapp://` (url_launcher) y el diálogo de guardar del
/// sistema (file_picker).
class NativeShareService implements ShareService {
  /// [sharePlus] permite usar otra plataforma en los tests.
  NativeShareService({SharePlus? sharePlus}) : _share = sharePlus ?? SharePlus.instance;

  final SharePlus _share;

  @override
  Future<void> shareText(String text, {String? subject}) async {
    _checkText(text);
    await _share.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<bool> openWhatsApp(String text) async {
    _checkText(text);
    final Uri uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<void> shareFile(ShareFile file, {String? subject}) async {
    await _share.share(ShareParams(
      files: <XFile>[XFile.fromData(_bytes(file), mimeType: file.mimeType, name: file.fileName)],
      fileNameOverrides: <String>[file.fileName],
      subject: subject,
    ));
  }

  @override
  Future<SaveFileResult> saveFile(ShareFile file) async {
    final Uri? saved = await FilePicker.saveFile(fileName: file.fileName, bytes: _bytes(file), mimeType: file.mimeType);
    return saved == null ? SaveFileResult.cancelled : SaveFileResult.saved;
  }

  static Uint8List _bytes(ShareFile file) => Uint8List.fromList(utf8.encode(file.content));

  static void _checkText(String text) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'No puede estar en blanco');
    }
  }
}
