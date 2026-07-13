#!/usr/bin/env bash
# Auditoria offline de los problemas detectados durante la revision del proyecto.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

bash -n install.sh
bash -n update.sh
bash -n verify-compatibility.sh
bash -n tests/test_install.sh
bash -n tests/test_compatibility.sh
bash -n tests/test_instructions.sh
pass "sintaxis Bash"

git diff --check
git diff --cached --check
pass "diff sin errores de espacios"

if rg -n 'Development/AI/' README.md GUIDE.md PROJECT_INSTRUCTIONS.md install.sh update.sh verify-compatibility.sh tests/test_install.sh tests/test_instructions.sh >/dev/null; then
  fail "quedan rutas con Development/AI/"
fi
pass "rutas Development/ai consistentes"

if rg -n 'rm -rf "\$link"' install.sh >/dev/null; then
  fail "install.sh todavia elimina destinos de skills con rm -rf"
fi
pass "symlinks sin eliminacion destructiva"

if rg -n 'ya existe, se omite' install.sh >/dev/null; then
  fail "install.sh todavia omite repos existentes sin validarlos"
fi
rg -n 'reconcile_repo|rev-parse HEAD|remote.origin.url' install.sh >/dev/null
pass "repositorios existentes reconciliados contra origin y commit"

rg -n 'tempfile.mkstemp|os.replace|target_group' install.sh >/dev/null
pass "settings.json validado y reemplazado atomicamente"

# shellcheck disable=SC1091
. ./tool-versions.env
case "$CLAUDE_MEM_VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) fail "CLAUDE_MEM_VERSION no esta fijada" ;;
esac
rg -n 'claude-mem@\$CLAUDE_MEM_VERSION' install.sh >/dev/null
pass "claude-mem fijado en tool-versions.env"

rg -n 'git clone https://github.com/alvarezdev/setup-skills.git && cd setup-skills && ./install.sh' README.md >/dev/null
rg -n 'CODEX_SKILLS_DST|codex mcp add context7' install.sh >/dev/null
rg -n 'claude-mem@\$CLAUDE_MEM_VERSION.*start' install.sh >/dev/null
pass "bootstrap sin opciones provisiona plataformas y arranca servicios"

while IFS='|' read -r tool platform support required_path detail; do
  case "$tool" in
    ''|\#*) continue ;;
  esac
  if ! awk -F'|' -v wanted="$platform" '
    $1 !~ /^#/ && $1 == wanted { found = 1 }
    END { exit !found }
  ' platforms.txt; then
    fail "platform-compatibility.txt referencia una plataforma no registrada: $platform"
  fi
done < platform-compatibility.txt

instruction_files=""
while IFS='|' read -r platform cli_command version_argument instructions_file detail; do
  case "$platform" in
    ''|\#*) continue ;;
  esac
  if ! awk -F'|' -v wanted="$platform" '
    $1 !~ /^#/ && $2 == wanted { found = 1 }
    END { exit !found }
  ' platform-compatibility.txt; then
    fail "la plataforma $platform no tiene herramientas declaradas"
  fi
  case "$instructions_file" in
    ''|*/*|*[!A-Za-z0-9._-]*) fail "archivo de instrucciones invalido para $platform" ;;
  esac
  instruction_files="$instruction_files
$instructions_file"
done < platforms.txt
duplicates="$(printf '%s\n' "$instruction_files" | sed '/^$/d' | sort | uniq -d)"
[ -z "$duplicates" ] || fail "dos plataformas comparten archivo de instrucciones: $duplicates"
pass "registros de plataformas y compatibilidad consistentes"

git ls-files --error-unmatch GUIDE.md >/dev/null 2>&1 || fail "GUIDE.md no esta agregado al indice de Git"
git ls-files --error-unmatch PROJECT_INSTRUCTIONS.md >/dev/null 2>&1 || fail "PROJECT_INSTRUCTIONS.md no esta agregado al indice de Git"
for generated in CLAUDE.md AGENTS.md; do
  if git ls-files --error-unmatch "$generated" >/dev/null 2>&1; then
    fail "$generated generado esta incluido en Git"
  fi
done
pass "fuente generica versionada y archivos por plataforma locales"

while IFS='|' read -r name url branch commit mode; do
  case "$name" in
    ''|\#*) continue ;;
  esac
  [ "$mode" = "pinned" ] || continue
  [ -d "$name/.git" ] || fail "$name no esta clonado"
  actual="$(git -C "$name" rev-parse HEAD)"
  [ "$actual" = "$commit" ] || fail "$name esta en $actual y el manifiesto fija $commit"
done < third-party-repos.txt
pass "clones pinned alineados con el manifiesto"

./tests/test_install.sh
pass "regresiones de install.sh"

./tests/test_compatibility.sh
pass "verificador extensible sin plataformas codificadas"

./tests/test_instructions.sh
pass "instrucciones locales generadas por plataforma"

./verify-compatibility.sh --platform claude --phase post
pass "compatibilidad Claude"

echo "AUDITORIA COMPLETA: todos los problemas originales estan cubiertos"
