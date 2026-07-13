#!/usr/bin/env bash
# Herramienta de mantenimiento de los manifiestos de setup-skills.
# No instala herramientas, no crea commits y nunca hace push.
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS="$BASE/third-party-repos.txt"
COMPATIBILITY="$BASE/platform-compatibility.txt"
PLATFORMS="$BASE/platforms.txt"
VERSIONS="$BASE/tool-versions.env"
GITIGNORE="$BASE/.gitignore"

usage() {
  cat <<'EOF'
Uso de mantenedor:
  ./manage.sh list [tools|compatibility|platforms|versions]
  ./manage.sh validate
  ./manage.sh audit

  ./manage.sh tool add <nombre> <url> <rama> <pinned|shallow> [commit|-]
  ./manage.sh tool update <nombre> [commit|latest]
  ./manage.sh tool remove <nombre>

  ./manage.sh compatibility set <herramienta> <plataforma> \
    <native|compatible|adapter_required|incompatible|unknown> <ruta|-> <detalle>
  ./manage.sh compatibility remove <herramienta> <plataforma>

  ./manage.sh platform add <nombre> <cli> <arg-version|-> \
    <archivo-instrucciones> <detalle>
  ./manage.sh platform remove <nombre>

  ./manage.sh version set <VARIABLE> <version>
  ./manage.sh version remove <VARIABLE>

Notas:
  - Los comandos que modifican datos solo cambian archivos locales versionados.
  - No se eliminan clones, skills instalados, commits ni recursos remotos.
  - Usa 'latest' para resolver el commit actual de la rama de un repo pinned.
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || die "falta el archivo requerido: $1"
}

reject_field_separator() {
  local label="$1"
  local value="$2"
  case "$value" in
    *'|'*) die "$label no puede contener el caracter |" ;;
    '') die "$label no puede estar vacio" ;;
  esac
}

validate_identifier() {
  local label="$1"
  local value="$2"
  reject_field_separator "$label" "$value"
  case "$value" in
    *[!A-Za-z0-9._-]*) die "$label contiene caracteres no permitidos: $value" ;;
  esac
}

validate_relative_path() {
  local value="$1"
  [ "$value" = "-" ] && return
  reject_field_separator "ruta" "$value"
  case "$value" in
    /*|../*|*/../*|*/..) die "la ruta debe ser relativa y no puede contener '..': $value" ;;
  esac
}

validate_commit() {
  local value="$1"
  case "$value" in
    *[!0-9a-fA-F]*) die "commit invalido: $value" ;;
  esac
  if [ "${#value}" -ne 40 ] && [ "${#value}" -ne 64 ]; then
    die "el commit debe ser un SHA completo de 40 o 64 caracteres: $value"
  fi
}

atomic_replace() {
  local temporary="$1"
  local destination="$2"
  chmod 644 "$temporary"
  mv "$temporary" "$destination"
}

new_temporary_for() {
  local destination="$1"
  mktemp "$(dirname "$destination")/.$(basename "$destination").XXXXXX"
}

key_exists() {
  local file="$1"
  local first="$2"
  local second="${3:-}"
  awk -F'|' -v first="$first" -v second="$second" '
    $0 !~ /^#/ && $1 == first && (second == "" || $2 == second) { found = 1 }
    END { exit !found }
  ' "$file"
}

resolve_remote_head() {
  local url="$1"
  local branch="$2"
  local commit
  command -v git >/dev/null 2>&1 || die "git es requerido para resolver latest"
  commit="$(git ls-remote --heads "$url" "refs/heads/$branch" | awk 'NR == 1 { print $1 }')"
  [ -n "$commit" ] || die "no se pudo resolver la rama $branch en $url"
  printf '%s\n' "$commit"
}

