import 'package:core_contracts/core_contracts.dart';
import 'package:core_di/core_di.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_database.dart';
import 'isar_feature.dart';
import 'plugin_preferences/isar_plugin_preference_repository.dart';

/// Almacenamiento local sobre Isar. Quien compone la app solo lo elige:
///
/// ```dart
/// IsarStorage(features: <IsarFeature>[ItemTrackerIsar()])
/// ```
///
/// Al registrarse abre la base de datos y registra en el [ServiceLocator]
/// `PluginPreferenceRepository` y los contratos de cada [IsarFeature]. La
/// base se cierra con [ServiceLocator.reset].
class IsarStorage implements DependencyModule {
  const IsarStorage({this.features = const <IsarFeature>[], this.directory, this.name = Isar.defaultName});

  /// Adaptadores Isar de las funcionalidades. Isar exige conocer todos los
  /// esquemas al abrir la base, así que van los de **todos** los plugins
  /// registrados, también los desactivados, para que sus datos sigan intactos.
  final List<IsarFeature> features;

  /// Carpeta de la base de datos. Por defecto, la de documentos de la app.
  final String? directory;

  /// Nombre de la base de datos dentro de [directory].
  final String name;

  @override
  Future<void> register(ServiceLocator services) async {
    final Isar isar = await IsarDatabase.open(
      directory: directory ?? (await getApplicationDocumentsDirectory()).path,
      features: features,
      name: name,
    );
    services
      ..registerSingleton<_OpenDatabase>(_OpenDatabase(isar), dispose: (_OpenDatabase database) => database.close())
      ..registerSingleton<PluginPreferenceRepository>(IsarPluginPreferenceRepository(isar));
    for (final IsarFeature feature in features) {
      feature.register(services, isar);
    }
  }
}

/// La base abierta, registrada solo para cerrarla al liberar el locator.
class _OpenDatabase {
  _OpenDatabase(this._isar);

  final Isar _isar;

  Future<void> close() async {
    if (_isar.isOpen) {
      await _isar.close();
    }
  }
}
