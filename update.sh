#!/usr/bin/env bash
# Consulta o aplica actualizaciones de terceros sin perder reproducibilidad.
#
#   ./update.sh check   # compara versiones fijadas con upstream
#   ./update.sh apply   # actualiza clones, valida rutas y guarda nuevos commits
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$BASE/third-party-repos.txt"
VERSIONS="$BASE/tool-versions.env"
MODE="${1:-check}"

case "$MODE" in
  check|apply) ;;
  *)
    echo "Uso: $0 [check|apply]" >&2
    exit 2
    ;;
esac

for command_name in git npm; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "ERROR: falta el comando requerido: $command_name" >&2
    exit 1
  fi
done

if [ ! -f "$MANIFEST" ] || [ ! -f "$VERSIONS" ]; then
  echo "ERROR: faltan third-party-repos.txt o tool-versions.env" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$VERSIONS"
: "${CLAUDE_MEM_VERSION:?Falta CLAUDE_MEM_VERSION en tool-versions.env}"

remote_head() {
  local url="$1"
  local branch="$2"
  git ls-remote --heads "$url" "refs/heads/$branch" | awk 'NR == 1 { print $1 }'
}

validate_repo() {
  local name="$1"
  local dest="$2"
  local required

  case "$name" in
    superpowers) required="skills/using-superpowers/SKILL.md" ;;
    prompt-master) required="SKILL.md" ;;
    abogado-del-diablo) required="skills/abogado-del-diablo/SKILL.md" ;;
    the-architect) required="CLAUDE.md" ;;
    context7) required="packages/mcp/package.json" ;;
    claude-token-efficient) required="CLAUDE.md" ;;
    *) required="README.md" ;;
  esac

  if [ ! -f "$dest/$required" ]; then
    echo "ERROR: $name ya no contiene $required; no se actualiza el manifiesto" >&2
    return 1
  fi
}

if [ "$MODE" = "apply" ]; then
  # Los archivos no rastreados se conservan. Git abortara antes de sobrescribir
  # alguno que choque con upstream. Los cambios rastreados si bloquean todo.
  while IFS='|' read -r name url branch commit mode; do
    case "$name" in
      ''|\#*) continue ;;
    esac
    dest="$BASE/$name"
    if [ -d "$dest/.git" ]; then
      if ! git -C "$dest" diff --quiet || ! git -C "$dest" diff --cached --quiet; then
        echo "ERROR: $name tiene cambios rastreados; guardalos antes de actualizar" >&2
        exit 1
      fi
    fi
  done < "$MANIFEST"
fi

manifest_tmp=""
versions_tmp=""
cleanup() {
  [ -z "$manifest_tmp" ] || rm -f "$manifest_tmp"
  [ -z "$versions_tmp" ] || rm -f "$versions_tmp"
}
trap cleanup EXIT

if [ "$MODE" = "apply" ]; then
  manifest_tmp="$(mktemp "$BASE/.third-party-repos.XXXXXX")"
fi

echo "==> Repositorios Git"
while IFS= read -r manifest_line || [ -n "$manifest_line" ]; do
  case "$manifest_line" in
    '')
      [ "$MODE" = "apply" ] && printf '\n' >> "$manifest_tmp"
      continue
      ;;
    \#*)
      [ "$MODE" = "apply" ] && printf '%s\n' "$manifest_line" >> "$manifest_tmp"
      continue
      ;;
  esac

  IFS='|' read -r name url branch commit mode <<EOF
$manifest_line
EOF

  latest="$(remote_head "$url" "$branch")"
  if [ -z "$latest" ]; then
    echo "ERROR: no se pudo resolver $name ($branch)" >&2
    exit 1
  fi

  if [ "$mode" = "pinned" ]; then
    current="$commit"
  elif [ -d "$BASE/$name/.git" ]; then
    current="$(git -C "$BASE/$name" rev-parse HEAD)"
  else
    current="-"
  fi

  if [ "$current" = "$latest" ]; then
    echo "OK  $name ya esta actualizado ($latest)"
  else
    echo "UPD $name: $current -> $latest"
  fi

  if [ "$MODE" = "apply" ]; then
    dest="$BASE/$name"
    if [ ! -d "$dest/.git" ]; then
      git clone "$url" "$dest"
    fi
    git -C "$dest" fetch origin "$branch"
    git -C "$dest" checkout --detach "$latest"
    validate_repo "$name" "$dest"

    if [ "$mode" = "pinned" ]; then
      printf '%s|%s|%s|%s|%s\n' "$name" "$url" "$branch" "$latest" "$mode" >> "$manifest_tmp"
    else
      printf '%s|%s|%s|%s|%s\n' "$name" "$url" "$branch" "$commit" "$mode" >> "$manifest_tmp"
    fi
  fi
done < "$MANIFEST"

echo "==> Paquetes npm"
latest_claude_mem="$(npm view claude-mem@latest version)"
if [ "$CLAUDE_MEM_VERSION" = "$latest_claude_mem" ]; then
  echo "OK  claude-mem ya esta actualizado ($CLAUDE_MEM_VERSION)"
else
  echo "UPD claude-mem: $CLAUDE_MEM_VERSION -> $latest_claude_mem"
fi

if [ "$MODE" = "apply" ]; then
  versions_tmp="$(mktemp "$BASE/.tool-versions.XXXXXX")"
  awk -v version="$latest_claude_mem" '
    /^CLAUDE_MEM_VERSION=/ { print "CLAUDE_MEM_VERSION=" version; next }
    { print }
  ' "$VERSIONS" > "$versions_tmp"

  mv "$manifest_tmp" "$MANIFEST"
  manifest_tmp=""
  mv "$versions_tmp" "$VERSIONS"
  versions_tmp=""
  echo "==> Versiones actualizadas y fijadas"
else
  echo "==> Solo consulta; ejecuta './update.sh apply' para aplicar"
fi