validate_manifests() {
  local name platform instructions_file tool support required_path mode commit key

  for file in "$REPOS" "$COMPATIBILITY" "$PLATFORMS" "$VERSIONS" "$GITIGNORE"; do
    require_file "$file"
  done

  awk -F'|' '
    function fail(message) { print "ERROR: third-party-repos.txt:" NR ": " message > "/dev/stderr"; errors = 1 }
    /^[[:space:]]*$/ || /^#/ { next }
    NF != 5 { fail("se esperaban 5 campos"); next }
    $1 !~ /^[A-Za-z0-9._-]+$/ { fail("nombre invalido: " $1) }
    seen[$1]++ { fail("nombre duplicado: " $1) }
    $2 == "" || $2 ~ /[[:space:]|]/ { fail("URL invalida") }
    $3 == "" || $3 ~ /[[:space:]|]/ { fail("rama invalida") }
    $5 != "pinned" && $5 != "shallow" { fail("modo invalido: " $5) }
    $5 == "pinned" && !($4 ~ /^[0-9a-fA-F]+$/ && (length($4) == 40 || length($4) == 64)) { fail("commit pinned invalido") }
    $5 == "shallow" && $4 != "-" { fail("un repo shallow debe usar commit -") }
    END { exit errors }
  ' "$REPOS" || return 1

  while IFS='|' read -r name _ _ commit mode; do
    case "$name" in ''|\#*) continue ;; esac
    if ! grep -Fx "/$name/" "$GITIGNORE" >/dev/null 2>&1; then
      echo "ERROR: .gitignore no protege el repositorio tercero /$name/" >&2
      return 1
    fi
    if [ "$mode" = "pinned" ]; then
      validate_commit "$commit"
    fi
  done < "$REPOS"

  awk -F'|' '
    function fail(message) { print "ERROR: platforms.txt:" NR ": " message > "/dev/stderr"; errors = 1 }
    /^[[:space:]]*$/ || /^#/ { next }
    NF != 5 { fail("se esperaban 5 campos"); next }
    $1 !~ /^[A-Za-z0-9._-]+$/ { fail("plataforma invalida: " $1) }
    $2 !~ /^[A-Za-z0-9._-]+$/ { fail("CLI invalido: " $2) }
    $3 == "" || $3 ~ /[[:space:]|]/ { fail("argumento de version invalido") }
    $4 !~ /^[A-Za-z0-9._-]+$/ { fail("archivo de instrucciones invalido: " $4) }
    seen_platform[$1]++ { fail("plataforma duplicada: " $1) }
    seen_file[$4]++ { fail("archivo de instrucciones duplicado: " $4) }
    $5 == "" { fail("detalle vacio") }
    END { exit errors }
  ' "$PLATFORMS" || return 1

  awk -F'|' '
    function fail(message) { print "ERROR: platform-compatibility.txt:" NR ": " message > "/dev/stderr"; errors = 1 }
    /^[[:space:]]*$/ || /^#/ { next }
    NF != 5 { fail("se esperaban 5 campos"); next }
    $1 !~ /^[A-Za-z0-9._-]+$/ { fail("herramienta invalida: " $1) }
    $2 !~ /^[A-Za-z0-9._-]+$/ { fail("plataforma invalida: " $2) }
    $3 != "native" && $3 != "compatible" && $3 != "adapter_required" && $3 != "incompatible" && $3 != "unknown" { fail("soporte invalido: " $3) }
    $4 == "" || $4 ~ /^\// || $4 ~ /(^|\/)\.\.(\/|$)/ { fail("ruta requerida invalida: " $4) }
    seen[$1 SUBSEP $2]++ { fail("declaracion duplicada para " $1 " y " $2) }
    $5 == "" { fail("detalle vacio") }
    END { exit errors }
  ' "$COMPATIBILITY" || return 1

  while IFS='|' read -r tool platform support required_path _; do
    case "$tool" in ''|\#*) continue ;; esac
    if ! key_exists "$PLATFORMS" "$platform"; then
      echo "ERROR: $tool referencia una plataforma no registrada: $platform" >&2
      return 1
    fi
    validate_relative_path "$required_path"
    case "$support" in
      native|compatible|adapter_required|incompatible|unknown) ;;
      *) die "soporte invalido para $tool/$platform: $support" ;;
    esac
  done < "$COMPATIBILITY"

  awk -F'=' '
    function fail(message) { print "ERROR: tool-versions.env:" NR ": " message > "/dev/stderr"; errors = 1 }
    /^[[:space:]]*$/ || /^#/ { next }
    NF != 2 { fail("se esperaba VARIABLE=version"); next }
    $1 !~ /^[A-Z][A-Z0-9_]*$/ { fail("variable invalida: " $1) }
    $2 == "" || $2 ~ /[[:space:]]/ { fail("version invalida") }
    seen[$1]++ { fail("variable duplicada: " $1) }
    END { exit errors }
  ' "$VERSIONS" || return 1

  echo "OK  manifiestos validos y consistentes"
}

