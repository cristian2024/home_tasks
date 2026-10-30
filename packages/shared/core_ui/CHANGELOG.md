# Changelog

## 0.1.2 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.1 - 2026-10-24

### Añadido

- `injectTranslations` y `translationAsset`: quien consume los paquetes inyecta todos sus textos desde `assets/i18n/<paquete>/<idioma>.json`.
- `package:core_ui/testing.dart`: `translationProblems` comprueba que los textos inyectados tengan exactamente las claves y los parámetros del paquete, `packageTranslations` lee los JSON de un paquete del workspace y `MapAssetBundle` sirve assets en memoria.

### Cambiado

- Los JSON de cada paquete pasan a ser el contrato de claves y el respaldo de los textos que no se inyecten.

## 0.1.0 - 2026-10-23

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- `LocalizationCoordinator`: sincroniza el idioma de todos los paquetes, traduce claves de otros paquetes y permite reemplazar sus textos (`overrideTranslations`).
- `LanguageRebuilder` para que las páginas abiertas cambien de idioma.
- Textos comunes (`commonStrings`) en español e inglés.
