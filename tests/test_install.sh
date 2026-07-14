#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local expected="$2"
  grep -F "$expected" "$file" >/dev/null || fail "$file no contiene: $expected"
}

PROJECT="$TMP/project"
ORIGIN="$TMP/superpowers-origin.git"
SOURCE="$TMP/superpowers-source"
MOCK_BIN="$TMP/mock-bin"
MOCK_LOG="$TMP/npx.log"
mkdir -p "$PROJECT" "$SOURCE" "$MOCK_BIN"

cp "$ROOT/install.sh" \
  "$ROOT/verify-compatibility.sh" \
  "$ROOT/platforms.txt" \
  "$ROOT/platform-compatibility.txt" \
  "$ROOT/PROJECT_INSTRUCTIONS.md" \
  "$ROOT/tool-versions.env" \
  "$PROJECT/"
chmod +x "$PROJECT/install.sh" "$PROJECT/verify-compatibility.sh"

git init -q -b main "$SOURCE"
mkdir -p "$SOURCE/skills/using-superpowers" "$SOURCE/hooks"
printf '%s\n' '# using-superpowers' > "$SOURCE/skills/using-superpowers/SKILL.md"
printf '%s\n' '#!/usr/bin/env sh' > "$SOURCE/hooks/run-hook.cmd"
git -C "$SOURCE" add .
git -C "$SOURCE" -c user.name=Test -c user.email=test@example.com commit -q -m baseline
PINNED_COMMIT="$(git -C "$SOURCE" rev-parse HEAD)"
printf '%s\n' 'newer upstream content' > "$SOURCE/newer.txt"
git -C "$SOURCE" add .
git -C "$SOURCE" -c user.name=Test -c user.email=test@example.com commit -q -m newer
NEWER_COMMIT="$(git -C "$SOURCE" rev-parse HEAD)"
git clone -q --bare "$SOURCE" "$ORIGIN"
git clone -q "$ORIGIN" "$PROJECT/superpowers"

mkdir -p \
  "$PROJECT/skills/commit-style" \
  "$PROJECT/prompt-master" \
  "$PROJECT/abogado-del-diablo/skills/abogado-del-diablo" \
  "$PROJECT/context7/packages/mcp" \
  "$PROJECT/context7/plugins/codex/context7/skills/context7-mcp" \
  "$PROJECT/the-architect" \
  "$PROJECT/claude-token-efficient"
printf '%s\n' '# skill' > "$PROJECT/skills/commit-style/SKILL.md"
printf '%s\n' '# skill' > "$PROJECT/prompt-master/SKILL.md"
printf '%s\n' '# skill' > "$PROJECT/abogado-del-diablo/skills/abogado-del-diablo/SKILL.md"
printf '%s\n' '{}' > "$PROJECT/context7/packages/mcp/package.json"
printf '%s\n' '# context7' > "$PROJECT/context7/plugins/codex/context7/skills/context7-mcp/SKILL.md"
printf '%s\n' '# architect' > "$PROJECT/the-architect/CLAUDE.md"
printf '%s\n' '# rules' > "$PROJECT/claude-token-efficient/CLAUDE.md"

printf '%s\n' \
  '# fixture manifest' \
  "superpowers|$ORIGIN|main|$PINNED_COMMIT|pinned" \
  > "$PROJECT/third-party-repos.txt"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [ "${1:-}" = "--version" ]; then echo "claude-test 1.0"; exit 0; fi' \
  'if [ "${1:-} ${2:-} ${3:-}" = "mcp get context7" ]; then exit 0; fi' \
  'exit 0' \
  > "$MOCK_BIN/claude"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [ "${1:-}" = "--version" ]; then echo "codex-test 1.0"; exit 0; fi' \
  'if [ "${1:-} ${2:-} ${3:-}" = "mcp get context7" ]; then exit 0; fi' \
  'exit 0' \
  > "$MOCK_BIN/codex"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$MOCK_LOG"' \
  'exit 0' \
  > "$MOCK_BIN/npx"
chmod +x "$MOCK_BIN/claude" "$MOCK_BIN/codex" "$MOCK_BIN/npx"
export MOCK_LOG