list_records() {
  local section="${1:-all}"
  case "$section" in
    all|tools|compatibility|platforms|versions) ;;
    *) die "seccion desconocida: $section" ;;
  esac

  if [ "$section" = "all" ] || [ "$section" = "tools" ]; then
    echo "==> Herramientas con repositorio"
    awk -F'|' '$0 !~ /^#/ && NF { printf "%-24s %-8s %-12s %s\n", $1, $5, $3, $4 }' "$REPOS"
  fi
  if [ "$section" = "all" ] || [ "$section" = "compatibility" ]; then
    echo "==> Compatibilidad"
    awk -F'|' '$0 !~ /^#/ && NF { printf "%-24s %-12s %-18s %s\n", $1, $2, $3, $4 }' "$COMPATIBILITY"
  fi
  if [ "$section" = "all" ] || [ "$section" = "platforms" ]; then
    echo "==> Plataformas"
    awk -F'|' '$0 !~ /^#/ && NF { printf "%-16s %-16s %-16s %s\n", $1, $2, $4, $5 }' "$PLATFORMS"
  fi
  if [ "$section" = "all" ] || [ "$section" = "versions" ]; then
    echo "==> Versiones de paquetes"
    awk '$0 !~ /^#/ && NF { print }' "$VERSIONS"
  fi
}

tool_add() {
  [ "$#" -ge 4 ] && [ "$#" -le 5 ] || { usage >&2; exit 2; }
  local name="$1" url="$2" branch="$3" mode="$4" commit="${5:-latest}"
  local temporary

  validate_identifier "nombre" "$name"
  reject_field_separator "URL" "$url"
  reject_field_separator "rama" "$branch"
  case "$url$branch" in *[[:space:]]*) die "URL y rama no pueden contener espacios" ;; esac
  key_exists "$REPOS" "$name" && die "la herramienta ya existe: $name"

  case "$mode" in
    pinned)
      [ "$commit" != "-" ] || die "un repo pinned requiere un commit"
      [ "$commit" != "latest" ] || commit="$(resolve_remote_head "$url" "$branch")"
      validate_commit "$commit"
      ;;
    shallow)
      [ "$commit" = "latest" ] && commit="-"
      [ "$commit" = "-" ] || die "un repo shallow debe usar commit -"
      ;;
    *) die "modo invalido: $mode" ;;
  esac

  temporary="$(new_temporary_for "$REPOS")"
  cp "$REPOS" "$temporary"
  printf '%s|%s|%s|%s|%s\n' "$name" "$url" "$branch" "$commit" "$mode" >> "$temporary"
  atomic_replace "$temporary" "$REPOS"

  if ! grep -Fx "/$name/" "$GITIGNORE" >/dev/null 2>&1; then
    temporary="$(new_temporary_for "$GITIGNORE")"
    cp "$GITIGNORE" "$temporary"
    printf '/%s/\n' "$name" >> "$temporary"
    atomic_replace "$temporary" "$GITIGNORE"
  fi

  validate_manifests >/dev/null
  echo "OK  herramienta agregada: $name ($mode $commit)"
  echo "SIG compatibilidad: ./manage.sh compatibility set $name <plataforma> <soporte> <ruta|-> <detalle>"
  echo "SIG documentacion: agrega la ficha de $name en PROJECT_INSTRUCTIONS.md y GUIDE.md"
}

tool_update() {
  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || { usage >&2; exit 2; }
  local name="$1" requested="${2:-latest}"
  local row url branch current mode commit temporary

  validate_identifier "nombre" "$name"
  row="$(awk -F'|' -v name="$name" '$0 !~ /^#/ && $1 == name { print; found = 1; exit } END { exit !found }' "$REPOS")" \
    || die "herramienta no registrada: $name"
  IFS='|' read -r _ url branch current mode <<EOF
$row
EOF

  [ "$mode" = "pinned" ] || die "$name usa modo shallow y ya sigue el ultimo commit de $branch"
  if [ "$requested" = "latest" ]; then
    commit="$(resolve_remote_head "$url" "$branch")"
  else
    commit="$requested"
  fi
  validate_commit "$commit"

  if [ "$commit" = "$current" ]; then
    echo "OK  $name ya declara $commit"
    return
  fi

  temporary="$(new_temporary_for "$REPOS")"
  awk -F'|' -v OFS='|' -v name="$name" -v commit="$commit" '
    $0 !~ /^#/ && $1 == name { $4 = commit }
    { print }
  ' "$REPOS" > "$temporary"
  atomic_replace "$temporary" "$REPOS"
  validate_manifests >/dev/null
  echo "OK  $name actualizado en el manifiesto: $current -> $commit"
  echo "NOTA: ejecuta ./install.sh para reconciliar el clone local con el nuevo commit"
  echo "NOTA: revisa PROJECT_INSTRUCTIONS.md si la nueva version cambia su uso o integracion"
}

