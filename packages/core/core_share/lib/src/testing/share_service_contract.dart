import 'dart:async';

import 'package:test/test.dart';

import '../share_file.dart';
import '../share_service.dart';

/// Crea la implementación para un test. [whatsAppInstalled] y
/// [userCancelsSave] describen el dispositivo simulado.
typedef ShareServiceFactory = FutureOr<ShareService> Function({
  required bool whatsAppInstalled,
  required bool userCancelsSave,
});

/// Tests de contrato de [ShareService]. Toda implementación debe pasarlos,
/// con la plataforma simulada como indique [create].
///
/// ```dart
/// shareServiceContract('Fake', create: FakeShareService.new);
/// ```
void shareServiceContract(String implementation, {required ShareServiceFactory create}) {
  group('ShareService ($implementation)', () {
    Future<ShareService> service({bool whatsAppInstalled = true, bool userCancelsSave = false}) async =>
        create(whatsAppInstalled: whatsAppInstalled, userCancelsSave: userCancelsSave);

    final ShareFile file = ShareFile.markdown(baseName: 'compras', content: '# Compras\n');

    test('shareText comparte un texto', () async {
      await expectLater((await service()).shareText('Huevos', subject: 'Compras'), completes);
    });

    test('shareText y openWhatsApp rechazan un texto en blanco', () async {
      final ShareService share = await service();

      await expectLater(share.shareText(' \n'), throwsArgumentError);
      await expectLater(share.openWhatsApp(''), throwsArgumentError);
    });

    test('openWhatsApp devuelve true si WhatsApp está instalado', () async {
      expect(await (await service()).openWhatsApp('*Compras*\n- Huevos'), isTrue);
    });

    test('openWhatsApp devuelve false si WhatsApp no está instalado', () async {
      expect(await (await service(whatsAppInstalled: false)).openWhatsApp('Huevos'), isFalse);
    });

    test('shareFile comparte un archivo', () async {
      await expectLater((await service()).shareFile(file), completes);
    });

    test('saveFile devuelve saved si el usuario guarda', () async {
      expect(await (await service()).saveFile(file), SaveFileResult.saved);
    });

    test('saveFile devuelve cancelled si el usuario cancela', () async {
      expect(await (await service(userCancelsSave: true)).saveFile(file), SaveFileResult.cancelled);
    });
  });
}