run_install() {
  local home="$1"
  PATH="$MOCK_BIN:$PATH" HOME="$home" "$PROJECT/install.sh" --platform claude
}

echo "TEST: reconcilia un repo existente con el commit fijado"
HOME_ONE="$TMP/home-one"
mkdir -p "$HOME_ONE/.claude"
printf '%s\n' '{"hooks":{"SessionStart":[{"matcher":"startup"}]}}' > "$HOME_ONE/.claude/settings.json"
[ "$(git -C "$PROJECT/superpowers" rev-parse HEAD)" = "$NEWER_COMMIT" ] || fail "fixture no inicio desalineado"
run_install "$HOME_ONE" > "$TMP/install-one.log"
[ "$(git -C "$PROJECT/superpowers" rev-parse HEAD)" = "$PINNED_COMMIT" ] || fail "install no reconcilio el commit"

echo "TEST: repara SessionStart incompleto sin perder el grupo existente"
python3 - "$HOME_ONE/.claude/settings.json" "$PROJECT/superpowers" <<'PY'
import json
import sys

path, root = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
groups = data["hooks"]["SessionStart"]
assert groups[0] == {"matcher": "startup"}
commands = [
    hook.get("command")
    for group in groups
    for hook in group.get("hooks", [])
    if isinstance(hook, dict)
]
assert commands == [f"{root}/hooks/run-hook.cmd session-start"]
PY

echo "TEST: una segunda instalacion no duplica hooks ni symlinks"
run_install "$HOME_ONE" > "$TMP/install-two.log"
python3 - "$HOME_ONE/.claude/settings.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
commands = [
    hook.get("command", "")
    for group in data["hooks"]["SessionStart"]
    for hook in group.get("hooks", [])
    if isinstance(hook, dict) and "run-hook.cmd session-start" in hook.get("command", "")
]
assert len(commands) == 1
PY
assert_file_contains "$MOCK_LOG" "claude-mem@13.10.4 install"
assert_file_contains "$MOCK_LOG" "claude-mem@13.10.4 install --ide claude-code"
assert_file_contains "$MOCK_LOG" "claude-mem@13.10.4 start"

echo "TEST: provisiona Codex sin configurar Claude"
HOME_CODEX="$TMP/home-codex"
mkdir -p "$HOME_CODEX"
PATH="$MOCK_BIN:$PATH" HOME="$HOME_CODEX" CODEX_HOME="$HOME_CODEX/.codex" \
  "$PROJECT/install.sh" --platform codex > "$TMP/install-codex.log"
[ -L "$HOME_CODEX/.codex/skills/commit-style" ] || fail "Codex no recibio commit-style"
[ -L "$HOME_CODEX/.codex/skills/using-superpowers" ] || fail "Codex no recibio superpowers"
[ -L "$HOME_CODEX/.codex/skills/context7-mcp" ] || fail "Codex no recibio Context7"
[ ! -e "$HOME_CODEX/.claude/settings.json" ] || fail "instalar solo Codex modifico settings de Claude"
assert_file_contains "$MOCK_LOG" "claude-mem@13.10.4 install --ide codex-cli"

echo "TEST: install.sh sin opciones autodetecta y configura ambas plataformas"
HOME_AUTO="$TMP/home-auto"
mkdir -p "$HOME_AUTO"
PATH="$MOCK_BIN:$PATH" HOME="$HOME_AUTO" CODEX_HOME="$HOME_AUTO/.codex" \
  "$PROJECT/install.sh" > "$TMP/install-auto.log"
[ -f "$PROJECT/CLAUDE.md" ] || fail "autodeteccion no genero CLAUDE.md"
[ -f "$PROJECT/AGENTS.md" ] || fail "autodeteccion no genero AGENTS.md"
[ -L "$HOME_AUTO/.claude/skills/commit-style" ] || fail "autodeteccion no provisiono Claude"
[ -L "$HOME_AUTO/.codex/skills/commit-style" ] || fail "autodeteccion no provisiono Codex"
assert_file_contains "$TMP/install-auto.log" "Instalacion terminada"

