# Changelog

## 0.1.0 - 2026-10-28

### Añadido

- `ShareService`: contrato para compartir texto (`shareText`), abrir WhatsApp con un texto (`openWhatsApp`, `false` si no está instalado), y compartir o guardar un archivo (`shareFile` y `saveFile`, que devuelve `SaveFileResult.saved` o `cancelled`).
- `ShareFile`: archivo de texto que se comparte o se guarda (`ShareFile.markdown` para un `.md`). Valida el nombre del archivo.
- `package:core_share/testing.dart`: batería de contrato `shareServiceContract` y `FakeShareService`, que guarda lo compartido.
