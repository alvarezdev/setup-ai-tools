#!/usr/bin/env bash
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

assert_adapter() {
  local name="$1"
  local relative_upstream="$2"
  local skill="$ROOT/adapters/codex/$name/SKILL.md"
  local upstream="$ROOT/adapters/codex/$name/upstream"

  [ -f "$skill" ] || fail "falta wrapper para $name"
  [ "$(head -n 1 "$skill")" = "---" ] || fail "$name no tiene frontmatter"
  assert_contains "$skill" "name: $name"
  if grep -q '^allowed-tools:' "$skill"; then
    fail "$name no debe declarar allowed-tools exclusivos de Claude"
  fi
  [ -L "$upstream" ] || fail "$name no tiene symlink upstream"
  [ "$(readlink "$upstream")" = "$relative_upstream" ] \
    || fail "$name upstream no usa el destino relativo esperado"
  [ -f "$upstream/SKILL.md" ] || fail "$name no puede leer su skill upstream"
  assert_contains "$skill" "upstream/SKILL.md"
}

echo "TEST: prompt-master tiene adaptador Codex autocontenido"
assert_adapter prompt-master ../../../prompt-master
PROMPT_SKILL="$ROOT/adapters/codex/prompt-master/SKILL.md"
assert_contains "$PROMPT_SKILL" "alcance"
assert_contains "$PROMPT_SKILL" "restricciones"
assert_contains "$PROMPT_SKILL" "verificación"
assert_contains "$PROMPT_SKILL" "condición de terminación"

echo "TEST: abogado-del-diablo traduce capacidades a Codex"
assert_adapter abogado-del-diablo ../../../abogado-del-diablo/skills/abogado-del-diablo
ABOGADO_SKILL="$ROOT/adapters/codex/abogado-del-diablo/SKILL.md"
assert_contains "$ABOGADO_SKILL" "rg"
assert_contains "$ABOGADO_SKILL" "subagentes"
assert_contains "$ABOGADO_SKILL" "autorizados"
assert_contains "$ABOGADO_SKILL" "búsqueda web"
assert_contains "$ABOGADO_SKILL" "pregunta directa"

echo "TEST: the-architect tiene workspace Codex sin depender de Claude"
ARCHITECT_ROOT="$ROOT/adapters/codex/the-architect"
ARCHITECT_AGENTS="$ARCHITECT_ROOT/AGENTS.md"
ARCHITECT_UPSTREAM="$ARCHITECT_ROOT/upstream"
[ -f "$ARCHITECT_AGENTS" ] || fail "falta AGENTS.md para the-architect"
[ -L "$ARCHITECT_UPSTREAM" ] || fail "the-architect no tiene symlink upstream"
[ "$(readlink "$ARCHITECT_UPSTREAM")" = "../../../the-architect" ] \
  || fail "the-architect upstream no usa el destino relativo esperado"
[ -f "$ARCHITECT_UPSTREAM/questions/phase-1-discovery.md" ] \
  || fail "the-architect no puede leer sus preguntas upstream"
[ -f "$ARCHITECT_ROOT/templates/agents-md-template.md" ] \
  || fail "falta plantilla AGENTS.md para proyectos destino"
[ -f "$ARCHITECT_ROOT/references/skills-registry.md" ] \
  || fail "falta registro Codex de capacidades"
assert_contains "$ARCHITECT_AGENTS" "upstream/questions/phase-1-discovery.md"
assert_contains "$ARCHITECT_AGENTS" "upstream/questions/phase-2-branches.md"
assert_contains "$ARCHITECT_AGENTS" "upstream/questions/phase-3-confirmation.md"
assert_contains "$ARCHITECT_AGENTS" "upstream/templates/blueprint-template.md"
assert_contains "$ARCHITECT_AGENTS" "templates/agents-md-template.md"
assert_contains "$ARCHITECT_AGENTS" "references/skills-registry.md"
assert_contains "$ARCHITECT_AGENTS" "upstream/output/"
assert_contains "$ARCHITECT_AGENTS" "AGENTS.md"
if grep -F "Use /deep-research" "$ARCHITECT_AGENTS" >/dev/null \
  || grep -F "Use /ui-ux-pro-max" "$ARCHITECT_AGENTS" >/dev/null \
  || grep -F "Use /find-skills" "$ARCHITECT_AGENTS" >/dev/null; then
  fail "the-architect conserva comandos slash exclusivos de Claude"
fi

echo "TEST: manifiesto declara los adaptadores Codex como compatibles"
assert_contains "$ROOT/platform-compatibility.txt" "prompt-master|codex|compatible|adapters/codex/prompt-master/SKILL.md|"
assert_contains "$ROOT/platform-compatibility.txt" "abogado-del-diablo|codex|compatible|adapters/codex/abogado-del-diablo/SKILL.md|"
assert_contains "$ROOT/platform-compatibility.txt" "the-architect|codex|compatible|adapters/codex/the-architect/AGENTS.md|"
assert_contains "$ROOT/platform-compatibility.txt" "claude-token-efficient|codex|compatible|claude-token-efficient/CLAUDE.md|"

echo "OK: adaptadores Codex validos"
