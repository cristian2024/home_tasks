import 'package:core_secrets/testing.dart';
import 'package:test/test.dart';

void main() {
  secretStoreContract('InMemorySecretStore', create: InMemorySecretStore.new);

  group('InMemorySecretStore', () {
    test('empieza con los valores iniciales y expone una copia de lo guardado', () async {
      final Map<String, String> initial = <String, String>{'a': '1'};
      final InMemorySecretStore store = InMemorySecretStore(initial);

      await store.write('b', '2');
      initial['c'] = '3';

      expect(await store.read('a'), '1');
      expect(store.values, <String, String>{'a': '1', 'b': '2'});
      expect(() => store.values['d'] = '4', throwsUnsupportedError);
    });
  });
}
