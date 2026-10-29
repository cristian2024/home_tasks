import 'package:core_contracts/core_contracts.dart';
import 'package:core_contracts/testing.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  pluginPreferenceRepositoryContract(
    'en memoria',
    create: InMemoryPluginPreferenceRepository.new,
    dispose: (PluginPreferenceRepository repository) => (repository as InMemoryPluginPreferenceRepository).close(),
  );

  test('watch().first termina con el reloj simulado (onCancel no devuelve el futuro de cancel)', () {
    fakeAsync((FakeAsync async) {
      final InMemoryPluginPreferenceRepository repository = InMemoryPluginPreferenceRepository();
      List<UserPluginPreference>? first;

      repository.watch().first.then((List<UserPluginPreference> value) => first = value);
      async.flushMicrotasks();

      expect(first, isEmpty);
    });
  });
}
