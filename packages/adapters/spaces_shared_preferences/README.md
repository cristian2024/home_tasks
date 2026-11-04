# spaces_shared_preferences

Adaptador de `core_spaces` con [shared_preferences](https://pub.dev/packages/shared_preferences): guarda la lista de espacios de datos del dispositivo y cuál es el activo, fuera de las bases de los espacios (hay que leerla antes de abrir ninguna).

## Uso

Quien compone la app lo elige, con `SharedPreferencesSpaces()` en su lista de adaptadores o creando el directorio directamente antes de abrir ninguna base:

```dart
final DataSpaceDirectory directory = SharedPreferencesDataSpaceDirectory();
final DataSpace? active = await directory.active();
```

## Detalles

- Todo va en una sola clave (`spaces.directory`, en JSON): un cambio guarda la lista y el activo a la vez, así que nunca queda una lista sin activo.
- Los cambios se aplican de uno en uno, aunque se pidan a la vez.
- Si lo guardado no se puede leer, falla con `StateError`: empezar con la lista vacía dejaría los datos de los espacios sin lista.

## Tests

Pasa `dataSpaceDirectoryContract` con `SharedPreferences.setMockInitialValues`:

```sh
flutter test
```
