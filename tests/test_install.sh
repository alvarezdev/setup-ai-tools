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
  'printf "%s\n" "$*" >> "$MOCK_LOG"' \
  'exit 0' \
  > "$MOCK_BIN/npx"
chmod +x "$MOCK_BIN/claude" "$MOCK_BIN/npx"
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

echo "TEST: rechaza y conserva un symlink administrado por otra fuente"
HOME_TWO="$TMP/home-two"
FOREIGN_TARGET="$TMP/foreign-skill"
mkdir -p "$HOME_TWO/.claude/skills" "$FOREIGN_TARGET"
ln -s "$FOREIGN_TARGET" "$HOME_TWO/.claude/skills/commit-style"
if run_install "$HOME_TWO" > "$TMP/foreign-link.log" 2>&1; then
  fail "install acepto un symlink ajeno"
fi
[ -L "$HOME_TWO/.claude/skills/commit-style" ] || fail "symlink ajeno fue eliminado"
[ "$(readlink "$HOME_TWO/.claude/skills/commit-style")" = "$FOREIGN_TARGET" ] || fail "symlink ajeno fue alterado"

echo "TEST: rechaza y conserva una carpeta real en el destino"
HOME_THREE="$TMP/home-three"
mkdir -p "$HOME_THREE/.claude/skills/commit-style"
printf '%s\n' 'preserve me' > "$HOME_THREE/.claude/skills/commit-style/user-file.txt"
if run_install "$HOME_THREE" > "$TMP/real-directory.log" 2>&1; then
  fail "install acepto una carpeta real"
fi
assert_file_contains "$HOME_THREE/.claude/skills/commit-style/user-file.txt" "preserve me"

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

echo "PASS: todas las pruebas de install.sh"
