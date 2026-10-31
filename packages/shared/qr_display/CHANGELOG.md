# Changelog

## 0.1.0 - 2026-10-31

### Añadido

- `AppQrCode`: widget agnóstico que dibuja un texto como código QR cuadrado, con etiqueta para el lector de pantalla, lado fijo o el ancho disponible, colores (negro sobre blanco por defecto, también en tema oscuro) y margen en módulos (4 por defecto).
- `QrMatrix.encode`: codifica un texto en los módulos del QR con un `QrErrorLevel` (`medium` por defecto). Lanza `ArgumentError` si no cabe.
- `QrPainter`: `CustomPainter` que pinta una `QrMatrix` centrada, para usarla fuera de `AppQrCode`.
- README del paquete.
