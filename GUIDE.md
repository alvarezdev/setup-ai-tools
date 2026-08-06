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

## Cyber Neo (Claude)

Audita un proyecto en modo solo lectura mediante `/cyber-neo`. El upstream se
mantiene intacto y el wrapper de este repo guarda el informe en
`~/Documents/reports-cyber-neo/`, creando esa carpeta solo al finalizar el
análisis.

**Ejemplo:**
```text
/cyber-neo /ruta/al/proyecto
```

No modifica, borra ni ejecuta el proyecto auditado, ni instala escáneres
opcionales. Su uso está publicado únicamente en Claude; Codex no recibe esta
skill. El resultado es un archivo Markdown priorizado en la carpeta indicada.

---

## Vercel Agent Skills

Tres skills de ingeniería de Vercel (`vercel-labs/agent-skills`) enlazadas al
commit fijado en `third-party-repos.txt` para Claude y Codex. Se activan por sus
triggers al escribir, revisar o refactorizar React/Next.js o UI, o de forma
explícita:

```text
/vercel-react-best-practices
/vercel-composition-patterns
/web-design-guidelines
```

- `vercel-react-best-practices`: rendimiento de React y Next.js (componentes,
  data fetching, bundles).
- `vercel-composition-patterns`: composición que escala (compound components,
  render props, context, React 19).
- `web-design-guidelines`: revisión de UI contra las Web Interface Guidelines
  (accesibilidad y UX).

El nombre publicado sale del campo `name:` de cada `SKILL.md` y difiere de la
carpeta upstream (`react-best-practices`, `composition-patterns`). `install.sh`
solo clona y enlaza estas tres carpetas; no ejecuta `npx skills`. Una
instalación previa hecha con `npx skills` en la misma ruta se conserva y se
reporta como destino ajeno.

---

## UI UX Pro Max

Siete skills de inteligencia de diseño (`nextlevelbuilder/ui-ux-pro-max-skill`)
enlazadas al commit fijado, para Claude y Codex:

```text
/ui-ux-pro-max
/design
/design-system
/brand
/banner-design
/slides
/ui-styling
```

`ui-ux-pro-max` es la base de datos consultable (estilos, paletas, tipografía,
guías UX, iconos, animación, gráficos); las otras seis cubren marca, sistema
de tokens, banners, slides y componentes shadcn/ui. `install.sh` solo clona y
enlaza `.claude/skills/<carpeta>`; no ejecuta `npx ui-ux-pro-max-cli`. Algunas
funciones de generación de logos/iconos usan la API de Gemini (credenciales
propias del usuario, no provisionadas aquí).

---

## Impeccable (Claude)

Guía de diseño para agentes de codificación (`pbakaus/impeccable`), enlazada
solo para Claude:

```text
/impeccable init
/impeccable audit <target>
/impeccable critique <target>
/impeccable polish <target>
```

Solo se enlaza la carpeta del skill (comandos + reglas de detección). No se
instala el detector automático (`PostToolUse`/`Stop` en `.claude/settings.json`,
requiere Node 22+ y copiar el skill dentro de cada proyecto), ni el modo `live`
de iteración visual en navegador, ni el marketplace de plugins. Para esas
piezas por-proyecto, corre `npx impeccable install` dentro del proyecto que lo
necesite.

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

Para evitar incompatibilidades con `~/.claude-mem/claude-mem.db`, no reduzcas
`CLAUDE_MEM_VERSION` manualmente. El instalador bloquea esa degradacion; para
actualizar usa primero `./update.sh check` y luego `./update.sh apply`.

**Ejemplos:**
```
/mem-search autenticacion
```
```
spawn knowledge-agent to find decisions about the database schema
```

`install.sh` publica además una regla selectiva para Claude y Codex. El agente
debe invocar `mem-search` automaticamente cuando la tarea dependa de otra
sesion, retome trabajo sin suficiente contexto, investigue un problema
recurrente o necesite la razon de una decision anterior. No debe usarlo para
informacion de la conversación actual, preguntas generales, tareas nuevas bien
definidas ni hechos que pueda comprobar directamente en el repo o en Git.

Cuando consulta memoria sigue `search` -> `timeline` cuando importa el orden ->
observaciones completas solo para los resultados relevantes. Después contrasta
lo recordado con las fuentes actuales. La memoria aporta contexto historico,
pero nunca autoriza por si sola commits, pushes, despliegues, eliminaciones u
otros efectos externos.

### Revertir la regla selectiva

La regla no modifica la base de datos de claude-mem. Para retirarla sin afectar
otras instrucciones:

1. Haz una copia de `~/.claude/CLAUDE.md` o de
   `${CODEX_HOME:-$HOME/.codex}/AGENTS.md`, según la plataforma afectada.
