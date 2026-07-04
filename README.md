# setup-skills

Configuracion portable de Claude Code: skills, MCP servers y plugins, con trazabilidad para moverla entre maquinas o compartirla.

Este repo versiona **solo trabajo propio**. Los proyectos de terceros no se copian aqui: se referencian por URL y commit en `third-party-repos.txt` y los clona `install.sh`.

## Que contiene este repo

- `skills/commit-style/` - skill propio (Conventional Commits desde el diff real)
- `CLAUDE.md` - documentacion e inventario de todo lo instalado, por categoria
- `third-party-repos.txt` - manifiesto de repos de terceros (URL + commit)
- `install.sh` - bootstrap idempotente para una maquina nueva
- `.gitignore` - ignora los directorios de terceros que clona `install.sh`

## Uso en una maquina nueva

```bash
git clone <url-de-este-repo> setup-skills
cd setup-skills
./install.sh
```

`install.sh` hace, en orden:
1. Clona los repos de terceros del manifiesto (pinned a un commit, o shallow para los de solo referencia).
2. Crea los symlinks de skills en `~/.claude/skills/`.
3. Actualiza `CLAUDE_PLUGIN_ROOT` y el hook de Superpowers en `~/.claude/settings.json`.
4. Instala claude-mem (`npx claude-mem install`).
5. Registra Context7 como MCP (`claude mcp add -s user`).

Pasos manuales que el script recuerda al terminar: arrancar el worker de claude-mem (`npx claude-mem start`), el API key de Context7, y copiar las reglas globales a `~/.claude/CLAUDE.md`.

## Terceros

Los proyectos referenciados (superpowers, prompt-master, abogado-del-diablo, context7, claude-token-efficient, the-architect) son repos independientes con licencia MIT, propiedad de sus autores. Aqui solo se referencian por URL; su codigo no forma parte de este repo. Ver `third-party-repos.txt` y la seccion correspondiente en `CLAUDE.md`.

## Versiones al clonar en una maquina nueva

- `pinned` (superpowers, prompt-master, abogado-del-diablo, the-architect): la maquina nueva queda en el mismo commit que la anterior. Reproducible.
- `shallow` (context7, claude-token-efficient): traen el ultimo estado de la rama al momento de correr `install.sh`, NO una version fija. Es intencional porque son solo referencia (el MCP de context7 corre remoto y las reglas de token-efficient ya viven en `~/.claude/CLAUDE.md`). Si el autor upstream las cambia, recibiras la version nueva.

Para fijar uno de los `shallow`: en `third-party-repos.txt` cambia su modo a `pinned` y pon un commit; borra su carpeta y vuelve a correr `install.sh`.
