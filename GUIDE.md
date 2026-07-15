# Guia de uso

Como usar cada herramienta instalada en `setup-ai-tools`. Para la ficha tecnica completa (rutas, version, alcance) ver `PROJECT_INSTRUCTIONS.md`.

---

## Superpowers

Metodologia de desarrollo de software para agentes de codificacion: 13 skills que cubren brainstorming, planes, TDD, debugging sistematico, code review y mas. Se activan solos segun el contexto de la tarea, via un hook que se inyecta al iniciar sesion. No hace falta invocarlos por nombre en la mayoria de los casos.

**Ejemplos:**
```
Quiero armar una nueva feature de autenticacion, ayudame a pensarla antes de escribir codigo
```
```
Encontre un bug raro en produccion, ayudame a encontrar la causa raiz de forma sistematica
```

---

## abogado-del-diablo

Critico hostil de ideas, planes y proyectos. Asume que van a fracasar y construye el caso mas fuerte en contra desde 8 angulos (premisas, mercado, competencia, viabilidad, numeros, ejecucion, pre-mortem, punto ciego). Util antes de comprometer tiempo o dinero en algo. Prohibido que adule o valide de entrada.

En Codex se instala el adaptador `adapters/codex/abogado-del-diablo/`: conserva
los ocho ángulos upstream y traduce las capacidades a lectura local, `rg`,
búsqueda web y subagentes cuando estén disponibles y autorizados.

**Ejemplos:**
```
/abogado-del-diablo Quiero lanzar una app de suscripcion para recordatorios de medicamentos
```
```
Hazme pedazos este plan de negocio antes de que hable con inversionistas
```

---

## prompt-master

Genera prompts optimizados para cualquier herramienta de IA (Claude, ChatGPT, Cursor, Midjourney, etc.). Detecta la herramienta destino, aplica el framework correcto (RTF, CO-STAR, Chain of Thought...) y corrige patrones que desperdician tokens. Entrega un prompt listo para pegar.

En Codex se instala `adapters/codex/prompt-master/`, que produce prompts con
objetivo, alcance, restricciones, verificación y condición de terminación.

**Ejemplos:**
```
/prompt-master
Necesito un prompt para que Cursor refactorice mi modulo de autenticacion
```
```
Write me a prompt for Midjourney to generate a minimalist logo for a coffee brand
```

---

## commit-style

Propone mensajes de commit en estilo Conventional Commits a partir del diff real del repositorio. Titulo corto en ingles con verbo imperativo, cuerpo con bullets concretos. Nunca hace push ni commit real sin autorizacion explicita; nunca afirma que corrio tests sin evidencia.

**Ejemplos:**
```
/commit-style
Termine de implementar el endpoint de perfil, proponme el commit
```
```
Como quedaria el commit de estos cambios que tengo sin commitear
```

---

## Graphify

Explora un codebase mediante su grafo antes de hacer una busqueda amplia. En
este repo se instala como CLI global aislado con `uv` y una skill propia para
Claude y Codex; no modifica las instrucciones ni hooks de las plataformas.

**Ejemplos:**
```bash
graphify query "How does install.sh provision Claude and Codex?"
graphify path "install.sh script" "ensure_skill_link()"
graphify explain install.sh
```

Para crear o actualizar el grafo deliberadamente:
```bash
graphify .
graphify update .
```

La skill `/graphify` está disponible en cada sesión nueva, pero el grafo no se
reconstruye automáticamente. Si no existe o está desactualizado, se indica y
se usa lectura directa o `rg`; `graphify-out/` permanece local e ignorado.

---

## Context7 (MCP)

Trae documentacion actualizada de librerias y frameworks directo al contexto, evitando que Claude invente APIs o use ejemplos de versiones viejas. Se activa automaticamente al detectar preguntas sobre librerias; tambien se puede invocar explicito.

**Ejemplos:**
```
use context7 to show me how to set up middleware in Next.js 15
```
```
use context7 with /vercel/next.js for app router setup
```

Si `codex mcp get context7` muestra `could not create PATH aliases` dentro de
un sandbox restringido, el aviso no pertenece a Context7. Repite la verificación
desde una Terminal normal; no filtres `stderr` ni muevas `CODEX_HOME` a `/tmp`.

---

## the-architect

Meta-agente de diseno de software. Convierte una idea de proyecto en un blueprint de 16 secciones (stack, arquitectura, modelos de datos, deploy) tras 3 fases de preguntas, listo para que otra sesion de agente lo ejecute.

**Ejemplos:**
```bash
cd setup-ai-tools/the-architect
claude
```
En Codex usa el workspace adaptado:
```bash
cd setup-ai-tools/adapters/codex/the-architect
codex
```
```
Quiero construir una app SaaS de gestion de inventario para pymes
```

---

## claude-mem (plugin)

Memoria persistente entre sesiones de Claude Code y Codex. Captura observaciones automaticamente y las inyecta como contexto en sesiones posteriores. `install.sh` instala las integraciones detectadas y deja el worker iniciado.

**Ejemplos:**
```
/mem-search autenticacion
```
```
spawn knowledge-agent to find decisions about the database schema
```

---

## claude-token-efficient

No es una herramienta que se invoque: son reglas que reducen verbosidad (sin
saludos, sin cierres, sin sobre-ingenieria). En Claude se aplican desde
`~/.claude/CLAUDE.md`; en Codex, `install.sh` mantiene un bloque delimitado en
`$CODEX_HOME/AGENTS.md`. El bloque se actualiza sin borrar instrucciones del
usuario fuera de sus marcadores. Un `AGENTS.override.md` no vacío puede ocultar
esas reglas globales.
