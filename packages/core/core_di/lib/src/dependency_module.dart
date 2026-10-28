import 'service_locator.dart';

/// Paquete que registra en el [ServiceLocator] las implementaciones de sus
/// contratos, p. ej. un adaptador de base de datos.
///
/// Quien compone la app solo elige qué módulos usa. Los demás paquetes piden
/// los contratos al locator sin saber qué implementación hay detrás ni qué
/// recursos necesita.
abstract interface class DependencyModule {
  /// Prepara sus recursos (p. ej. abrir la base de datos) y registra sus
  /// implementaciones en [services]. Para liberarlos, los registra con
  /// `dispose`.
  Future<void> register(ServiceLocator services);
}
