# design_system

Sistema de diseño de la app: tokens, temas claro y oscuro y componentes accesibles. Solo depende de Flutter y de `core_ui`, que aporta los textos comunes («Cancelar», «Confirmar»…).

Los componentes no conocen la app: reciben todo por parámetros y devuelven resultados con callbacks o con el valor del diálogo. La navegación, los cubits y los snackbars los pone la pantalla que los usa.

## Contenido

**Tokens y tema**
- `AppColors`, `AppSpacing` (`xs`…`xl`), `AppRadii` y `AppSizes` (`minTouchTarget` de 48).
- `AppTheme.light` y `AppTheme.dark`.

**Componentes**

| Componente | Para qué |
| :--- | :--- |
| `AppButton` | Botón principal, secundario o de texto (`AppButtonVariant`), con icono opcional. |
| `AppIconButton` | Botón de icono con `tooltip` obligatorio. |
| `AppTextField` | Campo de texto con etiqueta y error. |
| `AppCard` | Tarjeta, pulsable si recibe `onTap` (con `semanticLabel`). |
| `AppSectionHeader` | Título de sección con acción opcional a la derecha. |
| `AppStatusView`, `AppLoadingView` | Estados vacío, de error y de carga. |
| `AppShortcutTile`, `AppShortcutGrid` | Accesos rápidos en una grilla adaptable (`columnsFor`). |
| `AppSettingsSection`, `AppSettingsTile`, `AppChoiceSelector<T>` | Pantallas de configuración y elección entre pocas opciones. |
| `AppFilterChips<T>` | Elegir varias opciones a la vez (filtros). |
| `AppBadge` | Etiqueta corta con tono `critical`, `warning` o `neutral`. |
| `AppCheckTile` | Fila que se marca como hecha con su casilla. |

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