tool_remove() {
  [ "$#" -eq 1 ] || { usage >&2; exit 2; }
  local name="$1" temporary
  validate_identifier "nombre" "$name"
  key_exists "$REPOS" "$name" || die "herramienta no registrada: $name"

  temporary="$(new_temporary_for "$REPOS")"
  awk -F'|' -v name="$name" '$0 ~ /^#/ || $1 != name' "$REPOS" > "$temporary"
  atomic_replace "$temporary" "$REPOS"

  temporary="$(new_temporary_for "$COMPATIBILITY")"
  awk -F'|' -v name="$name" '$0 ~ /^#/ || $1 != name' "$COMPATIBILITY" > "$temporary"
  atomic_replace "$temporary" "$COMPATIBILITY"

  validate_manifests >/dev/null
  echo "OK  declaraciones eliminadas: $name"
  echo "NOTA: no se borro $BASE/$name ni ninguna instalacion local"
  echo "NOTA: /$name/ permanece en .gitignore para no versionar accidentalmente un clone existente"
  echo "SIG documentacion: elimina la ficha obsoleta de PROJECT_INSTRUCTIONS.md y GUIDE.md"
}

compatibility_set() {
  [ "$#" -eq 5 ] || { usage >&2; exit 2; }
  local tool="$1" platform="$2" support="$3" required_path="$4" detail="$5"
  local temporary

  validate_identifier "herramienta" "$tool"
  validate_identifier "plataforma" "$platform"
  key_exists "$PLATFORMS" "$platform" || die "plataforma no registrada: $platform"
  case "$support" in
    native|compatible|adapter_required|incompatible|unknown) ;;
    *) die "soporte invalido: $support" ;;
  esac
  validate_relative_path "$required_path"
  reject_field_separator "detalle" "$detail"

  temporary="$(new_temporary_for "$COMPATIBILITY")"
  if key_exists "$COMPATIBILITY" "$tool" "$platform"; then
    awk -F'|' -v OFS='|' -v tool="$tool" -v platform="$platform" \
      -v support="$support" -v path="$required_path" -v detail="$detail" '
      $0 !~ /^#/ && $1 == tool && $2 == platform {
        print tool, platform, support, path, detail
        next
      }
      { print }
    ' "$COMPATIBILITY" > "$temporary"
    echo "OK  compatibilidad actualizada: $tool/$platform"
  else
    cp "$COMPATIBILITY" "$temporary"
    printf '%s|%s|%s|%s|%s\n' "$tool" "$platform" "$support" "$required_path" "$detail" >> "$temporary"
    echo "OK  compatibilidad agregada: $tool/$platform"
  fi
  atomic_replace "$temporary" "$COMPATIBILITY"
  validate_manifests >/dev/null
}

compatibility_remove() {
  [ "$#" -eq 2 ] || { usage >&2; exit 2; }
  local tool="$1" platform="$2" temporary
  key_exists "$COMPATIBILITY" "$tool" "$platform" || die "no existe compatibilidad para $tool/$platform"
  temporary="$(new_temporary_for "$COMPATIBILITY")"
  awk -F'|' -v tool="$tool" -v platform="$platform" \
    '$0 ~ /^#/ || $1 != tool || $2 != platform' "$COMPATIBILITY" > "$temporary"
  atomic_replace "$temporary" "$COMPATIBILITY"
  validate_manifests >/dev/null
  echo "OK  compatibilidad eliminada: $tool/$platform"
}

platform_add() {
  [ "$#" -eq 5 ] || { usage >&2; exit 2; }
  local name="$1" cli="$2" version_argument="$3" instructions_file="$4" detail="$5"
  local temporary

  validate_identifier "plataforma" "$name"
  validate_identifier "CLI" "$cli"
  reject_field_separator "argumento de version" "$version_argument"
  case "$version_argument" in *[[:space:]]*) die "el argumento de version no puede contener espacios" ;; esac
  validate_identifier "archivo de instrucciones" "$instructions_file"
  reject_field_separator "detalle" "$detail"
  key_exists "$PLATFORMS" "$name" && die "la plataforma ya existe: $name"
  if awk -F'|' -v file="$instructions_file" '$0 !~ /^#/ && $4 == file { found = 1 } END { exit !found }' "$PLATFORMS"; then
    die "otra plataforma ya usa $instructions_file"
  fi

  temporary="$(new_temporary_for "$PLATFORMS")"
  cp "$PLATFORMS" "$temporary"
  printf '%s|%s|%s|%s|%s\n' "$name" "$cli" "$version_argument" "$instructions_file" "$detail" >> "$temporary"
  atomic_replace "$temporary" "$PLATFORMS"
  validate_manifests >/dev/null
  echo "OK  plataforma agregada: $name"
  echo "SIG compatibilidad: registra al menos una herramienta para $name"
}

