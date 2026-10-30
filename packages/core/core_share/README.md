# core_share

Contrato para sacar contenido de la app: compartir texto, abrir WhatsApp y compartir o guardar archivos. Es Dart puro; la implementación la elige la app (p. ej. `share_native`).

## Contenido

- **`ShareService`**:
  - `shareText(text)`: hoja de compartir del sistema.
  - `openWhatsApp(text)`: devuelve `false` si WhatsApp no está instalado.
  - `shareFile(file)`.
  - `saveFile(file)`: devuelve `SaveFileResult.saved` o `cancelled`.

  Un texto en blanco se rechaza con `ArgumentError`.
- **`ShareFile`**: archivo de texto con nombre, contenido y tipo MIME. `ShareFile.markdown(baseName:, content:)` crea un `.md`. Valida que el nombre tenga extensión y no tenga barras.

## Uso

Los plugins piden `ShareService` al `ServiceLocator`. Si no hay ninguno registrado, ocultan la opción de exportar:

```dart
if (locator.isRegistered<ShareService>()) {
  await locator.get<ShareService>().openWhatsApp(text);
}
```

## Tests

`package:core_share/testing.dart` trae la batería `shareServiceContract`, que toda implementación debe pasar, y `FakeShareService`, que guarda lo compartido y simula si WhatsApp está instalado o si el usuario cancela el guardado.

```sh
dart test
```
