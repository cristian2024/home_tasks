/// Lectura y validación de JSON para los modelos que viajan entre
/// dispositivos o se guardan como texto.
library;

/// Lanza [ArgumentError] si [value] no es JSON: `null`, `bool`, `num`,
/// `String`, listas o mapas con claves `String` de esos mismos tipos.
void checkJsonValue(Object? value, String name) {
  if (value == null || value is bool || value is num || value is String) {
    return;
  }
  if (value is List<Object?>) {
    for (final Object? element in value) {
      checkJsonValue(element, name);
    }
    return;
  }
  if (value is Map<String, Object?>) {
    for (final Object? element in value.values) {
      checkJsonValue(element, name);
    }
    return;
  }
  throw ArgumentError.value(value, name, 'No es un valor JSON');
}

/// Lanza [ArgumentError] si [value] está vacío.
String checkNotEmpty(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'No puede estar vacío');
  }
  return value;
}

/// Campo [key] de [json] con tipo [T]. Lanza [FormatException] si falta o
/// tiene otro tipo.
T readJson<T>(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! T) {
    throw FormatException('Se esperaba $T en "$key"', json);
  }
  return value;
}

/// [value] como mapa JSON. Lanza [FormatException] si no lo es.
Map<String, Object?> asJsonMap(Object? value) {
  if (value is! Map<String, Object?>) {
    throw FormatException('Se esperaba un objeto JSON', value);
  }
  return value;
}

/// Ejecuta [read] y convierte en [FormatException] los errores de validación
/// de los constructores.
T parseJson<T>(Object? source, T Function() read) {
  try {
    return read();
  } on ArgumentError catch (error) {
    throw FormatException(error.toString(), source);
  }
}
