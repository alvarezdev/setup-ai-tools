#!/usr/bin/env bash
# Regresiones de Graphify: contrato local, sin ejecutar instaladores upstream.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -F "$expected" "$file" >/dev/null || fail "$file no contiene: $expected"
}

echo "TEST: fija Graphify y registra soporte nativo para ambas plataformas"
# shellcheck disable=SC1091
. "$ROOT/tool-versions.env"
[ "${GRAPHIFY_VERSION:-}" = "0.9.16" ] || fail "GRAPHIFY_VERSION debe fijar 0.9.16"
assert_contains "$ROOT/platform-compatibility.txt" "graphify|claude|native|skills/graphify/SKILL.md|"
assert_contains "$ROOT/platform-compatibility.txt" "graphify|codex|native|skills/graphify/SKILL.md|"

echo "TEST: publica un wrapper propio con frontmatter portable"
SKILL="$ROOT/skills/graphify/SKILL.md"
[ -f "$SKILL" ] || fail "falta skills/graphify/SKILL.md"
[ "$(sed -n '1p' "$SKILL")" = "---" ] || fail "Graphify no tiene frontmatter"
assert_contains "$SKILL" "name: graphify"
assert_contains "$SKILL" "description: Use when"
assert_contains "$SKILL" "graphify query"
assert_contains "$SKILL" 'graphify path "install.sh script" "ensure_skill_link()"'
assert_contains "$SKILL" "graphify explain"
assert_contains "$SKILL" "antes de modificar"

echo "TEST: el instalador solo provisiona el CLI con uv y enlaza la skill propia"
assert_contains "$ROOT/install.sh" 'uv tool install --python 3.12 "graphifyy==$GRAPHIFY_VERSION"'
assert_contains "$ROOT/install.sh" 'graphify|graphify|$BASE/skills/graphify'
if rg -n 'graphify (install|claude install|codex install)|graphify install --platform' "$ROOT/install.sh" >/dev/null; then
  fail "install.sh invoca un instalador upstream de Graphify"
fi

echo "TEST: update consulta la version de Graphify desde PyPI"
assert_contains "$ROOT/update.sh" 'https://pypi.org/pypi/graphifyy/json'
assert_contains "$ROOT/update.sh" 'GRAPHIFY_VERSION'

echo "TEST: instrucciones generadas priorizan el grafo y verifican fuentes"
assert_contains "$ROOT/PROJECT_INSTRUCTIONS.md" "Graphify"
assert_contains "$ROOT/PROJECT_INSTRUCTIONS.md" "Antes de una busqueda amplia"
assert_contains "$ROOT/PROJECT_INSTRUCTIONS.md" "verifica los archivos fuente"
assert_contains "$ROOT/PROJECT_INSTRUCTIONS.md" "Si no hay un grafo actual"

echo "TEST: ignora insumos y salidas que no deben versionarse"
IGNORE="$ROOT/.graphifyignore"
[ -f "$IGNORE" ] || fail "falta .graphifyignore"
for pattern in superpowers/ prompt-master/ 'adapters/codex/*/upstream' .git/ graphify-out/; do
  assert_contains "$IGNORE" "$pattern"
done
assert_contains "$ROOT/.gitignore" "/graphify-out/"

echo "OK: contrato Graphify valido"
