# Changelog

## 0.1.2 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.1 - 2026-10-27

### Añadido

- `DependencyModule`: contrato de un paquete que registra en el `ServiceLocator` las implementaciones de sus contratos (p. ej. un adaptador de base de datos). Quien compone la app solo elige qué módulos usa; el resto pide los contratos al locator.

### Interno

- Tipos explícitos en todo el paquete (`always_specify_types`).

## 0.1.0 - 2026-10-22

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- `ServiceLocator`: envoltorio fino sobre `get_it`, con singletons, singletons diferidos, factorías, registros con nombre y scopes por plugin (`pushScope` / `dropScope`).
