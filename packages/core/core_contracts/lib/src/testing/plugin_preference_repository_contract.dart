import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../plugin_preference_repository.dart';
import '../user_plugin_preference.dart';

/// Tests de contrato de [PluginPreferenceRepository]. Toda implementación
/// (en memoria o de cualquier motor de base de datos) debe pasarlos.
///
/// [create] devuelve un repositorio vacío para cada test y [dispose] lo
/// libera. Lo propio de cada motor (p. ej. que los datos sobrevivan al cerrar
/// la base) se prueba aparte, en el paquete de la implementación.
///
/// ```dart
/// pluginPreferenceRepositoryContract('Isar', create: () => ..., dispose: (_) => ...);
/// ```
void pluginPreferenceRepositoryContract(
  String implementation, {
  required FutureOr<PluginPreferenceRepository> Function() create,
  FutureOr<void> Function(PluginPreferenceRepository repository)? dispose,
}) {
  group('PluginPreferenceRepository ($implementation)', () {
    late PluginPreferenceRepository repository;

    const UserPluginPreference a = UserPluginPreference(pluginId: 'a', isEnabled: true, sortOrder: 0);
    const UserPluginPreference b = UserPluginPreference(pluginId: 'b', isEnabled: false, sortOrder: 1);

    setUp(() async => repository = await create());
    tearDown(() async => dispose?.call(repository));

    test('getAll devuelve vacío sin preferencias', () async {
      expect(await repository.getAll(), isEmpty);
    });

    test('save inserta y reemplaza por pluginId', () async {
      await repository.save(a);
      await repository.save(a.copyWith(isEnabled: false));

      expect(await repository.getAll(), <UserPluginPreference>[a.copyWith(isEnabled: false)]);
    });

    test('saveAll inserta varias preferencias y reemplaza las que ya existían', () async {
      await repository.save(a);
      await repository.saveAll(<UserPluginPreference>[a.copyWith(sortOrder: 5), b]);

      expect(await repository.getAll(), unorderedEquals(<UserPluginPreference>[a.copyWith(sortOrder: 5), b]));
    });

    test('watch emite el estado actual al suscribirse y la lista completa en cada cambio', () async {
      final Future<List<List<UserPluginPreference>>> emissions = repository.watch().take(3).toList();

      await repository.save(a);
      await repository.save(b);

      final List<List<UserPluginPreference>> result = await emissions;
      expect(result[0], isEmpty);
      expect(result[1], <UserPluginPreference>[a]);
      expect(result[2], unorderedEquals(<UserPluginPreference>[a, b]));
    });

    test('watch, suscrito después de guardar, empieza con lo guardado', () async {
      await repository.saveAll(<UserPluginPreference>[a, b]);

      expect(await repository.watch().first, unorderedEquals(<UserPluginPreference>[a, b]));
    });
  });
}
