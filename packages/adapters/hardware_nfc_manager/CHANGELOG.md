# Changelog

## 0.1.0 - 2026-10-29

### Añadido

- `NfcManagerHardware`: `DependencyModule` que registra `NfcManagerScanner` como factoría de `NfcIdentifierScanner` (`core_hardware`). Quien compone la app solo lo elige.
- `NfcManagerScanner`: lee y escribe etiquetas NFC con `nfc_manager`. Usa el primer registro Text o URI, o el UID del tag si no tiene ninguno, y traduce los errores a `ScanException`. Viene de `core_hardware`, que lo eliminará.
