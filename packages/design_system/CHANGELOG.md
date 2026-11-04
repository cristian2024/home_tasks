# Changelog

## 0.1.4 - 2026-10-31

### Añadido

- `AppSyncStatusCard`: tarjeta con el estado de una sincronización (`AppSyncTone`: `off`, `idle`, `syncing`, `error`), detalles en líneas, mensaje de error y una acción que se desactiva con indicador mientras sincroniza. El título se anuncia a los lectores de pantalla cuando cambia.
- `AppConflictCard<T>` con `AppConflictOption<T>`: conflicto entre dispositivos con sus opciones. Marca la opción que ya rige, avisa de la elegida y, con `keepLabel`, confirma la actual. Con `busy` no responde.
- La galería del ejemplo los muestra en la sección «Sincronización».

## 0.1.3 - 2026-10-29

### Añadido

- `showAppChoiceDialog<T>` con `AppDialogOption<T>`: diálogo que pregunta entre varias acciones además de cancelar (p. ej. «Sacar el contenido» o «Borrar todo»). Devuelve el valor elegido o `null` si se cancela. Las opciones `destructive` usan el color de error.
- La galería del ejemplo lo muestra en la sección «Diálogos».
- README del paquete y de la galería: tokens, componentes, diálogos y accesibilidad.

## 0.1.2 - 2026-10-28

### Añadido

- `AppFilterChips<T>`: elegir varias opciones a la vez (p. ej. filtrar por categorías), con la etiqueta visible u oculta (`showLabel`). Los lectores de pantalla anuncian la etiqueta.
- `AppBadge`: etiqueta corta con tono `critical`, `warning` o `neutral`, con colores del tema e icono opcional.
- `AppCheckTile`: fila que se marca como hecha con su casilla (con etiqueta para lectores de pantalla), tacha el título al marcarla y muestra badges bajo el subtítulo.
- La galería del ejemplo muestra los nuevos componentes en la sección «Listas».

### Interno

- Tipos explícitos en la app de ejemplo (`always_specify_types`).

## 0.1.1 - 2026-10-26

### Añadido

- `AppShortcutTile`: acceso rápido con un icono destacado y el título debajo (máximo dos líneas), con estado de error, tooltip opcional e icono genérico si no recibe uno.
- `AppShortcutGrid`: grilla desplazable de accesos rápidos con 4 columnas en móvil y más en pantallas anchas (`columnsFor`).

### Interno

- Tipos explícitos en todo el paquete (`always_specify_types`).

## 0.1.0 - 2026-10-22

Primera versión con CHANGELOG. Incluye lo hecho hasta esa fecha:

### Añadido

- Tokens (`AppColors`, `AppSpacing`, `AppRadii`, `AppSizes`) y temas claro y oscuro (`AppTheme`).
- Componentes accesibles: `AppButton`, `AppIconButton`, `AppCard`, `AppTextField`, `AppStatusView`, `AppLoadingView`, `AppSectionHeader`, `AppSettingsSection`, `AppSettingsTile`, `AppChoiceSelector` y `showAppConfirmDialog`.
