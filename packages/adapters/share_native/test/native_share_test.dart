import 'dart:convert';
import 'dart:typed_data';

import 'package:core_di/core_di.dart';
import 'package:core_share/core_share.dart';
import 'package:core_share/testing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_native/share_native.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final List<ShareParams> shared = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    return const ShareResult('', ShareResultStatus.success);
  }
}

class _FakeUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  _FakeUrlLauncher({required this.whatsAppInstalled});

  final bool whatsAppInstalled;
  final List<String> launched = <String>[];
  final List<PreferredLaunchMode> modes = <PreferredLaunchMode>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => whatsAppInstalled && url.startsWith('whatsapp:');

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    modes.add(options.mode);
    return true;
  }
}

class _FakeFilePicker extends FilePickerPlatform with MockPlatformInterfaceMixin {
  _FakeFilePicker({required this.userCancels});

  final bool userCancels;
  final List<(String, Uint8List, String)> saved = <(String, Uint8List, String)>[];

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (userCancels) {
      return null;
    }
    saved.add((fileName, bytes, mimeType));
    return Uri.file('/documentos/$fileName');
  }
}

void main() {
  late _FakeSharePlatform sharePlatform;
  late _FakeUrlLauncher urlLauncher;
  late _FakeFilePicker filePicker;

  NativeShareService create({bool whatsAppInstalled = true, bool userCancelsSave = false}) {
    sharePlatform = _FakeSharePlatform();
    UrlLauncherPlatform.instance = urlLauncher = _FakeUrlLauncher(whatsAppInstalled: whatsAppInstalled);
    FilePickerPlatform.instance = filePicker = _FakeFilePicker(userCancels: userCancelsSave);
    return NativeShareService(sharePlus: SharePlus.custom(sharePlatform));
  }

  shareServiceContract('NativeShareService', create: create);

  final ShareFile file = ShareFile.markdown(baseName: 'compras', content: '# Compras ñ\n');

  test('shareText pasa el texto y el asunto a la hoja de compartir', () async {
    await create().shareText('Huevos', subject: 'Compras');

    expect(sharePlatform.shared.single.text, 'Huevos');
    expect(sharePlatform.shared.single.subject, 'Compras');
  });

  test('openWhatsApp abre whatsapp://send con el texto codificado, fuera de la app', () async {
    await create().openWhatsApp('*Compras*\n- Huevos & pan');

    expect(urlLauncher.launched, <String>['whatsapp://send?text=*Compras*%0A-%20Huevos%20%26%20pan']);
    expect(urlLauncher.modes, <PreferredLaunchMode>[PreferredLaunchMode.externalApplication]);
  });

  test('openWhatsApp no abre nada si WhatsApp no está instalado', () async {
    await create(whatsAppInstalled: false).openWhatsApp('Huevos');

    expect(urlLauncher.launched, isEmpty);
  });

  test('shareFile comparte el contenido en UTF-8 con su nombre y su tipo', () async {
    await create().shareFile(file, subject: 'Compras');

    final ShareParams params = sharePlatform.shared.single;
    expect(params.fileNameOverrides, <String>['compras.md']);
    expect(params.subject, 'Compras');
    expect(params.files!.single.mimeType, 'text/markdown');
    expect(utf8.decode(await params.files!.single.readAsBytes()), '# Compras ñ\n');
  });

  test('saveFile abre el diálogo de guardar con el nombre, el contenido y el tipo', () async {
    await create().saveFile(file);

    final (String name, Uint8List bytes, String mimeType) = filePicker.saved.single;
    expect(name, 'compras.md');
    expect(utf8.decode(bytes), '# Compras ñ\n');
    expect(mimeType, 'text/markdown');
  });

  test('NativeShare registra ShareService en el locator', () async {
    final ServiceLocator locator = ServiceLocator();
    addTearDown(locator.reset);

    await const NativeShare().register(locator);

    expect(locator.get<ShareService>(), isA<NativeShareService>());
    expect(NativeShareService(), isA<ShareService>());
  });
}
