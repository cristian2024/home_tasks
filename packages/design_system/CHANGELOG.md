# Changelog

## 0.3.0 - 2026-11-05

### Añadido

- `AppIcons`: iconos lineales de Lucide 1.69.0, incluidos en el paquete con su licencia.
- `registerDesignSystemLicenses`: añade las licencias de Inter y Lucide a la lista de la app.
- `AppButtonSize`: tamaños de 36, 40 y 48 de alto; el texto y los márgenes cambian con ellos.
- `AppButtonVariant.danger` y `dangerOutline`.
- `AppTouchTarget`: da 48 de área táctil y semántica a un control más pequeño, sin ocupar más sitio.
- `AppTopBar`: barra superior de 64 de alto, con el título pegado a la flecha.
- `AppFooterActions`, `AppNote`, `AppCameraFrame` y `showAppBottomSheet`.
- `AppIconButtonVariant.subtle` y `primary`.
- `AppTextField.prefixIcon`.
- `AppChoiceSelector.showLabel` y `wrapLabels`, y `AppChoiceSegment.borderRadius`.
- `AppDialogOption.primary`.
- `AppSettingsTile.compact` y `AppSectionHeader.compact`.
- `AppSizes.controlCompact` y `topBarHeight`.

### Cambiado

- **Incompatible:** `AppShortcutGrid` calcula las columnas según el ancho, a razón de 114 por casilla y con un mínimo de 2. `compactBreakpoint`, `compactColumns` y `maxTileWidth` pasan a ser `minColumns` y `minTileWidth`, y `columnsFor` recibe el ancho sin márgenes.
- **Incompatible:** `AppTextField` muestra la etiqueta encima del campo, mide 48 de alto y solo enseña el contador a partir del 80 % de `maxLength`. Con varias líneas empieza con dos y crece. Quien busque en tests un campo por su etiqueta debe usar `find.widgetWithText(AppTextField, …)`.
- **Incompatible:** `showAppChoiceDialog` apila las opciones a todo el ancho, con cancelar al final, y la destructiva lleva borde.
- `AppButton` mide 48 con `label-l`, y 36 si es solo texto; ya no ocupa 48 de alto en todos los tamaños.
- `AppChoiceSelector` mide 44 de alto, con 48 de área táctil. `AppFilterChips` mide 36, con borde de marca en la opción activa.
- `AppCheckTile` lleva la casilla de 24 alineada con el margen.
- Temas: filas de lista, diálogos (ancho 342, radio 24, velo `bgScrim`), hojas (fondo `bgSurfaceRaised`), barra superior y campos con los valores del diseño.
- `AppIconButton` estándar usa `textPrimary`.
- `AppSettingsTile` desactivada mantiene legible el subtítulo.
- `AppSyncStatusCard` sin hogar muestra el icono de casa.
- `AppConflictCard` deja la etiqueta en una línea si cabe junto al badge.

## 0.2.1 - 2026-11-04

### Añadido

- `AppChoiceSelector.padding`, para usarlo suelto en una pantalla sin margen propio.
- `AppChoiceSegment.showIcon`.

### Cambiado

- `AppChoiceSelector` quita el icono o la marca de las opciones cuando no caben, antes de apilarlas. Así caben cuatro opciones cortas en una fila.

## 0.2.0 - 2026-11-03

### Añadido

- Todos los tokens del sistema de diseño de Figma, se usen o no:
  - `AppColors` con la paleta completa.
  - `AppThemeColors`: extensión del tema con los 49 colores semánticos de claro y oscuro, incluidos éxito, información, hover y pressed.
  - `AppSpacing.s0`…`s1600`, con `xs`…`xl` como nombres cortos.
  - `AppRadii.none`, `extraSmall`, `extraLarge` y `full`.
  - `AppSizes`: controles, iconos, `touchTarget` y trazos.
  - `AppLayout`: márgenes, retículas, puntos de corte y anchos de referencia.
  - `AppTypography`: familia, tamaños, alturas de línea y los estilos `web*` y `mobile*`.
  - `AppElevation`: las sombras de claro y oscuro.
- La fuente Inter, incluida en el paquete con los pesos 400, 500, 600 y 700. Quien depende del paquete no tiene que declararla.
- `AppModuleCard`: tarjeta de un módulo en el inicio, con icono, título, resumen, etiquetas y acciones.
- `AppIconBox`: icono en un recuadro de 56.
- `AppButtonVariant.outline`: botón solo con borde.
- `AppBadgeTone.brand` y `AppBadgeTone.success`.
- `AppSettingsTile.destructive`, para acciones peligrosas como «Salir del hogar».
- `AppChoiceSegment`: cada opción de `AppChoiceSelector`.

### Cambiado

- `AppTheme` usa la paleta morada y los neutros del sistema de diseño de Figma, con un `ColorScheme` explícito en claro y en oscuro. Los avisos son ámbar.
- El `textTheme` usa Inter y los estilos `mobile*`: el título de la barra superior pasa de 22 a 18, los títulos de 16 con peso 600 y los interlineados los del sistema de diseño.
- `AppButtonVariant.secondary` pasa a ser un botón relleno suave de marca. Para seguir mostrando solo el borde, usa `outline`.
- `AppChoiceSelector` pasa a ser un control segmentado en lugar de `ChoiceChip`. Si las opciones no caben, se apilan.
- `AppBadge` pasa a forma de píldora y usa los colores semánticos de cada tono.
- `AppSettingsSection` usa radio de 12, y `AppSettingsTile` una flecha más pequeña y discreta y el tono de texto desactivado.
- `AppSectionHeader` pasa a 14 en color secundario.
- `AppStatusView` muestra el icono en un círculo de marca y un título de 18.
- `AppShortcutTile` usa `AppIconBox`, y su título pasa a peso 500.
- `AppSyncStatusCard` usa los colores semánticos, y su acción va a todo el ancho y sin icono.
- `AppConflictCard` marca la opción aplicada con una fila de marca y muestra las demás como botones con borde.
- Los `SnackBar` son flotantes, sobre la superficie elevada y con borde.
- Los botones pasan a radio de 8, las tarjetas a un borde sin elevación, los campos de texto a fondo de superficie y la barra superior al color del fondo de la pantalla.

### Eliminado

- **Incompatible:** `AppShortcutTile.iconBoxSize`. Usa `AppIconBox.size`.
- **Incompatible:** `AppColors.primary`, `primaryDark`, `secondary`, `backgroundLight`, `backgroundDark`, `surfaceLight`, `surfaceDark` y `error`. Ahora `AppColors` tiene los primitivos de Figma (`violet700`, `neutral50`…). Usa los colores de `Theme.of(context).colorScheme`.

### Interno

- Tests de contraste y opacidad de los colores de ambos temas, y de la carga de la fuente con el texto al 200 %. La galería muestra los colores nuevos y el README los describe.

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
