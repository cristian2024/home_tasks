# urgency

Niveles de urgencia comunes para lo pendiente de la casa (compras, tareas). Dart puro.

## Contenido

`Urgency`, de más a menos urgente:

| Valor | Significado |
| :--- | :--- |
| `immediate` | Hoy, o ya. |
| `high` | En la próxima ocasión (la próxima compra, esta semana). |
| `normal` | Sin prisa especial. Es el valor por defecto (`Urgency.defaultValue`). |
| `low` | Cuando se pueda. |

- El orden natural (`compareTo`) pone primero lo más urgente, así que una lista ordenada con `sort()` empieza por lo urgente.
- `isUrgent`: `immediate` o `high`, lo que debe verse de un vistazo.
- `isMoreUrgentThan(other)`.

## Uso

Cada funcionalidad guarda el valor (p. ej. por su `name`) y compone sus propios textos traducidos. Este paquete no tiene textos.

## Tests

```sh
dart test
```

Cobertura: 100 %.
