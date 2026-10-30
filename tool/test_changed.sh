#!/usr/bin/env bash
# Pruebas de lo que cambia respecto a una rama base (p. ej. origin/main): los
# paquetes modificados y todos los que dependen de ellos. Si cambia algo fuera
# de packages/ y apps/ que no sea documentación (pubspec.yaml raíz, tool/,
# workflows...), ejecuta todas las pruebas.
#
# Uso: tool/test_changed.sh origin/main
set -euo pipefail

base="${1:?Indica la rama base, p. ej. origin/main}"
changed="$(git diff --name-only "$base"...HEAD)"

if echo "$changed" | grep -vE '^(packages|apps)/|\.md$|^specs/' | grep -q .; then
  echo "Hay cambios fuera de packages/ y apps/: se ejecutan todas las pruebas."
  exec melos run test
fi

# Los dependientes se añaden después de los filtros normales: el tipo de
# paquete y la carpeta test/ se filtran con --post-filter.
run_tests() {
  local kind="$1" label="$2"
  shift 2
  local filters=(--diff="$base" --include-dependents --post-filter="$kind" --post-filter=dir-exists=test)
  local packages
  packages="$(melos list "${filters[@]}" --parsable 2>/dev/null || true)"
  if [ -z "$packages" ]; then
    echo "Ningún paquete $label con pruebas afectado."
    return
  fi
  echo "Paquetes $label afectados:"
  echo "$packages" | sed "s#^$PWD/#  #"
  melos exec "${filters[@]}" --concurrency=1 -- "$@"
}

run_tests flutter Flutter flutter test
run_tests no-flutter "Dart puro" dart test