echo "TEST: conserva un symlink ajeno y continua con las demas herramientas"
HOME_TWO="$TMP/home-two"
FOREIGN_TARGET="$TMP/foreign-skill"
mkdir -p "$HOME_TWO/.claude/skills" "$FOREIGN_TARGET"
ln -s "$FOREIGN_TARGET" "$HOME_TWO/.claude/skills/commit-style"
run_install "$HOME_TWO" > "$TMP/foreign-link.log" 2>&1
[ -L "$HOME_TWO/.claude/skills/commit-style" ] || fail "symlink ajeno fue eliminado"
[ "$(readlink "$HOME_TWO/.claude/skills/commit-style")" = "$FOREIGN_TARGET" ] || fail "symlink ajeno fue alterado"
assert_file_contains "$TMP/foreign-link.log" "Conflictos conservados"
assert_file_contains "$TMP/foreign-link.log" "claude/commit-style"

echo "TEST: conserva una carpeta real y continua con las demas herramientas"
HOME_THREE="$TMP/home-three"
mkdir -p "$HOME_THREE/.claude/skills/commit-style"
printf '%s\n' 'preserve me' > "$HOME_THREE/.claude/skills/commit-style/user-file.txt"
run_install "$HOME_THREE" > "$TMP/real-directory.log" 2>&1
assert_file_contains "$HOME_THREE/.claude/skills/commit-style/user-file.txt" "preserve me"
assert_file_contains "$TMP/real-directory.log" "destino real"

echo "TEST: reutiliza Superpowers externo cuando origin y commit coinciden"
EXTERNAL_SAME="$TMP/external-superpowers-same"
git clone -q "$ORIGIN" "$EXTERNAL_SAME"
git -C "$EXTERNAL_SAME" checkout -q --detach "$PINNED_COMMIT"
HOME_SAME="$TMP/home-superpowers-same"
mkdir -p "$HOME_SAME/.claude/skills"
ln -s "$EXTERNAL_SAME/skills/using-superpowers" "$HOME_SAME/.claude/skills/using-superpowers"
run_install "$HOME_SAME" > "$TMP/superpowers-same.log"
[ "$(readlink "$HOME_SAME/.claude/skills/using-superpowers")" = "$EXTERNAL_SAME/skills/using-superpowers" ] \
  || fail "no reutilizo Superpowers externo compatible"
assert_file_contains "$TMP/superpowers-same.log" "REUSE claude/superpowers"
python3 - "$HOME_SAME/.claude/settings.json" "$EXTERNAL_SAME" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
assert data["env"]["CLAUDE_PLUGIN_ROOT"] == sys.argv[2]
PY

echo "TEST: conserva Superpowers externo diferente y permite migrarlo explicitamente"
EXTERNAL_DIFFERENT="$TMP/external-superpowers-different"
git clone -q "$ORIGIN" "$EXTERNAL_DIFFERENT"
[ "$(git -C "$EXTERNAL_DIFFERENT" rev-parse HEAD)" = "$NEWER_COMMIT" ] \
  || fail "fixture externo no usa el commit diferente"
HOME_DIFFERENT="$TMP/home-superpowers-different"
mkdir -p "$HOME_DIFFERENT/.claude/skills"
ln -s "$EXTERNAL_DIFFERENT/skills/using-superpowers" "$HOME_DIFFERENT/.claude/skills/using-superpowers"
run_install "$HOME_DIFFERENT" > "$TMP/superpowers-different.log" 2>&1
[ "$(readlink "$HOME_DIFFERENT/.claude/skills/using-superpowers")" = "$EXTERNAL_DIFFERENT/skills/using-superpowers" ] \
  || fail "altero Superpowers externo sin autorizacion"
[ -L "$HOME_DIFFERENT/.claude/skills/commit-style" ] \
  || fail "el conflicto de Superpowers detuvo otras herramientas"
assert_file_contains "$TMP/superpowers-different.log" "externa=$ORIGIN@$NEWER_COMMIT"

