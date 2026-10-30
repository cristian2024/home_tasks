# Changelog

## 0.1.1 - 2026-10-29

### Añadido

- README del paquete.

## 0.1.0 - 2026-10-28

### Añadido

- `Recurrence`: recurrencia aproximada entre `minDays` y `maxDays` días (`Recurrence.between(8, 15)`) o fija (`Recurrence.fixed(7)`), de 1 a 365 días.
- `windowAfter(lastDone)` devuelve la `RecurrenceWindow` siguiente: se abre a los `minDays` días y se cierra al terminar el día `maxDays`. Todo en UTC.
- `statusAt(now, lastDone:)` devuelve `RecurrenceStatus.waiting` (aún no toca), `due` (toca) u `overdue` (atrasado). Si nunca se hizo, toca.
