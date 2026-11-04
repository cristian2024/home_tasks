import 'dart:async';

import 'package:test/test.dart';

import '../secret_store.dart';

/// Crea un almacén vacío para un test.
typedef SecretStoreFactory = FutureOr<SecretStore> Function();

/// Tests de contrato de [SecretStore]. Toda implementación debe pasarlos.
///
/// ```dart
/// secretStoreContract('InMemorySecretStore', create: InMemorySecretStore.new);
/// ```
void secretStoreContract(String implementation, {required SecretStoreFactory create}) {
  group('SecretStore ($implementation)', () {
    late SecretStore store;

    setUp(() async => store = await create());

    test('read devuelve null si la clave no existe', () async {
      expect(await store.read('household.key'), isNull);
    });

    test('write guarda el valor y read lo devuelve', () async {
      await store.write('household.key', 'c2VjcmV0bw==');

      expect(await store.read('household.key'), 'c2VjcmV0bw==');
    });

    test('write reemplaza el valor anterior', () async {
      await store.write('household.key', 'a');
      await store.write('household.key', 'b');

      expect(await store.read('household.key'), 'b');
    });

    test('guarda un valor vacío y caracteres no ASCII', () async {
      await store.write('vacío', '');
      await store.write('ñandú', 'clave: ñ€✓');

      expect(await store.read('vacío'), '');
      expect(await store.read('ñandú'), 'clave: ñ€✓');
    });

    test('las claves son independientes', () async {
      await store.write('a', '1');
      await store.write('b', '2');
      await store.delete('a');

      expect(await store.read('a'), isNull);
      expect(await store.read('b'), '2');
    });

    test('delete borra la clave y no falla si no existe', () async {
      await store.write('household.key', 'a');
      await store.delete('household.key');
      await store.delete('household.key');

      expect(await store.read('household.key'), isNull);
    });

    test('rechaza una clave vacía', () async {
      await expectLater(store.read(''), throwsArgumentError);
      await expectLater(store.write('', 'a'), throwsArgumentError);
      await expectLater(store.delete(''), throwsArgumentError);
    });
  });
}
