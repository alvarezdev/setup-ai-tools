#!/usr/bin/env bash
# Verifica si las herramientas declaradas pueden usarse en una plataforma.
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="$BASE/platform-compatibility.txt"
PLATFORMS="$BASE/platforms.txt"
PLATFORM=""
PHASE="post"

usage() {
  echo "Uso: $0 --platform <nombre> [--phase <pre|post>]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      PLATFORM="$2"
      shift 2
      ;;
    --phase)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      PHASE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[ -n "$PLATFORM" ] || { usage; exit 2; }
case "$PHASE" in
  pre|post) ;;
  *) usage; exit 2 ;;
esac

if [ ! -f "$REGISTRY" ] || [ ! -f "$PLATFORMS" ]; then
  echo "ERROR: faltan platform-compatibility.txt o platforms.txt" >&2
  exit 1
fi

platform_command=""
version_argument=""
platform_detail=""
while IFS='|' read -r registered_platform registered_command registered_version registered_instructions registered_detail; do
  case "$registered_platform" in
    ''|\#*) continue ;;
  esac
  if [ "$registered_platform" = "$PLATFORM" ]; then
    platform_command="$registered_command"
    version_argument="$registered_version"
    platform_detail="$registered_detail"
    break
  fi
done < "$PLATFORMS"

if [ -z "$platform_command" ]; then
  echo "FAIL  plataforma no registrada: $PLATFORM" >&2
  echo "Plataformas disponibles:" >&2
  while IFS='|' read -r registered_platform registered_command registered_version registered_instructions registered_detail; do
    case "$registered_platform" in
      ''|\#*) continue ;;
    esac
    printf '  - %s (%s)\n' "$registered_platform" "$registered_detail" >&2
  done < "$PLATFORMS"
  exit 1
fi

if ! command -v "$platform_command" >/dev/null 2>&1; then
  echo "FAIL  plataforma $PLATFORM: CLI '$platform_command' no encontrado en PATH" >&2
  exit 1
fi

if [ "$version_argument" = "-" ]; then
  platform_version="$($platform_command 2>/dev/null || true)"
else
  platform_version="$($platform_command "$version_argument" 2>/dev/null || true)"
fi
echo "Plataforma: $PLATFORM${platform_detail:+ - $platform_detail}${platform_version:+ ($platform_version)}"
echo "Fase: $PHASE"

failures=0
warnings=0
entries=0
while IFS='|' read -r tool platform support required_path detail; do
  case "$tool" in
    ''|\#*) continue ;;
  esac
  [ "$platform" = "$PLATFORM" ] || continue
  entries=$((entries + 1))

  case "$support" in
    native)
      status="PASS"
      ;;
    compatible)
      status="PASS"
      ;;
    adapter_required)
      status="WARN"
      warnings=$((warnings + 1))
      ;;
    incompatible|unknown)
      status="FAIL"
      failures=$((failures + 1))
      ;;
    *)
      status="FAIL"
      detail="Estado de compatibilidad desconocido: $support"
      failures=$((failures + 1))
      ;;
  esac

  if [ "$PHASE" = "post" ] && [ "$required_path" != "-" ] && [ ! -f "$BASE/$required_path" ]; then
    status="FAIL"
    detail="Falta archivo requerido: $required_path"
    failures=$((failures + 1))
  fi

  printf '%-5s %-24s %s\n' "$status" "$tool" "$detail"
done < "$REGISTRY"

if [ "$entries" -eq 0 ]; then
  echo "FAIL  no hay herramientas declaradas para $PLATFORM" >&2
  exit 1
fi

if [ "$failures" -gt 0 ]; then
  echo "Resultado: incompatible ($failures errores, $warnings adaptaciones)" >&2
  exit 1
fi
if [ "$warnings" -gt 0 ]; then
  echo "Resultado: requiere adaptadores ($warnings)" >&2
  exit 2
fi

echo "Resultado: compatible"
