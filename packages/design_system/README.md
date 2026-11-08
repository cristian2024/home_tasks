# design_system

Sistema de diseño de la app: tokens, temas claro y oscuro y componentes accesibles. Solo depende de Flutter y de `core_ui`, que aporta los textos comunes («Cancelar», «Confirmar»…).

Los componentes no conocen la app: reciben todo por parámetros y devuelven resultados con callbacks o con el valor del diálogo. La navegación, los cubits y los snackbars los pone la pantalla que los usa.

## Contenido

**Tokens y tema**
Replican el sistema de diseño de Figma.
- `AppColors`: colores primitivos.
- `AppThemeColors`: colores semánticos de cada tema, con lo que `ColorScheme` no cubre (éxito, información, hover, pressed). Se leen con `AppThemeColors.of(context)`.
- `AppSpacing` (`s0`…`s1600`, y `xs`…`xl` como nombres cortos), `AppRadii`, `AppSizes` (`minTouchTarget` de 48) y `AppLayout`.
- `AppTypography` (estilos `web*` y `mobile*`) y `AppElevation`.
- `AppTheme.light` y `AppTheme.dark`, con los `SnackBar` en la superficie elevada, flotantes y con borde. Los componentes y las pantallas leen los colores del tema, nunca `AppColors`, y los textos de `textTheme`, que usa los estilos `mobile*`.

**Fuente**
El paquete incluye Inter 4.1 (pesos 400, 500, 600 y 700, bajo la licencia de `assets/fonts/OFL.txt`). Quien depende del paquete la recibe sin declarar nada. Un `TextStyle` propio debe indicar `package: AppTypography.fontPackage`; sin eso, Flutter no la encuentra y usa la del sistema.

También incluye los iconos de Lucide 1.69.0 (`assets/fonts/Lucide.ttf`, bajo la licencia ISC y MIT de `assets/fonts/LICENSE-Lucide.txt`). Se usan con `AppIcons`, nunca con `Icons`. Quien publica una app llama a `registerDesignSystemLicenses()` al arrancar para incluir ambas licencias.

Algunos nombres no coinciden con Figma y están documentados en cada clase: `radius/sm` es `AppRadii.extraSmall`, y `size/icon-md` es `AppSizes.iconCompact`.

**Componentes**

| Componente | Para qué |
| :--- | :--- |
| `AppButton` | Botón `primary`, `secondary` (relleno suave), `outline`, `text`, `danger`, `dangerOutline` o `dangerText` (`AppButtonVariant`), de 36, 40 o 48 de alto (`AppButtonSize`), con icono opcional. |
| `AppTouchTarget` | Da 48 de área táctil y semántica a un control más pequeño, sin ocupar más sitio. |
| `AppTopBar` | Barra superior de las pantallas. Usarla en lugar de `AppBar`. |
| `AppFooterActions` | Acciones fijas al pie de una pantalla. |
| `AppNote` | Nota destacada con icono. |
| `AppCameraFrame` | Panel oscuro con guía para la vista previa de una cámara. |
| `showAppBottomSheet` | Hoja inferior que mide lo que su contenido. |
| `showAppActionSheet<T>` | Hoja inferior con acciones agrupadas (`AppSheetAction<T>`, con `destructive`), p. ej. el menú ⋮. Devuelve la elegida. |
| `showAppDateSheet` | Hoja para elegir un día: accesos rápidos (`AppDateOption`), campo en el formato del idioma y calendario del sistema. Devuelve `AppDateChoice`, sin fecha si se quita. |
| `AppIconButton` | Botón de icono con `tooltip` obligatorio. |
| `AppTextField` | Campo de texto con la etiqueta encima, error e icono opcional. El contador aparece cerca del límite, con el texto de `counterText`. Con `minLines: 1`, un campo de varias líneas empieza en una y crece. |
| `AppPickerField` | Campo que no se escribe: muestra un valor y abre un selector al tocarlo (p. ej. la fecha). Se anuncia como botón. |
| `AppCard` | Tarjeta, pulsable si recibe `onTap` (con `semanticLabel`). |
| `AppIconBox` | Icono en un recuadro de 56, de marca o de error. |
| `AppModuleCard` | Tarjeta de un módulo en el inicio: icono, título, resumen, etiquetas y acciones. Pulsable con `onTap`, o con acciones, pero no ambas. |
| `AppSectionHeader` | Título de sección con acción opcional a la derecha, que pasa debajo si no cabe. |
| `AppStatusView`, `AppLoadingView` | Estados vacío, de error y de carga. El icono va en un círculo de marca. |
| `AppShortcutTile`, `AppShortcutGrid` | Accesos rápidos en una grilla con tantas columnas como quepan (`columnsFor`). |
| `AppSettingsSection`, `AppSettingsTile`, `AppChoiceSelector<T>` | Pantallas de configuración (`destructive` para acciones peligrosas) y elección entre pocas opciones con un control segmentado (`AppChoiceSegment`), que quita la marca y luego apila las opciones si no caben. `padding: EdgeInsets.zero` para usarlo suelto en una pantalla. |
| `AppFilterChips<T>` | Elegir varias opciones a la vez (filtros). |
| `AppBadge` | Etiqueta corta con tono `critical`, `warning`, `neutral`, `brand` o `success`. |
| `AppCheckTile` | Fila que se marca como hecha con su casilla, con una línea de datos y etiquetas. Hecha, el título se tacha en color secundario. |
| `AppSyncStatusCard` | Estado de una sincronización (`AppSyncTone`: `off`, `idle`, `syncing`, `error`), con detalles, mensaje de error y acción. El título se anuncia al cambiar. |
| `AppConflictCard<T>` | Conflicto entre dispositivos con sus opciones (`AppConflictOption<T>`): marca la que ya rige (`applied`) con una fila de marca y su etiqueta, avisa de la elegida (`onSelected`) y confirma la actual (`keepLabel`, `onKeep`). |

**Diálogos**
- `showAppConfirmDialog`: sí o no. Devuelve `true` solo si se confirma.
- `showAppChoiceDialog<T>`: varias acciones además de cancelar (`AppDialogOption<T>`, con `destructive` para las peligrosas). Devuelve el valor elegido o `null`.

```dart
final String? choice = await showAppChoiceDialog<String>(
  context,
  title: '¿Borrar «Caja»?',
  message: 'Contiene 3 objetos.',
  options: const <AppDialogOption<String>>[
    AppDialogOption<String>(value: 'move', label: 'Sacar el contenido'),
    AppDialogOption<String>(value: 'all', label: 'Borrar todo', destructive: true),
  ],
);
```

## Accesibilidad

Todo componente interactivo tiene etiqueta para lectores de pantalla (`Semantics` o `tooltip`), un área táctil mínima de 48 y admite texto ampliado sin desbordar. Los tests lo comprueban con las guías de accesibilidad de Flutter.

## Galería

`example/` muestra todos los componentes con cambio de idioma, tema y escala de texto:

```sh
cd packages/design_system/example
flutter run
```
