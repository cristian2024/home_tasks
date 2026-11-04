# share_native

Adaptador de `core_share` con [`share_plus`](https://pub.dev/packages/share_plus), [`url_launcher`](https://pub.dev/packages/url_launcher) y [`file_picker`](https://pub.dev/packages/file_picker).

## Uso

Quien compone la app solo lo elige:

```dart
adapters: <DependencyModule>[NativeShare()]
```

`NativeShare` registra `NativeShareService` como `ShareService`:
- `shareText` y `shareFile`: hoja de compartir del sistema (share_plus).
- `openWhatsApp`: abre `whatsapp://send?text=…` (url_launcher). Devuelve `false` si WhatsApp no está instalado; no hay alternativa web.
- `saveFile`: diálogo del sistema para elegir dónde guardar (file_picker).

## Configuración nativa

Para que `openWhatsApp` detecte WhatsApp, la app declara el esquema `whatsapp`:
- Android: en `<queries>` del `AndroidManifest.xml`.
- iOS: en `LSApplicationQueriesSchemes` de `Info.plist`.

## Tests

Pasa la batería `shareServiceContract` con las plataformas simuladas. `NativeShareService(sharePlus: …)` permite inyectar otra instancia de `SharePlus`.

```sh
flutter test
```