PATH="$MOCK_BIN:$PATH" HOME="$HOME_DIFFERENT" \
  "$PROJECT/install.sh" --platform claude --migrate-tool superpowers \
  > "$TMP/superpowers-migrated.log"
[ "$(readlink "$HOME_DIFFERENT/.claude/skills/using-superpowers")" = "$PROJECT/superpowers/skills/using-superpowers" ] \
  || fail "la migracion explicita no adopto Superpowers"
MIGRATION_LOG="$HOME_DIFFERENT/.local/state/setup-ai-tools/migrations.log"
assert_file_contains "$MIGRATION_LOG" "previous_target=$EXTERNAL_DIFFERENT"
assert_file_contains "$MIGRATION_LOG" "previous_commit=$NEWER_COMMIT"
assert_file_contains "$MIGRATION_LOG" "new_target=$PROJECT/superpowers"

echo "TEST: aplica la misma proteccion y migracion de Superpowers en Codex"
HOME_CODEX_DIFFERENT="$TMP/home-codex-superpowers-different"
mkdir -p "$HOME_CODEX_DIFFERENT/.codex/skills"
ln -s "$EXTERNAL_DIFFERENT/skills/using-superpowers" \
  "$HOME_CODEX_DIFFERENT/.codex/skills/using-superpowers"
PATH="$MOCK_BIN:$PATH" HOME="$HOME_CODEX_DIFFERENT" CODEX_HOME="$HOME_CODEX_DIFFERENT/.codex" \
  "$PROJECT/install.sh" --platform codex > "$TMP/codex-superpowers-different.log" 2>&1
[ "$(readlink "$HOME_CODEX_DIFFERENT/.codex/skills/using-superpowers")" = "$EXTERNAL_DIFFERENT/skills/using-superpowers" ] \
  || fail "Codex altero Superpowers externo sin autorizacion"
[ -L "$HOME_CODEX_DIFFERENT/.codex/skills/commit-style" ] \
  || fail "el conflicto de Superpowers detuvo otras skills de Codex"
assert_file_contains "$TMP/codex-superpowers-different.log" "codex/superpowers"

PATH="$MOCK_BIN:$PATH" HOME="$HOME_CODEX_DIFFERENT" CODEX_HOME="$HOME_CODEX_DIFFERENT/.codex" \
  "$PROJECT/install.sh" --platform codex --migrate-tool superpowers \
  > "$TMP/codex-superpowers-migrated.log"
[ "$(readlink "$HOME_CODEX_DIFFERENT/.codex/skills/using-superpowers")" = "$PROJECT/superpowers/skills/using-superpowers" ] \
  || fail "Codex no migro Superpowers con autorizacion explicita"
assert_file_contains "$HOME_CODEX_DIFFERENT/.local/state/setup-ai-tools/migrations.log" "platform=codex"

echo "TEST: rechaza un repositorio con origin ajeno"
HOME_FOUR="$TMP/home-four"
git -C "$PROJECT/superpowers" remote set-url origin "$TMP/foreign-origin.git"
if run_install "$HOME_FOUR" > "$TMP/foreign-origin.log" 2>&1; then
  fail "install acepto un origin ajeno"
fi
git -C "$PROJECT/superpowers" remote set-url origin "$ORIGIN"

echo "TEST: una configuracion invalida no se sobrescribe"
HOME_FIVE="$TMP/home-five"
mkdir -p "$HOME_FIVE/.claude"
printf '%s\n' '{"hooks":[]}' > "$HOME_FIVE/.claude/settings.json"
BEFORE_HASH="$(shasum -a 256 "$HOME_FIVE/.claude/settings.json" | awk '{print $1}')"
if run_install "$HOME_FIVE" > "$TMP/invalid-settings.log" 2>&1; then
  fail "install acepto settings.json invalido"
fi
AFTER_HASH="$(shasum -a 256 "$HOME_FIVE/.claude/settings.json" | awk '{print $1}')"
[ "$BEFORE_HASH" = "$AFTER_HASH" ] || fail "settings.json invalido fue modificado"