2. Elimina exclusivamente el bloque desde
   `# >>> setup-ai-tools: claude-mem-selective-recall >>>` hasta
   `# <<< setup-ai-tools: claude-mem-selective-recall <<<`, incluidos ambos
   marcadores.
3. Cierra la sesion del agente y abre una nueva para que relea sus instrucciones.

El resto de las reglas personales queda fuera del bloque y se conserva. Una
nueva ejecución de `install.sh` volvera a publicarlo. Para una reversión
permanente, revierte en Git el cambio que introdujo
`rules/claude-mem-selective-recall.md` y luego retira los bloques globales.

### Troubleshooting: `worker unreachable`

Si un hook muestra `claude-mem worker unreachable for N consecutive hooks`,
comprueba primero el worker sin borrar la memoria:

```bash
curl -fsS http://127.0.0.1:37701/api/health
```

Una respuesta sana debe mostrar la version esperada junto con
`"initialized":true` y `"mcpReady":true`. En el incidente registrado en este
proyecto, el instalador habia degradado claude-mem de 13.12.4 a 13.10.4 y el
worker antiguo no pudo abrir el esquema mas nuevo de
`~/.claude-mem/claude-mem.db`.

Recuperacion recomendada para Claude:

```bash
./update.sh check
./update.sh apply
./install.sh --platform claude
curl -fsS http://127.0.0.1:37701/api/health
```

Para Codex, sustituye la plataforma final por `--platform codex`. Si el worker
sigue sin inicializar, revisa `~/.claude-mem/logs/` y compara la version del
endpoint con `CLAUDE_MEM_VERSION` en `tool-versions.env`. No borres
`~/.claude-mem/` como primera solucion: contiene la base de datos y el historial
local.

---

## PagoKit (agente-pagokit)

Plugin de Claude Code (`Hainrixz/agente-pagokit`) que genera integraciones de
pagos completas: analiza el proyecto, hace 3 preguntas (pais, recurrencia,
metodos locales) y recomienda entre Stripe, Mercado Pago, Wompi o Lemon
Squeezy, con frontend, webhook firmado, schema de DB, portal de clientes y
checklist de produccion. Enfocado en LATAM.

Se clona en el commit fijado pero **no** se activa globalmente ni se
symlinkea en `~/.claude/skills/`: sus hooks (`PreToolUse`/`PostToolUse`/`Stop`)
corren sobre cualquier `Write`/`Edit`/`MultiEdit`, y activarlo en cada sesion
afectaria proyectos que no tienen nada que ver con pagos. Se activa a mano,
por proyecto:

```bash
cd <proyecto-que-necesita-pagos>
claude --plugin-dir <ruta-a-setup-ai-tools>/agente-pagokit
```

Dentro de esa sesion:
```text
/pagokit:start
/pagokit:test
/pagokit:doctor
```

Requiere Node.js >= 18 y Claude Code 2.x. Sin soporte declarado para Codex.

---

## Claude SEO AI (claude-seo-ai)

Plugin de Claude Code (`Hainrixz/claude-seo-ai`) que audita un sitio o codebase
web en dos ejes independientes: SEO clasico y AI Visibility (GEO/AEO), cada
uno con un score 0-100. Detecta el vertical del sitio y corre auditorias
especialistas en paralelo (crawlability, schema JSON-LD, Core Web Vitals,
E-E-A-T, internacional, e-commerce, local, etc.). Offline-first, sin API keys
requeridas.

Se clona en el commit fijado pero **no** se activa globalmente ni se
symlinkea en `~/.claude/skills/`: su hook `PreToolUse` corre sobre cualquier
`Write`/`Edit`, y activarlo en cada sesion afectaria proyectos que no tienen
nada que ver con SEO. Se activa a mano, por proyecto:

```bash
cd <proyecto-a-auditar>
claude --plugin-dir <ruta-a-setup-ai-tools>/claude-seo-ai
```

Dentro de esa sesion:
```text
/claude-seo-ai:audit <url|ruta>
/claude-seo-ai:geo <url|ruta>
/claude-seo-ai:score
/claude-seo-ai:fix <url|ruta> [--dry-run]
```

Solo `/fix` puede escribir, y siempre pide confirmacion antes de aplicar
cambios. Requiere Node.js >= 18 (opcional). Sin soporte declarado para Codex.

---

## claude-token-efficient

No es una herramienta que se invoque: son reglas que reducen verbosidad (sin
saludos, sin cierres, sin sobre-ingenieria). En Claude se aplican desde
`~/.claude/CLAUDE.md`; en Codex, `install.sh` mantiene un bloque delimitado en
`$CODEX_HOME/AGENTS.md`. El bloque se actualiza sin borrar instrucciones del
usuario fuera de sus marcadores. Un `AGENTS.override.md` no vacío puede ocultar
esas reglas globales.
