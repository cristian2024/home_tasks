# core_ui

Base de UI compartida: internacionalización con [slang](https://pub.dev/packages/slang) y coordinación del idioma entre paquetes.

## Contenido

- **`LocalizationCoordinator`**: mantiene el mismo idioma en todos los paquetes (`es`, `en`).
  - Cada paquete se registra con `register(...)`: cómo aplicar un idioma y, si quiere, cómo traducir sus claves y aceptar textos de reemplazo.
  - La app llama a `setLanguage(code)`, traduce claves de otros paquetes con `translate(key)` (p. ej. `HomePlugin.nameKey`) y reemplaza textos con `overrideTranslations`.
  - `LocalizationCoordinator.instance` es la instancia global. `supportedLocales` y `localizationsDelegates` se pasan a `MaterialApp`.
- **`injectTranslations(...)`**: lee de los assets del consumidor (`assets/i18n/<paquete>/<idioma>.json`, ver `translationAsset`) todos los textos de cada paquete y se los inyecta al coordinador.
- **`LanguageScope`** y **`LanguageRebuilder`**: exponen el idioma al árbol y vuelven a montar una página cuando cambia. Los textos de slang son globales y un widget ya construido no se entera del cambio.
- **`commonStrings`**: textos comunes (`cancel`, `confirm`, `save`, `retry`, `close`, `back`, `loading`…).

## Textos de los paquetes

Cada paquete define sus claves en `lib/src/i18n/{es,en}.i18n.json`: son su contrato y su respaldo. Quien consume el paquete (la app o un ejemplo) define **todos** sus textos en `assets/i18n/<paquete>/<idioma>.json` y los inyecta al arrancar. Para cambiar un texto se edita el archivo del consumidor, no el del paquete.

## Tests

`package:core_ui/testing.dart` trae lo que necesitan los tests de un consumidor:
- `translationProblems(base, injected)`: lista lo que falta o sobra en sus archivos (claves, tipos y parámetros).
- `MapAssetBundle`: assets en memoria.

```sh
flutter test
```
