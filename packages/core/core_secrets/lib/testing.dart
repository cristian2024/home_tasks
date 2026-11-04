/// Doble de prueba y tests de contrato de `core_secrets`.
library;

import 'core_secrets.dart';

export 'src/testing/secret_store_contract.dart';

/// [SecretStore] en memoria, para tests y apps de ejemplo. Cumple
/// `secretStoreContract`.
class InMemorySecretStore implements SecretStore {
  InMemorySecretStore([Map<String, String> initial = const <String, String>{}])
      : _values = Map<String, String>.of(initial);

  final Map<String, String> _values;

  /// Copia de lo guardado.
  Map<String, String> get values => Map<String, String>.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[_checkKey(key)];

  @override
  Future<void> write(String key, String value) async => _values[_checkKey(key)] = value;

  @override
  Future<void> delete(String key) async => _values.remove(_checkKey(key));

  String _checkKey(String key) {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', 'No puede estar vacía');
    }
    return key;
  }
}
