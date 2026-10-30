import 'package:core_di/core_di.dart';
import 'package:core_secrets/core_secrets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Registra [SecureStorageSecretStore] como `SecretStore`. Quien compone la
/// app solo lo elige:
///
/// ```dart
/// adapters: <DependencyModule>[SecureStorageSecrets()]
/// ```
///
/// En Android, la app excluye este almacén de las copias de seguridad
/// (`allowBackup` / `dataExtractionRules`): restaurado en otro teléfono, la
/// clave no se podría descifrar.
class SecureStorageSecrets implements DependencyModule {
  const SecureStorageSecrets();

  @override
  Future<void> register(ServiceLocator services) async =>
      services.registerSingleton<SecretStore>(SecureStorageSecretStore());
}

/// [SecretStore] con flutter_secure_storage: Keychain en iOS y macOS y
/// Keystore en Android.
///
/// En iOS y macOS los secretos se leen tras el primer desbloqueo (también en
/// segundo plano) y nunca salen del dispositivo: ni a iCloud Keychain ni a una
/// copia restaurada en otro.
class SecureStorageSecretStore implements SecretStore {
  /// [storage] permite usar otra configuración en los tests.
  SecureStorageSecretStore({FlutterSecureStorage storage = defaultStorage}) : _storage = storage;

  static const IOSOptions _iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device);
  static const MacOsOptions _macOsOptions =
      MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device);

  /// Configuración por defecto: la de [SecureStorageSecretStore].
  static const FlutterSecureStorage defaultStorage =
      FlutterSecureStorage(iOptions: _iosOptions, mOptions: _macOsOptions);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async => _storage.read(key: _checkKey(key));

  @override
  Future<void> write(String key, String value) async => _storage.write(key: _checkKey(key), value: value);

  @override
  Future<void> delete(String key) async => _storage.delete(key: _checkKey(key));

  String _checkKey(String key) {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', 'No puede estar vacía');
    }
    return key;
  }
}
