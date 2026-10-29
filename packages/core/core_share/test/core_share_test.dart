import 'package:core_share/core_share.dart';
import 'package:core_share/testing.dart';
import 'package:test/test.dart';

void main() {
  shareServiceContract('FakeShareService', create: FakeShareService.new);

  group('ShareFile', () {
    test('markdown añade la extensión .md y el tipo text/markdown', () {
      expect(
        ShareFile.markdown(baseName: 'compras', content: 'x'),
        ShareFile(fileName: 'compras.md', content: 'x', mimeType: 'text/markdown'),
      );
    });

    test('rechaza nombres vacíos, sin extensión o con separadores de ruta', () {
      for (final String name in <String>['', '.md', 'compras', 'compras.', 'a/b.md', r'a\b.md']) {
        expect(() => ShareFile(fileName: name, content: '', mimeType: 'text/plain'), throwsArgumentError, reason: name);
      }
      expect(ShareFile(fileName: 'lista de compras.v2.md', content: '', mimeType: 'text/plain').fileName,
          'lista de compras.v2.md');
    });
  });

  group('FakeShareService', () {
    test('guarda lo compartido y lo guardado', () async {
      final FakeShareService share = FakeShareService();
      final ShareFile file = ShareFile.markdown(baseName: 'compras', content: 'x');

      await share.shareText('a');
      await share.openWhatsApp('b');
      await share.shareFile(file);
      await share.saveFile(file);
      share.userCancelsSave = true;
      await share.saveFile(file);

      expect(share.sharedTexts, <String>['a']);
      expect(share.whatsAppMessages, <String>['b']);
      expect(share.sharedFiles, <ShareFile>[file]);
      expect(share.savedFiles, <ShareFile>[file]);
    });
  });
}
