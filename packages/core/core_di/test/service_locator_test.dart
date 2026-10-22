import 'package:core_di/core_di.dart';
import 'package:test/test.dart';

class Service {
  Service(this.name);
  final String name;
}

void main() {
  late ServiceLocator locator;

  setUp(() => locator = ServiceLocator());
  tearDown(() => locator.reset());

  test('registerSingleton devuelve siempre la misma instancia', () {
    final service = Service('a');
    locator.registerSingleton(service);

    expect(locator.get<Service>(), same(service));
    expect(locator.isRegistered<Service>(), isTrue);
  });

  test('registerLazySingleton crea la instancia en el primer get', () {
    var created = 0;
    locator.registerLazySingleton(() {
      created++;
      return Service('lazy');
    });

    expect(created, 0);
    final first = locator.get<Service>();
    expect(locator.get<Service>(), same(first));
    expect(created, 1);
  });

  test('registerFactory crea una instancia nueva en cada get', () {
    locator.registerFactory(() => Service('f'));

    expect(locator.get<Service>(), isNot(same(locator.get<Service>())));
  });

  test('soporta registros con nombre', () {
    locator
      ..registerSingleton(Service('a'), instanceName: 'a')
      ..registerSingleton(Service('b'), instanceName: 'b');

    expect(locator.get<Service>(instanceName: 'b').name, 'b');
  });

  group('scopes por plugin', () {
    test('dropScope libera los registros del plugin e invoca dispose', () async {
      final disposed = <String>[];
      await locator.pushScope(
        'plugin_a',
        init: (l) => l.registerSingleton(Service('a'), dispose: (s) => disposed.add(s.name)),
      );

      expect(locator.get<Service>().name, 'a');

      await locator.dropScope('plugin_a');

      expect(locator.isRegistered<Service>(), isFalse);
      expect(locator.hasScope('plugin_a'), isFalse);
      expect(disposed, ['a']);
    });

    test('descartar un scope intermedio no afecta a los demás', () async {
      await locator.pushScope('plugin_a', init: (l) => l.registerSingleton(Service('a')));
      await locator.pushScope(
        'plugin_b',
        init: (l) => l.registerSingleton(Service('b'), instanceName: 'b'),
      );

      await locator.dropScope('plugin_a');

      expect(locator.isRegistered<Service>(), isFalse);
      expect(locator.get<Service>(instanceName: 'b').name, 'b');
      expect(locator.hasScope('plugin_b'), isTrue);
    });

    test('un scope oculta registros previos del mismo tipo', () async {
      locator.registerSingleton(Service('base'));
      await locator.pushScope('plugin_a', init: (l) => l.registerSingleton(Service('a')));

      expect(locator.get<Service>().name, 'a');

      await locator.dropScope('plugin_a');

      expect(locator.get<Service>().name, 'base');
    });

    test('pushScope con un nombre existente lanza StateError', () async {
      await locator.pushScope('plugin_a');

      expect(() => locator.pushScope('plugin_a'), throwsStateError);
    });

    test('dropScope de un scope inexistente no hace nada', () async {
      await locator.dropScope('missing');
    });
  });
}
