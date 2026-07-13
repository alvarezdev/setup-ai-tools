#!/usr/bin/env bash
# Pruebas aisladas de las operaciones de mantenimiento.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROJECT="$TMP/project"
mkdir -p "$PROJECT/tests"
cp "$ROOT/manage.sh" \
  "$ROOT/third-party-repos.txt" \
  "$ROOT/platform-compatibility.txt" \
  "$ROOT/platforms.txt" \
  "$ROOT/tool-versions.env" \
  "$ROOT/.gitignore" \
  "$PROJECT/"
chmod +x "$PROJECT/manage.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

COMMIT_ONE="1111111111111111111111111111111111111111"
COMMIT_TWO="2222222222222222222222222222222222222222"

echo "TEST: valida y lista los manifiestos actuales"
"$PROJECT/manage.sh" validate >/dev/null
"$PROJECT/manage.sh" list tools | grep -F 'superpowers' >/dev/null

echo "TEST: agrega una herramienta reproducible y protege su clone"
"$PROJECT/manage.sh" tool add demo-tool https://example.com/demo.git main pinned "$COMMIT_ONE" >/dev/null
grep -Fx "demo-tool|https://example.com/demo.git|main|$COMMIT_ONE|pinned" "$PROJECT/third-party-repos.txt" >/dev/null
grep -Fx '/demo-tool/' "$PROJECT/.gitignore" >/dev/null
if "$PROJECT/manage.sh" tool add demo-tool https://example.com/demo.git main pinned "$COMMIT_ONE" >/dev/null 2>&1; then
  fail "acepto una herramienta duplicada"
fi

echo "TEST: registra y actualiza compatibilidad sin duplicarla"
"$PROJECT/manage.sh" compatibility set demo-tool claude compatible demo/SKILL.md "Skill de prueba" >/dev/null
"$PROJECT/manage.sh" compatibility set demo-tool claude native demo/SKILL.md "Skill nativa" >/dev/null
[ "$(awk -F'|' '$1 == "demo-tool" && $2 == "claude" { count++ } END { print count + 0 }' "$PROJECT/platform-compatibility.txt")" -eq 1 ]
grep -Fx 'demo-tool|claude|native|demo/SKILL.md|Skill nativa' "$PROJECT/platform-compatibility.txt" >/dev/null

echo "TEST: actualiza el commit fijado sin acceder a la red"
"$PROJECT/manage.sh" tool update demo-tool "$COMMIT_TWO" >/dev/null
grep -Fx "demo-tool|https://example.com/demo.git|main|$COMMIT_TWO|pinned" "$PROJECT/third-party-repos.txt" >/dev/null

echo "TEST: agrega y retira una plataforma solo cuando no tiene dependencias"
"$PROJECT/manage.sh" platform add test-agent test-agent --version TEST_AGENT.md "Agente de prueba" >/dev/null
"$PROJECT/manage.sh" compatibility set demo-tool test-agent unknown - "Pendiente de evaluar" >/dev/null
if "$PROJECT/manage.sh" platform remove test-agent >/dev/null 2>&1; then
  fail "elimino una plataforma con compatibilidad declarada"
fi
"$PROJECT/manage.sh" compatibility remove demo-tool test-agent >/dev/null
"$PROJECT/manage.sh" platform remove test-agent >/dev/null

echo "TEST: administra versiones de paquetes"
"$PROJECT/manage.sh" version set DEMO_VERSION 1.2.3 >/dev/null
grep -Fx 'DEMO_VERSION=1.2.3' "$PROJECT/tool-versions.env" >/dev/null
"$PROJECT/manage.sh" version set DEMO_VERSION 2.0.0 >/dev/null
grep -Fx 'DEMO_VERSION=2.0.0' "$PROJECT/tool-versions.env" >/dev/null
"$PROJECT/manage.sh" version remove DEMO_VERSION >/dev/null
if grep -q '^DEMO_VERSION=' "$PROJECT/tool-versions.env"; then
  fail "no elimino la version"
fi

echo "TEST: eliminar una herramienta conserva sus archivos locales"
mkdir -p "$PROJECT/demo-tool"
printf '%s\n' 'conservar' > "$PROJECT/demo-tool/user-file.txt"
"$PROJECT/manage.sh" tool remove demo-tool >/dev/null
if grep -q '^demo-tool|' "$PROJECT/third-party-repos.txt"; then
  fail "no elimino la herramienta del manifiesto"
fi
if grep -q '^demo-tool|' "$PROJECT/platform-compatibility.txt"; then
  fail "no elimino la compatibilidad de la herramienta"
fi
grep -Fx 'conservar' "$PROJECT/demo-tool/user-file.txt" >/dev/null
grep -Fx '/demo-tool/' "$PROJECT/.gitignore" >/dev/null

"$PROJECT/manage.sh" validate >/dev/null
echo "PASS: todas las pruebas de manage.sh"
