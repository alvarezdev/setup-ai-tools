#!/usr/bin/env bash
# Regresiones de Cyber Neo: upstream fijado y wrapper solo para Claude.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINNED_COMMIT="dcac0a8f111954e543e1e66e02a222c0c489ca74"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -F "$expected" "$file" >/dev/null || fail "$file no contiene: $expected"
}

echo "TEST: fija Cyber Neo como upstream reproducible e ignorado"
assert_contains "$ROOT/third-party-repos.txt" "cyber-neo|https://github.com/Hainrixz/cyber-neo.git|main|$PINNED_COMMIT|pinned"
assert_contains "$ROOT/.gitignore" "/cyber-neo/"

echo "TEST: declara soporte nativo exclusivamente para Claude"
assert_contains "$ROOT/platform-compatibility.txt" "cyber-neo|claude|native|skills/cyber-neo/SKILL.md|"
if awk -F'|' '$1 == "cyber-neo" && $2 == "codex" { found = 1 } END { exit found ? 0 : 1 }' "$ROOT/platform-compatibility.txt"; then
  fail "Cyber Neo no debe publicarse para Codex"
fi

echo "TEST: publica un wrapper que preserva el upstream y redirige el reporte"
SKILL="$ROOT/skills/cyber-neo/SKILL.md"
[ -f "$SKILL" ] || fail "falta skills/cyber-neo/SKILL.md"
assert_contains "$SKILL" "name: cyber-neo"
assert_contains "$SKILL" "cyber-neo/skills/cyber-neo"
assert_contains "$SKILL" 'REPO_ROOT="$(cd "$(realpath "$CLAUDE_SKILL_DIR")/../.." && pwd)"'
assert_contains "$SKILL" 'REPORT_DIR="$HOME/Documents/reports-cyber-neo"'
assert_contains "$SKILL" 'mkdir -p "$REPORT_DIR"'
assert_contains "$SKILL" 'cyber-neo-report-{project-name}-{YYYY-MM-DD}.md'
assert_contains "$SKILL" "Never modify, delete, or create files in the target project"

CLAUDE_SKILL_DIR="$ROOT/skills/cyber-neo"
RESOLVED_REPO_ROOT="$(cd "$(realpath "$CLAUDE_SKILL_DIR")/../.." && pwd)"
[ "$RESOLVED_REPO_ROOT" = "$ROOT" ] || fail "la ruta del wrapper no resuelve la raiz del proyecto"

echo "TEST: installador enlaza el wrapper solo para Claude"
assert_contains "$ROOT/install.sh" 'cyber-neo|cyber-neo|$BASE/skills/cyber-neo'
if sed -n '/CODEX_SKILL_LINKS="/,/"$/p' "$ROOT/install.sh" | grep -F 'cyber-neo|' >/dev/null; then
  fail "install.sh publica Cyber Neo para Codex"
fi

echo "TEST: documenta el destino y la restriccion de solo lectura"
assert_contains "$ROOT/PROJECT_INSTRUCTIONS.md" "~/Documents/reports-cyber-neo/"
assert_contains "$ROOT/GUIDE.md" "~/Documents/reports-cyber-neo/"

echo "OK: contrato Cyber Neo valido"
