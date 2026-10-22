import 'package:core_contracts/core_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late PluginRegistry registry;

  setUp(() => registry = PluginRegistry());

  test('registra plugins y los devuelve en orden de registro', () {
    final a = FakePlugin('a');
    final b = FakePlugin('b');

    registry
      ..register(a)
      ..register(b);

    expect(registry.allPlugins, [a, b]);
    expect(registry.getPlugin('b'), same(b));
    expect(registry.getPlugin('missing'), isNull);
  });

  test('lanza StateError al registrar un ID duplicado', () {
    registry.register(FakePlugin('a'));

    expect(() => registry.register(FakePlugin('a')), throwsStateError);
  });

  test('allPlugins es inmodificable', () {
    registry.register(FakePlugin('a'));

    expect(() => registry.allPlugins.add(FakePlugin('b')), throwsUnsupportedError);
  });
}
