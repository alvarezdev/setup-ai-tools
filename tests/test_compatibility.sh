#!/usr/bin/env bash
# Prueba que una plataforma nueva se agrega solo mediante los registros de datos.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp "$ROOT/verify-compatibility.sh" "$TMP/verify-compatibility.sh"
chmod +x "$TMP/verify-compatibility.sh"

printf '%s\n' \
  '# Plataforma|comando_cli|argumento_version|archivo_instrucciones|detalle' \
  'plataforma-prueba|cli-prueba|--version|PRUEBA.md|Plataforma de prueba' \
  > "$TMP/platforms.txt"

printf '%s\n' \
  '# Herramienta|plataforma|soporte|required_path|detalle' \
  'herramienta-prueba|plataforma-prueba|compatible|-|Registro descubierto dinamicamente' \
  > "$TMP/platform-compatibility.txt"

mkdir -p "$TMP/bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  '[ "${1:-}" = "--version" ] || exit 1' \
  'echo "cli-prueba 1.0.0"' \
  > "$TMP/bin/cli-prueba"
chmod +x "$TMP/bin/cli-prueba"

output="$(PATH="$TMP/bin:$PATH" "$TMP/verify-compatibility.sh" --platform plataforma-prueba --phase post)"
printf '%s\n' "$output" | grep -F 'Plataforma: plataforma-prueba - Plataforma de prueba (cli-prueba 1.0.0)' >/dev/null
printf '%s\n' "$output" | grep -F 'PASS  herramienta-prueba' >/dev/null
printf '%s\n' "$output" | grep -F 'Resultado: compatible' >/dev/null

set +e
unknown_output="$(PATH="$TMP/bin:$PATH" "$TMP/verify-compatibility.sh" --platform inexistente --phase post 2>&1)"
unknown_rc=$?
set -e
[ "$unknown_rc" -eq 1 ]
printf '%s\n' "$unknown_output" | grep -F 'plataforma-prueba (Plataforma de prueba)' >/dev/null

echo "PASS: registro generico de plataformas"