platform_remove() {
  [ "$#" -eq 1 ] || { usage >&2; exit 2; }
  local name="$1" temporary
  key_exists "$PLATFORMS" "$name" || die "plataforma no registrada: $name"
  if awk -F'|' -v platform="$name" '$0 !~ /^#/ && $2 == platform { found = 1 } END { exit !found }' "$COMPATIBILITY"; then
    die "$name todavia tiene declaraciones de compatibilidad; eliminalas primero"
  fi
  temporary="$(new_temporary_for "$PLATFORMS")"
  awk -F'|' -v name="$name" '$0 ~ /^#/ || $1 != name' "$PLATFORMS" > "$temporary"
  atomic_replace "$temporary" "$PLATFORMS"
  validate_manifests >/dev/null
  echo "OK  plataforma eliminada: $name"
}

version_set() {
  [ "$#" -eq 2 ] || { usage >&2; exit 2; }
  local key="$1" value="$2" temporary
  case "$key" in
    [A-Z]* ) ;;
    *) die "la variable debe comenzar por una letra mayuscula" ;;
  esac
  case "$key" in *[!A-Z0-9_]*) die "variable invalida: $key" ;; esac
  reject_field_separator "version" "$value"
  case "$value" in *[[:space:]]*) die "la version no puede contener espacios" ;; esac

  temporary="$(new_temporary_for "$VERSIONS")"
  if awk -F'=' -v key="$key" '$0 !~ /^#/ && $1 == key { found = 1 } END { exit !found }' "$VERSIONS"; then
    awk -F'=' -v key="$key" -v value="$value" '
      $0 !~ /^#/ && $1 == key { print key "=" value; next }
      { print }
    ' "$VERSIONS" > "$temporary"
    echo "OK  version actualizada: $key=$value"
  else
    cp "$VERSIONS" "$temporary"
    printf '%s=%s\n' "$key" "$value" >> "$temporary"
    echo "OK  version agregada: $key=$value"
  fi
  atomic_replace "$temporary" "$VERSIONS"
  validate_manifests >/dev/null
}

version_remove() {
  [ "$#" -eq 1 ] || { usage >&2; exit 2; }
  local key="$1" temporary
  if ! awk -F'=' -v key="$key" '$0 !~ /^#/ && $1 == key { found = 1 } END { exit !found }' "$VERSIONS"; then
    die "version no registrada: $key"
  fi
  temporary="$(new_temporary_for "$VERSIONS")"
  awk -F'=' -v key="$key" '$0 ~ /^#/ || $1 != key' "$VERSIONS" > "$temporary"
  atomic_replace "$temporary" "$VERSIONS"
  validate_manifests >/dev/null
  echo "OK  version eliminada: $key"
}

for required in "$REPOS" "$COMPATIBILITY" "$PLATFORMS" "$VERSIONS" "$GITIGNORE"; do
  require_file "$required"
done

command_name="${1:-}"
[ -n "$command_name" ] || { usage; exit 2; }
shift

case "$command_name" in
  list)
    [ "$#" -le 1 ] || { usage >&2; exit 2; }
    list_records "${1:-all}"
    ;;
  validate)
    [ "$#" -eq 0 ] || { usage >&2; exit 2; }
    validate_manifests
    ;;
  audit)
    [ "$#" -eq 0 ] || { usage >&2; exit 2; }
    validate_manifests
    "$BASE/tests/audit_project.sh"
    ;;
  tool)
    action="${1:-}"
    [ -n "$action" ] || { usage >&2; exit 2; }
    shift
    case "$action" in
      add) tool_add "$@" ;;
      update) tool_update "$@" ;;
      remove) tool_remove "$@" ;;
      *) die "accion de tool desconocida: $action" ;;
    esac
    ;;
  compatibility)
    action="${1:-}"
    [ -n "$action" ] || { usage >&2; exit 2; }
    shift
    case "$action" in
      set) compatibility_set "$@" ;;
      remove) compatibility_remove "$@" ;;
      *) die "accion de compatibility desconocida: $action" ;;
    esac
    ;;
  platform)
    action="${1:-}"
    [ -n "$action" ] || { usage >&2; exit 2; }
    shift
    case "$action" in
      add) platform_add "$@" ;;
      remove) platform_remove "$@" ;;
      *) die "accion de platform desconocida: $action" ;;
    esac
    ;;
  version)
    action="${1:-}"
    [ -n "$action" ] || { usage >&2; exit 2; }
    shift
    case "$action" in
      set) version_set "$@" ;;
      remove) version_remove "$@" ;;
      *) die "accion de version desconocida: $action" ;;
    esac
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    die "comando desconocido: $command_name"
    ;;
esac
