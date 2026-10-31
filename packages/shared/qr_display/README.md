# qr_display

Muestra un texto como código QR. Widget agnóstico: recibe por parámetros todo lo que necesita y no usa cubits, navegación ni textos propios.

Codifica con [`qr`](https://pub.dev/packages/qr) (solo genera los módulos) y dibuja con un `CustomPainter`. No usa `qr_flutter`, que lleva años sin publicar versiones.

## Uso

```dart
AppQrCode(
  data: householdInvitation, // el texto que se quiere compartir
  semanticLabel: joinCodeLabel, // lo anuncia el lector de pantalla
  size: 240, // opcional: sin él ocupa el ancho disponible
)
```

| Parámetro | Por defecto | |
| :--- | :--- | :--- |
| `data` | | Texto que codifica. Si no cabe en un QR, lanza `ArgumentError` al construirse. |
| `semanticLabel` | | Lo que anuncia el lector de pantalla. El contenido no se lee. |
| `size` | ancho disponible | Lado en píxeles lógicos. |
| `errorLevel` | `QrErrorLevel.medium` | Cuánto del código puede perderse y seguir leyéndose (`low` ~7 %, `medium` ~15 %, `quartile` ~25 %, `high` ~30 %). |
| `color` / `backgroundColor` | negro / blanco | Se mantienen en el tema oscuro: muchos lectores no leen un QR invertido. |
| `quietZone` | 4 | Margen en módulos que pide el estándar. |

También se exportan:

- `QrMatrix.encode(data, errorLevel:)`: los módulos ya codificados (`size`, `isDark(row, column)`), para dibujarlos de otra forma.
- `QrPainter`: el `CustomPainter` que pinta una `QrMatrix` centrada.

**Capacidad:** con `medium` caben 2331 bytes (versión 40). Un texto de 2000 caracteres base64url (el máximo que acepta el lector de identificadores es 2048) cabe.

## Tests

```sh
flutter test
```

Comprueban la codificación (tamaño y patrones de las esquinas), la accesibilidad, el tamaño y lo que se pinta.
