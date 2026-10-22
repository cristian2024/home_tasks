import 'dart:async';

import 'package:get_it/get_it.dart';

/// Envoltorio fino sobre `get_it` para que los paquetes no dependan
/// directamente de él.
///
/// Cada plugin registra sus dependencias en un scope propio (nombrado con su
/// ID) durante `initialize()` y lo descarta con [dropScope] en `dispose()`,
/// liberando así sus registros sin afectar a los demás.
class ServiceLocator {
  ServiceLocator([GetIt? getIt]) : _getIt = getIt ?? GetIt.asNewInstance();

  /// Instancia global de la aplicación.
  static final ServiceLocator instance = ServiceLocator(GetIt.instance);

  final GetIt _getIt;

  T get<T extends Object>({String? instanceName}) =>
      _getIt.get<T>(instanceName: instanceName);

  bool isRegistered<T extends Object>({String? instanceName}) =>
      _getIt.isRegistered<T>(instanceName: instanceName);

  /// Registra [instance] en el scope activo. [dispose] se invoca al descartar
  /// el scope o al hacer [reset].
  ///
  /// Devuelve `void` (a diferencia de get_it) para que `T` se infiera siempre
  /// del argumento y no del contexto, p. ej. dentro de `init: (l) => ...`.
  void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    FutureOr<void> Function(T instance)? dispose,
  }) {
    _getIt.registerSingleton<T>(instance, instanceName: instanceName, dispose: dispose);
  }

  /// Registra un singleton que se crea en el primer [get].
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
    FutureOr<void> Function(T instance)? dispose,
  }) =>
      _getIt.registerLazySingleton<T>(factory, instanceName: instanceName, dispose: dispose);

  /// Registra una factoría que crea una instancia nueva en cada [get].
  void registerFactory<T extends Object>(T Function() factory, {String? instanceName}) =>
      _getIt.registerFactory<T>(factory, instanceName: instanceName);

  /// Abre el scope [name] y ejecuta [init] para registrar en él. Los registros
  /// de este scope ocultan los de scopes anteriores con el mismo tipo.
  Future<void> pushScope(
    String name, {
    FutureOr<void> Function(ServiceLocator locator)? init,
  }) {
    if (_getIt.hasScope(name)) {
      throw StateError('El scope "$name" ya existe.');
    }
    return _getIt.pushNewScopeAsync(
      scopeName: name,
      init: init == null ? null : (_) async => init(this),
    );
  }

  /// Descarta el scope [name] (esté o no en la cima) invocando las funciones
  /// `dispose` de sus registros. No hace nada si el scope no existe.
  Future<void> dropScope(String name) async {
    if (_getIt.hasScope(name)) {
      await _getIt.dropScope(name);
    }
  }

  bool hasScope(String name) => _getIt.hasScope(name);

  /// Elimina todos los registros y scopes. Pensado para tests.
  Future<void> reset() => _getIt.reset();
}
