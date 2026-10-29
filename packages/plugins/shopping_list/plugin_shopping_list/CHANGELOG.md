# Changelog

## 0.1.0 - 2026-10-28

### Añadido

- `ShoppingListPlugin` (ID `shopping_list`, rutas bajo `/shopping-list`): lista de compras con items (nombre, cantidad, notas, urgencia, categorías y recurrencia aproximada) que se crean, editan, marcan como comprados (con deshacer) y borran.
- Lista filtrable por categorías, urgencia y estado, agrupada por categoría (cada item una vez, bajo su primera categoría) o por urgencia, con lo urgente y lo atrasado a la vista.
- Gestión de categorías con cinco por defecto (Comida, Aseo, Limpieza, Hogar y Farmacia): crear, renombrar, reordenar y borrar. Al borrar una en uso se avisa de cuántos items la usan, y esos items conservan sus demás categorías.
- Items recurrentes: al comprarlos guardan la fecha en el historial y vuelven a la lista cuando se abre su ventana.
- Exportar la lista completa o la filtrada, agrupada por categoría o por urgencia: por WhatsApp, como texto, o como archivo `.md` (compartir o guardar). Usa el `ShareService` que registre la app; sin él no se ofrece exportar.
- Capacidades públicas `ShoppingListQuery` y `ShoppingListWriter` (`shopping_list_contract`), registradas en el scope del plugin mientras está activo, y el evento `ShoppingItemPurchased` en el `EventBus`.
- Tarjeta de inicio con lo que hay por comprar y lo urgente.
- Textos en español e inglés que la app puede reemplazar (`translation_overrides`).
- App de ejemplo en `example/`, que elige sus adaptadores (`ShoppingListIsar` y `NativeShare`) e inyecta todos los textos.