echo "TEST: migra una instalacion al mover el proyecto para Claude y Codex"
OLD_PROJECT="$PROJECT"
STATE_DIR="$HOME_AUTO/.local/state/setup-ai-tools"
STATE_FILE="$STATE_DIR/managed-roots"
[ -f "$STATE_FILE" ] || fail "install no registro la ruta administrada"

echo "TEST: importa el estado y el historial creados bajo setup-skills"
LEGACY_STATE_DIR="$HOME_AUTO/.local/state/setup-skills"
mkdir -p "$(dirname "$LEGACY_STATE_DIR")"
mv "$STATE_DIR" "$LEGACY_STATE_DIR"
{
  printf '%s\n' 'setup-skills-managed-roots-v1'
  tail -n +2 "$LEGACY_STATE_DIR/managed-roots"
} > "$LEGACY_STATE_DIR/managed-roots.new"
mv "$LEGACY_STATE_DIR/managed-roots.new" "$LEGACY_STATE_DIR/managed-roots"
printf '%s\n' 'legacy-history=preserved' > "$LEGACY_STATE_DIR/migrations.log"

HOME_DISCOVERY="$TMP/home-legacy-discovery"
mkdir -p "$HOME_DISCOVERY/.claude/skills"
ln -s "$OLD_PROJECT/skills/commit-style" "$HOME_DISCOVERY/.claude/skills/commit-style"
ln -s "$OLD_PROJECT/superpowers/skills/using-superpowers" \
  "$HOME_DISCOVERY/.claude/skills/using-superpowers"

mkdir -p "$TMP/relocated"
PROJECT="$TMP/relocated/setup-ai-tools"
mv "$OLD_PROJECT" "$PROJECT"

PATH="$MOCK_BIN:$PATH" HOME="$HOME_AUTO" CODEX_HOME="$HOME_AUTO/.codex" \
  "$PROJECT/install.sh" --platform claude > "$TMP/install-relocated-claude.log"
[ "$(readlink "$HOME_AUTO/.claude/skills/commit-style")" = "$PROJECT/skills/commit-style" ] \
  || fail "Claude no migro commit-style a la nueva ruta"
[ "$(readlink "$HOME_AUTO/.codex/skills/commit-style")" = "$OLD_PROJECT/skills/commit-style" ] \
  || fail "la migracion de Claude altero Codex antes de seleccionarlo"
assert_file_contains "$STATE_FILE" "$OLD_PROJECT"
assert_file_contains "$STATE_FILE" "$PROJECT"
assert_file_contains "$HOME_AUTO/.local/state/setup-ai-tools/migrations.log" "legacy-history=preserved"
assert_file_contains "$TMP/install-relocated-claude.log" "Estado anterior importado desde: $LEGACY_STATE_DIR"

PATH="$MOCK_BIN:$PATH" HOME="$HOME_AUTO" CODEX_HOME="$HOME_AUTO/.codex" \
  "$PROJECT/install.sh" --platform codex > "$TMP/install-relocated-codex.log"
[ "$(readlink "$HOME_AUTO/.codex/skills/commit-style")" = "$PROJECT/skills/commit-style" ] \
  || fail "Codex no migro commit-style a la nueva ruta"
assert_file_contains "$TMP/install-relocated-codex.log" "MIG Codex/commit-style"

run_install "$HOME_DISCOVERY" > "$TMP/install-legacy-discovery.log"
[ "$(readlink "$HOME_DISCOVERY/.claude/skills/commit-style")" = "$PROJECT/skills/commit-style" ] \
  || fail "no migro una instalacion sin archivo de estado"
assert_file_contains "$TMP/install-legacy-discovery.log" "Instalacion anterior detectada en: $OLD_PROJECT"

python3 - "$HOME_AUTO/.claude/settings.json" "$PROJECT/superpowers" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
root = sys.argv[2]
assert data["env"]["CLAUDE_PLUGIN_ROOT"] == root
commands = [
    hook.get("command")
    for group in data["hooks"]["SessionStart"]
    for hook in group.get("hooks", [])
    if isinstance(hook, dict)
]
assert commands == [f"{root}/hooks/run-hook.cmd session-start"]
PY

echo "PASS: todas las pruebas de install.sh"
