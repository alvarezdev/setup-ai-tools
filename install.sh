#!/usr/bin/env bash
# Bootstrap script for setup-skills.
# Run this after cloning the repo on a new machine to wire everything
# back into ~/.claude/. Safe to re-run (idempotent).
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DST="$HOME/.claude/skills"
SETTINGS="$HOME/.claude/settings.json"

echo "==> Usando setup-skills en: $BASE"
mkdir -p "$SKILLS_DST"

# --- 0. Clonar repos de terceros desde el manifiesto -------------------
# Solo referencias: el repo propio no versiona el codigo de terceros, lo
# clona aqui. Lee third-party-repos.txt (nombre|url|branch|commit|modo).
MANIFEST="$BASE/third-party-repos.txt"
if [ -f "$MANIFEST" ]; then
  echo "==> Clonando repos de terceros (manifiesto: third-party-repos.txt)"
  while IFS='|' read -r name url branch commit mode; do
    case "$name" in
      ''|\#*) continue ;;  # ignora lineas vacias y comentarios
    esac
    dest="$BASE/$name"
    if [ -d "$dest/.git" ]; then
      echo "OK  $name ya existe, se omite"
      continue
    fi
    if [ "$mode" = "shallow" ]; then
      echo "==> clone shallow $name ($branch)"
      git clone --depth 1 --branch "$branch" "$url" "$dest"
    else
      echo "==> clone $name (pinned $commit)"
      git clone "$url" "$dest"
      git -C "$dest" checkout "$commit"
    fi
  done < "$MANIFEST"
else
  echo "AVISO: no se encontro $MANIFEST, se omite el clonado de terceros"
fi

# --- 1. Symlinks de skills ---------------------------------------------
# macOS trae bash 3.2 (sin arrays asociativos), por eso usamos pares "name|target".
SKILL_LINKS="
commit-style|$BASE/skills/commit-style
prompt-master|$BASE/prompt-master
abogado-del-diablo|$BASE/abogado-del-diablo/skills/abogado-del-diablo
brainstorming|$BASE/superpowers/skills/brainstorming
dispatching-parallel-agents|$BASE/superpowers/skills/dispatching-parallel-agents
executing-plans|$BASE/superpowers/skills/executing-plans
finishing-a-development-branch|$BASE/superpowers/skills/finishing-a-development-branch
receiving-code-review|$BASE/superpowers/skills/receiving-code-review
requesting-code-review|$BASE/superpowers/skills/requesting-code-review
subagent-driven-development|$BASE/superpowers/skills/subagent-driven-development
systematic-debugging|$BASE/superpowers/skills/systematic-debugging
test-driven-development|$BASE/superpowers/skills/test-driven-development
using-git-worktrees|$BASE/superpowers/skills/using-git-worktrees
using-superpowers|$BASE/superpowers/skills/using-superpowers
verification-before-completion|$BASE/superpowers/skills/verification-before-completion
writing-plans|$BASE/superpowers/skills/writing-plans
writing-skills|$BASE/superpowers/skills/writing-skills
"

echo "$SKILL_LINKS" | while IFS='|' read -r name target; do
  [ -z "$name" ] && continue
  link="$SKILLS_DST/$name"
  if [ ! -d "$target" ]; then
    echo "AVISO: falta $target (submodulo/repo no clonado?) - se omite $name"
    continue
  fi
  rm -rf "$link"
  ln -s "$target" "$link"
  echo "OK  $name -> $target"
done

# --- 2. Superpowers: CLAUDE_PLUGIN_ROOT y hook SessionStart -------------
echo "==> Actualizando settings.json (CLAUDE_PLUGIN_ROOT + hook de superpowers)"
python3 - "$SETTINGS" "$BASE/superpowers" <<'PYEOF'
import json, os, sys

settings_path, superpowers_root = sys.argv[1], sys.argv[2]

if os.path.exists(settings_path):
    with open(settings_path) as f:
        data = json.load(f)
else:
    data = {}

data.setdefault("env", {})["CLAUDE_PLUGIN_ROOT"] = superpowers_root

hook_cmd = f"{superpowers_root}/hooks/run-hook.cmd session-start"
session_start = data.setdefault("hooks", {}).setdefault("SessionStart", [{"hooks": []}])
if not session_start or "hooks" not in session_start[0]:
    session_start.append({"hooks": []})
hooks_list = session_start[0]["hooks"]

replaced = False
for h in hooks_list:
    if h.get("type") == "command" and "run-hook.cmd session-start" in h.get("command", ""):
        h["command"] = hook_cmd
        replaced = True
if not replaced:
    hooks_list.append({"type": "command", "command": hook_cmd})

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print(f"CLAUDE_PLUGIN_ROOT -> {superpowers_root}")
print(f"Hook SessionStart  -> {hook_cmd}")
PYEOF

# --- 3. claude-mem plugin ------------------------------------------------
echo "==> Instalando claude-mem (npx claude-mem install)"
if command -v npx >/dev/null 2>&1; then
  (cd "$BASE" && npx claude-mem install) || echo "AVISO: claude-mem install fallo, revisar manualmente"
else
  echo "AVISO: npx no disponible, instala Node.js y corre 'npx claude-mem install' manualmente"
fi

# --- 4. Context7 MCP (scope user) ----------------------------------------
echo "==> Registrando Context7 como MCP (scope user)"
if claude mcp get context7 >/dev/null 2>&1; then
  echo "Context7 ya estaba registrado, se omite"
else
  claude mcp add --transport http context7 https://mcp.context7.com/mcp -s user
fi

# --- 5. Recordatorios ------------------------------------------------------
cat <<'EOF'

==> Listo. Pendientes manuales:
  - claude-mem: el worker no arranca solo. Ejecuta: npx claude-mem start
  - Context7: para salir del tier anonimo, crea cuenta en context7.com/dashboard
    y agrega CONTEXT7_API_KEY a tu shell profile.
  - Reglas globales de ~/.claude/CLAUDE.md (Espanol, claude-token-efficient,
    estilo de escritura) NO se automatizan con este script todavia.
    Copia manualmente el contenido documentado en este CLAUDE.md.

==> Nota de versiones (importante en una maquina nueva):
  - Repos 'pinned' (superpowers, prompt-master, abogado-del-diablo,
    the-architect): quedan en el commit exacto fijado en third-party-repos.txt.
    Reproducibles: la maquina nueva tiene la misma version que la anterior.
  - Repos 'shallow' (context7, claude-token-efficient): traen el ULTIMO estado
    de la rama al momento de correr este script, NO una version fija. Si el
    autor upstream los cambio, aqui recibiras esa version nueva.
    Para fijarlos: en third-party-repos.txt cambia su modo a 'pinned' y pon un
    commit; luego borra su carpeta y vuelve a correr install.sh.
EOF
