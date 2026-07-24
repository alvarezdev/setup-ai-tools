# Instrucciones del proyecto

Este archivo proporciona instrucciones persistentes a cualquier agente de desarrollo que trabaje en este repositorio. `install.sh` lo publica con el nombre esperado por cada plataforma seleccionada.

## Regla de documentacion

Cada vez que se instale una herramienta, plugin, perfil o recurso en este proyecto, documenta inmediatamente en este archivo bajo la categoria correspondiente:
- **Skills** - Habilidades que los agentes invocan para guiar su comportamiento en tareas especificas.
- **MCP Servers** - Servidores externos que una plataforma conecta via protocolo MCP para acceder a herramientas y datos en tiempo real.
- **Instrucciones de Comportamiento** - Reglas persistentes que modifican como responde cada agente por defecto.
- **Plugins** - Paquetes instalables que combinan hooks, skills y servicios de fondo en una sola unidad.

Por cada item documentar:
- Nombre y repositorio fuente.
- Descripcion breve de que hace y para que sirve.
- Donde se instalo (ruta o alcance: global o proyecto).
- Perfiles o variantes disponibles, si los tiene.
- Consideraciones importantes de uso.

No omitas este paso aunque la instalacion haya sido simple.

---

## Portabilidad y `install.sh`

Este proyecto es la fuente de verdad para trazabilidad y portabilidad entre maquinas. El objetivo: clonar `setup-ai-tools` en una maquina nueva, correr un script, y quedar configurado.

Modelo de repo: este repo versiona **solo trabajo propio** (`skills/commit-style/`, `skills/graphify/`, `skills/cyber-neo/`, `adapters/codex/`, `PROJECT_INSTRUCTIONS.md`, `GUIDE.md`, `install.sh`, `manage.sh`, `update.sh`, `verify-compatibility.sh`, `platforms.txt`, `platform-compatibility.txt`, `tests/`, `README.md`, `third-party-repos.txt`, `tool-versions.env`, `.gitignore`). `PROJECT_INSTRUCTIONS.md` es la fuente generica; `install.sh` genera localmente el archivo que declara cada plataforma en `platforms.txt`, por ejemplo `CLAUDE.md` o `AGENTS.md`. Los repos de terceros NO se versionan: se referencian por URL + commit en `third-party-repos.txt` y los clona `install.sh`. El `.gitignore` ignora sus directorios (`superpowers/`, `prompt-master/`, etc.), lo que ademas evita que sus `.git` anidados se traten como submodules accidentales.

Manifiesto `third-party-repos.txt` (formato `nombre|url|branch|commit|modo`):
- `pinned` - clon completo + `checkout` al commit fijado (reproducible). Usado por superpowers, prompt-master, abogado-del-diablo, the-architect y cyber-neo.
- `shallow` - `git clone --depth 1` del tip de la rama, sin fijar commit. Usado por context7 y claude-token-efficient (solo referencia; su version exacta no importa y evita traer los 45MB de historial de context7).
- `tool-versions.env` fija paquetes que no se instalan desde repos Git: claude-mem y Graphify.
- `./update.sh check` consulta actualizaciones sin modificar archivos; `./update.sh apply` actualiza, valida y guarda los nuevos commits y versiones, incluida la version de Graphify en PyPI.
- `./manage.sh` es exclusivo del mantenedor: agrega, actualiza o elimina declaraciones de herramientas, compatibilidad, plataformas y versiones. Nunca instala, borra clones, crea commits ni hace push.

Como funciona:
- `PROJECT_INSTRUCTIONS.md` es la unica fuente versionada de instrucciones del proyecto. `platforms.txt` declara el nombre local que usa cada plataforma y `install.sh` genera los archivos administrados correspondientes. Con Claude y Codex seleccionados conviven `CLAUDE.md` y `AGENTS.md` con el mismo contenido.
- Los skills instalados en `~/.claude/skills/` y `$CODEX_HOME/skills/` **son symlinks**, no copias. El contenido real vive dentro de este repo o de un repo clonado. Los adaptadores propios de Codex viven en `adapters/codex/` y contienen symlinks relativos a su fuente upstream para no modificarla.
- `install.sh` autodetecta una o varias plataformas, genera sus archivos de instrucciones, verifica compatibilidad y provisiona lo soportado. Para Claude administra skills, settings, hooks, claude-mem y Context7; tambien publica el wrapper propio de Cyber Neo. Para Codex instala skills compatibles en `$CODEX_HOME/skills`, incluidos los adaptadores de `prompt-master` y `abogado-del-diablo`; configura claude-mem con hooks nativos, registra Context7 y actualiza el bloque administrado de `claude-token-efficient` en `$CODEX_HOME/AGENTS.md`. Para ambas instala el CLI Graphify fijado con `uv` y Python 3.12 y publica el wrapper propio como symlink. Los destinos ajenos nunca se reemplazan.
- `update.sh` resuelve el ultimo commit de cada rama, la ultima version npm de claude-mem y la ultima version de Graphify en PyPI. En modo `apply`, actualiza los clones, valida sus archivos esenciales y persiste las nuevas versiones para que instalaciones posteriores sigan siendo reproducibles.
- `verify-compatibility.sh` descubre plataformas desde `platforms.txt` y compara cada herramienta con `platform-compatibility.txt`; devuelve exito, adaptador requerido o incompatibilidad antes de instalar. Agregar una plataforma no requiere modificar el script. `tests/test_compatibility.sh` demuestra esa extensibilidad con una plataforma ficticia.
- `manage.sh validate` comprueba la estructura y consistencia cruzada de todos los manifiestos; `manage.sh audit` agrega la suite completa de regresion. Una herramienta nueva que requiera hooks o comandos propios tambien debe incorporar su provisionamiento en `install.sh` y sus pruebas.
- El instalador es convergente para repos `pinned`: valida `origin`, estado Git y commit. No reemplaza carpetas reales ni symlinks que apunten fuera de este proyecto.
- Si el repositorio cambia de ubicacion, `install.sh` migra los symlinks administrados de Claude y Codex. Conserva el historial de rutas en `~/.local/state/setup-ai-tools/managed-roots` y puede reconocer instalaciones antiguas mediante varios symlinks rotos que coincidan con la estructura esperada. El estado creado anteriormente bajo `~/.local/state/setup-skills` se importa automaticamente.
- Las herramientas ajenas se conservan y ya no detienen toda la instalacion. Para Superpowers, una copia externa limpia con el mismo origin y commit se reutiliza; una version diferente se omite solo en la plataforma afectada. `--migrate-tool superpowers` transfiere explicitamente sus symlinks y registra ruta, origin y commit anteriores en `~/.local/state/setup-ai-tools/migrations.log`; nunca reemplaza carpetas reales.
- `settings.json` se valida estructuralmente y se reemplaza de forma atomica, preservando grupos `SessionStart` existentes y evitando hooks duplicados.

Uso en maquina nueva:
```bash
git clone <url-del-repo> setup-ai-tools
cd setup-ai-tools
./install.sh
```

Sin opciones, el script selecciona todos los CLI registrados que encuentre en `PATH`. Usa `--platform` o `--instructions-only` solamente para mantenimiento y pruebas.

Limitaciones conocidas (no automatizadas todavia):
- **Reglas globales personales**: no se sobrescriben. No son necesarias para usar este proyecto; pueden configurarse opcionalmente en el archivo global de cada plataforma.
- **claude-mem**: sus archivos viven en `~/.claude/plugins/marketplaces/thedotmack/` (con `node_modules` propios), no dentro de este repo. `install.sh` instala la version declarada en `tool-versions.env` y bloquea una degradacion frente a una version ya presente, porque podria ser incompatible con `~/.claude-mem/claude-mem.db`. `update.sh apply` es el unico flujo que la avanza automaticamente.
- **Context7**: se registra como MCP de usuario en cada plataforma detectada; `install.sh` usa los comandos nativos de Claude y Codex. El aviso `could not create PATH aliases` al ejecutar `codex` dentro de un sandbox restringido no corresponde al MCP: se verifica desde una Terminal normal, sin filtrar `stderr` ni mover `CODEX_HOME` a `/tmp`.
- **`the-architect`**: repo autocontenido para Claude en `the-architect/` y workspace adaptado para Codex en `adapters/codex/the-architect/`. No requiere symlink de skill, pero si esta en el manifiesto para que `install.sh` lo clone en la maquina nueva.
- **Graphify**: el CLI y la skill quedan disponibles globalmente, pero el grafo no se crea ni se actualiza al abrir una sesion. Genera o actualiza el grafo bajo demanda; `graphify-out/` es local e ignorado. No se ejecutan los instaladores upstream `graphify install`, `graphify claude install` ni `graphify codex install`, porque escriben instrucciones y hooks con rutas absolutas y romperian esta fuente unica.
- **Cyber Neo**: se publica solo para Claude; su upstream no se modifica. El wrapper propio crea `~/Documents/reports-cyber-neo/` solo al guardar el informe y nunca escribe dentro del proyecto auditado.

### Regla Graphify

Antes de una busqueda amplia o analisis arquitectonico, consulta el grafo actual con `graphify query`, `graphify path` o `graphify explain`. Abre y verifica los archivos fuente citados antes de proponer o modificar cambios. Si no hay un grafo actual o la consulta falla, indicalo y usa `rg` y lectura directa; no inventes resultados. Genera o actualiza el grafo de forma deliberada con `graphify .` o `graphify update .`, respetando `.graphifyignore`.

---

## Skills

Skills instalados mediante symlinks en `~/.claude/skills/` y, cuando son compatibles, en `$CODEX_HOME/skills/`.

### Superpowers
- Repositorio: https://github.com/obra/superpowers
- Instalado en: `~/.claude/skills/<nombre>` y `$CODEX_HOME/skills/<nombre>` (symlinks) -> `setup-ai-tools/superpowers/skills/<nombre>`; Claude agrega su hook SessionStart mediante `install.sh`
- Alcance: global

Metodologia completa de desarrollo de software para agentes de codificacion. Al iniciar sesion, inyecta automaticamente instrucciones via hook y pone a disposicion un conjunto de skills que el agente debe invocar segun el contexto.

Skills disponibles:
- `brainstorming` - Refinamiento de ideas antes de escribir codigo
- `writing-plans` - Planes de implementacion detallados por tareas
- `executing-plans` - Ejecucion por lotes con checkpoints
- `subagent-driven-development` - Desarrollo con subagentes y revision en dos etapas
- `test-driven-development` - Ciclo RED-GREEN-REFACTOR estricto
- `systematic-debugging` - Proceso de 4 fases para encontrar la causa raiz
- `verification-before-completion` - Verificar que el problema realmente esta resuelto
- `requesting-code-review` - Checklist antes de revisiones
- `receiving-code-review` - Responder feedback de revisiones
- `using-git-worktrees` - Ramas de trabajo aisladas
- `finishing-a-development-branch` - Decision de merge/PR al terminar
- `dispatching-parallel-agents` - Flujos concurrentes con subagentes
- `writing-skills` - Crear nuevos skills siguiendo las practicas del proyecto

Consideraciones:
- Los skills se invocan con el tool `Skill`, no leyendo los archivos directamente.
- El hook `SessionStart` requiere que `CLAUDE_PLUGIN_ROOT` apunte al repositorio clonado.
- Repositorio clonado en: `setup-ai-tools/superpowers`

---

### abogado-del-diablo
- Repositorio: https://github.com/Hainrixz/abogado-del-diablo
- Instalado en Claude: `~/.claude/skills/abogado-del-diablo` (symlink) -> `setup-ai-tools/abogado-del-diablo/skills/abogado-del-diablo` (fuente real)
- Instalado en Codex: `$CODEX_HOME/skills/abogado-del-diablo` (symlink) -> `setup-ai-tools/adapters/codex/abogado-del-diablo`; su `upstream` relativo apunta a la fuente real
- Alcance: global
- Version: 1.0.0

Skill que actua como critico hostil de ideas, planes, pitches y proyectos. Asume que la idea va a fracasar y construye el caso mas fuerte posible en su contra desde 8 angulos. Prohibido validar o adular; el primer parrafo no contiene un solo cumplido.

Los 8 angulos de ataque:
1. Premisas falsas - la suposicion que si cae, cae todo
2. Mercado - si el dolor es real y pagable, no solo "nice to have"
3. Competencia - quien ya lo hace mejor, mas barato, o antes
4. Viabilidad - donde esta el "y aqui ocurre un milagro"
5. Numeros - si la matematica cierra (CAC, margen, runway)
6. Ejecucion - si este equipo con estos recursos puede lograrlo
7. Pre-mortem - narrar la autopsia detallada del fracaso
8. Punto ciego - el elefante en la sala que nadie nombro

Como invocarlo:
- Explicito: `/abogado-del-diablo [idea o plan]`
- Natural: "hazme pedazos esto", "critica sin filtros", "por que va a fallar", "pre-mortem", "red team this"
- Modo proyecto: "critica todo el proyecto" (lee el codebase completo antes de atacar)
- Modo demolicion profunda: usa subagentes en paralelo, uno por angulo

Formato de salida: VEREDICTO brutal, grietas ordenadas por severidad, causa de muerte principal, lista priorizada de que arreglar primero.

Consideraciones:
- Si hay web search disponible, busca casos reales de fracasos similares antes de opinar.
- Para demolicion profunda lanza subagentes con `Task`, uno por angulo.
- En Codex, el adaptador usa lectura local y `rg`, búsqueda web cuando esté disponible y subagentes solo cuando estén disponibles y autorizados; no presupone tools de Claude.
- Repositorio clonado en: `setup-ai-tools/abogado-del-diablo`

---

### prompt-master
- Repositorio: https://github.com/nidhinjs/prompt-master
- Instalado en Claude: `~/.claude/skills/prompt-master` (symlink) -> `setup-ai-tools/prompt-master/` (fuente real)
- Instalado en Codex: `$CODEX_HOME/skills/prompt-master` (symlink) -> `setup-ai-tools/adapters/codex/prompt-master`; su `upstream` relativo apunta a la fuente real
- Alcance: global
- Version: 1.7.0

Skill que genera prompts optimizados para cualquier herramienta de IA. Extrae 9 dimensiones de intento, detecta la herramienta destino, aplica el framework correcto automaticamente y entrega un prompt listo para pegar que funciona en el primer intento.

Capacidades principales:
- Soporte para 30+ herramientas: Claude, ChatGPT, GPT-5.x, o3/o4-mini, Gemini, Cursor, Windsurf, Claude Code, Midjourney, DALL-E, Stable Diffusion, Sora, Runway, ElevenLabs, Zapier, Make, Devin, Bolt, v0, Lovable, ComfyUI, Ollama, Qwen, DeepSeek, MiniMax y mas.
- 12 templates seleccionados automaticamente (RTF, CO-STAR, RISEN, Chain of Thought, Few-Shot, ReAct, Visual Descriptor, etc.)
- Deteccion de 35 patrones que desperdician tokens, con correccion automatica.
- Sistema de Memory Block para sesiones largas con decisiones previas.
- Modo Prompt Decompiler para adaptar o mejorar prompts existentes.

Como invocarlo:
- Naturalmente: "Write me a prompt for Cursor to refactor my auth module"
- Explicitamente: `/prompt-master`

Consideraciones:
- Pregunta max 3 preguntas de clarificacion si falta informacion critica.
- Para herramientas agentivas agrega automaticamente condiciones de parada y limites de scope.
- No agrega CoT a modelos de razonamiento nativo (o3, o4-mini, DeepSeek-R1, Qwen3 thinking).
- El adaptador Codex elimina referencias exclusivas de Claude y exige objetivo, alcance, restricciones, verificación y condición de terminación en los prompts para Codex.
- Repositorio clonado en: `setup-ai-tools/prompt-master`

---

### commit-style
- Origen: creado por el usuario. Fuente base en `appguarderia/docs/ai/commit_style_skill.md`
- Instalado en: `~/.claude/skills/commit-style/` y `$CODEX_HOME/skills/commit-style/` (symlinks) -> `setup-ai-tools/skills/commit-style/`
- Alcance: global

Skill que genera propuestas de mensaje de commit en estilo Conventional Commits a partir del diff real del repositorio. Titulo corto en ingles con verbo imperativo, cuerpo con bullets concretos, y notas de validacion solo cuando hay evidencia de que se ejecuto.

Reglas de seguridad clave:
- Nunca ejecuta `git push`, deploy, releases, PRs ni acciones remotas.
- Solo hace `git commit` local si la politica Git del proyecto lo autoriza o si el usuario lo pide explicitamente. Por defecto solo propone el mensaje.
- No afirma que se corrieron tests sin evidencia real.

Como invocarlo:
- Explicito: `/commit-style`
- Natural: "proponme el commit", "como quedaria el commit de estos cambios"

Estructura (divide para eficiencia de tokens):
- `SKILL.md` - reglas, formato de titulo/cuerpo, modos de operacion, checklists
- `references/examples.md` - ejemplos completos por tipo de proyecto (mobile, frontend, backend, scripts, CI, docs), se cargan solo cuando se necesitan

Mejoras aplicadas sobre la version original:
- Se corrigio el frontmatter (estaba sin delimitadores `---` ni `:`, por lo que Claude Code no lo cargaba como skill).
- Descripcion acortada y enfocada en que hace y cuando usarlo.
- Referencias a `git_handle.md` generalizadas a "la politica Git del proyecto".
- Bloque de inspeccion de git consolidado en un solo lugar.
- Idioma explicito: commits en ingles, respuestas al usuario en su idioma.

---

### Graphify
- Repositorio y sitio: https://github.com/Graphify-Labs/graphify y https://graphify.net/
- Paquete administrado: `graphifyy`, version `GRAPHIFY_VERSION` en `tool-versions.env`
- Instalado en Claude y Codex: `~/.claude/skills/graphify` y `$CODEX_HOME/skills/graphify` (symlinks) -> `setup-ai-tools/skills/graphify/`; el CLI se instala globalmente con `uv tool install --python 3.12`
- Alcance: global para la skill; el grafo es local por proyecto

Herramienta de exploracion basada en grafo. Ayuda a consultar relaciones y rutas del codebase antes de ampliar la busqueda textual o modificar archivos.

Como usarlo:
```bash
graphify query "How does install.sh provision Claude and Codex?"
graphify path "install.sh script" "ensure_skill_link()"
graphify explain install.sh
```

Para crear o refrescar el grafo, usa `graphify .` o `graphify update .`. La skill puede invocarse como `/graphify` en Claude y Codex. No se activa ni reconstruye automaticamente en sesiones nuevas; la regla compartida exige usarlo cuando exista un grafo actual y la tarea lo justifique.

Consideraciones:
- Requiere `uv`; el instalador usa un entorno aislado con Python 3.12 aunque el Python del sistema sea anterior.
- `.graphifyignore` excluye terceros, instrucciones generadas, metadatos Git y salidas locales. `graphify-out/` no se versiona.
- No ejecutes los instaladores upstream de Graphify en este repo: modifican `CLAUDE.md`, `AGENTS.md` y hooks con rutas absolutas. El wrapper propio preserva `PROJECT_INSTRUCTIONS.md` como fuente unica.
- `update.sh check|apply` consulta PyPI y actualiza la version fijada de `graphifyy` junto con claude-mem.

---

### Cyber Neo
- Repositorio: https://github.com/Hainrixz/cyber-neo
- Instalado en Claude: `~/.claude/skills/cyber-neo` (symlink) -> `setup-ai-tools/skills/cyber-neo/`; el upstream fijado se clona en `setup-ai-tools/cyber-neo/`
- Alcance: global en Claude; sin soporte publicado para Codex
- Version: commit fijado en `third-party-repos.txt`

Skill de auditoria de ciberseguridad en modo solo lectura. Revisa SAST, autenticacion, criptografia, secretos, dependencias, seguridad web, supply chain, CI/CD, contenedores, errores y logging, y organiza los hallazgos por severidad, CWE y OWASP.

Como invocarlo:
```text
/cyber-neo /ruta/al/proyecto
```

El wrapper carga el runbook y scripts del upstream intacto, no instala escaneres opcionales y mantiene la prohibicion de modificar, borrar o ejecutar el proyecto auditado. Solo al finalizar crea, si hace falta, `~/Documents/reports-cyber-neo/` y escribe un informe Markdown con el nombre `cyber-neo-report-{proyecto}-{fecha}.md`.

Consideraciones:
- Solo se habilito para Claude porque el upstream usa tools y variables propias de Claude Code; Codex no recibe symlink ni declaracion de compatibilidad.
- Semgrep, Trivy, Gitleaks, `npm audit`, `pip-audit` y `cargo-audit` son opcionales; no se instalan ni se ejecutan por el provisionamiento.
- El informe puede contener rutas y evidencia de seguridad, pero debe mantener secretos redactados como exige el upstream.

---

## MCP Servers

Servidores registrados con los comandos MCP nativos de cada plataforma. Ver alcance de cada uno abajo.

### Context7
- Repositorio: https://github.com/upstash/context7
- Instalado con: `claude mcp add --transport http ... -s user` y `codex mcp add context7 --url ...`
- Alcance: `user` (global en las plataformas detectadas)
- URL del servidor: `https://mcp.context7.com/mcp`

Servidor MCP que provee documentacion actualizada de librerias directamente en el contexto del agente. Resuelve el problema de que los LLMs usan documentacion desactualizada de entrenamiento, generando APIs hallucindas o ejemplos de versiones viejas.

**Nota importante:** Inicialmente se intento configurar via `~/.claude/.mcp.json`, pero ese archivo no es leido por el Claude Code CLI real (verificado con `claude mcp list`, v2.1.177). La forma correcta de dar alcance global es `claude mcp add` con `-s user`. Los otros alcances son `local` (default, solo el proyecto actual) y `project` (via `.mcp.json` en la raiz del proyecto, requiere aprobar confianza la primera vez).

Herramientas disponibles:
- `resolve-library-id` - Encuentra el ID de una libreria por nombre
- `query-docs` - Obtiene documentacion y ejemplos de codigo actualizados

Como usarlo:
- Automatico: detecta cuando preguntas sobre librerias y busca la documentacion
- Explicito: "use context7 to show me how to set up middleware in Next.js 15"
- Con ID directo: "use context7 with /vercel/next.js for app router setup"

Verificar en cualquier sesion:
```bash
claude mcp list
claude mcp get context7
codex mcp list
codex mcp get context7
```

Consideraciones:
- Sin API key funciona en modo anonimo con rate limits reducidos.
- Una cuenta y API key amplian el tier anonimo, pero son opcionales para comenzar.
- Si `codex` muestra `could not create PATH aliases` dentro de un sandbox restringido, no es un fallo de Context7. Confirma el MCP desde una Terminal normal con `codex mcp get context7`; no filtres `stderr` ni muevas `CODEX_HOME` a `/tmp`.
- Repositorio clonado en: `setup-ai-tools/context7` (solo referencia, el servidor corre remotamente).

---

## Instrucciones de Comportamiento

Reglas persistentes que modifican el comportamiento por defecto del agente. No son herramientas que se invocan, sino configuracion que cada plataforma lee automaticamente al iniciar una sesion.

### claude-token-efficient
- Repositorio: https://github.com/drona23/claude-token-efficient
- Instalado en Claude: `~/.claude/CLAUDE.md`
- Instalado en Codex: bloque administrado entre `# >>> setup-ai-tools: claude-token-efficient >>>` y `# <<< setup-ai-tools: claude-token-efficient <<<` en `$CODEX_HOME/AGENTS.md`
- Alcance: global

Conjunto de reglas que reducen el consumo de tokens (~63% menos en output) eliminando comportamientos verbosos por defecto: saludos, cierres, sobre-ingenieria, re-lectura innecesaria de archivos, etc.

Perfil instalado: Universal (6 reglas base). Perfiles adicionales disponibles en el repositorio:

| Perfil | Archivo | Ideal para |
|--------|---------|-----------|
| Universal (instalado) | `CLAUDE.md` | Cualquier proyecto |
| Coding | `profiles/CLAUDE.coding.md` | Desarrollo, code review, debugging |
| Benchmark | `profiles/CLAUDE.benchmark.md` | Benchmarks de tokens |
| Agents | `profiles/CLAUDE.agents.md` | Pipelines de automatizacion, multi-agente |
| Analysis | `profiles/CLAUDE.analysis.md` | Analisis de datos, investigacion, reportes |

Versiones avanzadas:

| Version | Estrategia | Tool calls max | Ideal para |
|---------|-----------|---------------|-----------|
| `J-drona23-v5` | Multi-archivo estructurado | 50 | Proyectos complejos |
| `K-drona23-v6` | Ejecucion one-shot | 50 | Tareas de un solo paso |
| `M-drona23-v8` | Ultra-lean | 20 | Pipelines costo-eficientes |

Consideraciones:
- El archivo CLAUDE.md agrega tokens de entrada en cada mensaje. El beneficio neto solo aplica cuando el volumen de output es alto.
- Para cambiar de perfil, reemplazar el contenido de `~/.claude/CLAUDE.md` con el perfil deseado.
- En Codex el instalador actualiza solo su bloque delimitado y preserva las instrucciones del usuario antes y después. Si los marcadores están corruptos, el archivo se conserva sin cambios; tampoco se reemplazan symlinks, directorios ni un `AGENTS.override.md` no vacío que pueda ocultar el archivo global.
- Repositorio clonado en: `setup-ai-tools/claude-token-efficient`

---

### the-architect
- Repositorio: https://github.com/Hainrixz/the-architect
- Instalado en Claude: `setup-ai-tools/the-architect/`
- Instalado en Codex: `setup-ai-tools/adapters/codex/the-architect/`, con `AGENTS.md`, plantilla de instrucciones para el proyecto destino y un symlink relativo al upstream
- Alcance: proyecto (requiere navegar al directorio)

Meta-agente de diseno de software. Al abrir el workspace correspondiente, sus instrucciones transforman al agente en "The Architect": un agente que convierte una idea en un blueprint completo de 16 secciones listo para ser ejecutado por otra instancia de agente.

Como activarlo:
```bash
cd setup-ai-tools/the-architect
claude
```

Para Codex:
```bash
cd setup-ai-tools/adapters/codex/the-architect
codex
```

Flujo de trabajo (4 fases):
1. **Discovery** - 2-3 preguntas para entender la idea y clasificarla en uno de 6 arquetipos
2. **Deep Dive** - preguntas especificas del arquetipo (auth, pagos, roles, etc.)
3. **Architecture Review** - presenta el stack tecnologico para aprobacion
4. **Generation** - genera `blueprint.md` con 16 secciones

Arquetipos disponibles:
- SaaS Web App, Marketing Site, Mobile App, API Backend, Internal Tool, Content Platform

En Claude, el blueprint generado se copia al nuevo proyecto como `CLAUDE.md`. En Codex, el adaptador genera el blueprint en `upstream/output/` e incluye un `AGENTS.md` completo para el proyecto destino.

Consideraciones:
- No instala nada globalmente. Funciona solo dentro de su propio directorio.
- Usa skills externos durante el diseno: `/deep-research`, `/ui-ux-pro-max`, `/playwright-cli`.
- En Codex, el adaptador usa las capacidades disponibles por categoría y continúa con supuestos explícitos si no hay búsqueda, documentación o herramientas visuales; no usa comandos slash exclusivos de Claude.
- El output es un archivo markdown; el usuario decide donde ejecutarlo.

---

## Plugins

Paquetes con integraciones nativas por plataforma. Combinan hooks automaticos, skills y servicios de fondo.

### claude-mem
- Repositorio: https://github.com/thedotmack/claude-mem
- Version administrada: ver `CLAUDE_MEM_VERSION` en `tool-versions.env`
- Instalado en: marketplace local de Claude y marketplace/plugin de Codex
- Alcance: global
- Instalado via: `npx claude-mem@<version> install --ide claude-code|codex-cli`

Sistema de memoria persistente para Claude Code y Codex. Captura automaticamente observaciones, genera resumenes semanticos y los inyecta como contexto en sesiones futuras del mismo proyecto.

Componentes activos:
- **Worker service**: proceso local en `http://localhost:37701` con panel web para ver memoria en tiempo real
- **Base de datos SQLite**: almacena sesiones, observaciones y resumenes en `~/.claude-mem/`
- **Vector DB Chroma**: busqueda semantica hibrida sobre las observaciones almacenadas
- **Hooks automaticos**: SessionStart, UserPromptSubmit, PostToolUse, PreToolUse (Read), Stop

Skills disponibles (invocar con `Skill` o su nombre):
- `mem-search` - Busca en memoria con lenguaje natural (`search`, `timeline`, `get_observations`)
- `learn-codebase` - Ingesta inicial del repo completo (~5 min, opcional)
- `knowledge-agent` - Agente especializado en recuperar contexto historico
- `make-plan` - Genera plan de implementacion basado en memoria del proyecto
- `smart-explore` - Exploracion de codebase guiada por memoria
- `pathfinder` - Encuentra archivos relevantes para una tarea
- `standup` - Genera reporte de standup a partir del historial
- `timeline-report` - Reporte cronologico de actividad
- `babysit` - Supervision de tareas largas con checkpoints
- `design-is` - Documenta decisiones de diseno en memoria
- `do` - Ejecuta tareas usando contexto de memoria
- `weekly-digests` - Resumen semanal de actividad
- `version-bump` - Bump de version con historial de cambios
- `wowerpoint` - Genera presentaciones desde memoria
- `how-it-works` - Explica el sistema de memoria

Como usar memoria:
```
/mem-search autenticacion        # busca en memoria sobre autenticacion
/learn-codebase                  # ingestar repo por primera vez
spawn knowledge-agent to find decisions about the database schema
```

Privacidad: usa etiquetas `<private>` para excluir contenido del almacenamiento.

Consideraciones:
- El instalador arranca el worker automaticamente y falla de forma visible si no puede dejarlo funcionando.
- El instalador rechaza un pin menor que una version ya presente en los caches de Claude o Codex; no reduzcas `CLAUDE_MEM_VERSION` manualmente. Ejecuta `./update.sh check` y luego `./update.sh apply` para avanzar la version de forma segura.
- Si un hook informa `claude-mem worker unreachable for N consecutive hooks`, consulta `http://127.0.0.1:37701/api/health`: la version debe coincidir con el pin y mostrar `initialized: true` y `mcpReady: true`. Reinstala la plataforma despues de actualizar el pin y revisa `~/.claude-mem/logs/` si no inicializa. No borres `~/.claude-mem/` como primera solucion.
- La memoria empieza a inyectarse a partir de la segunda sesion en un proyecto.
- Panel web: `http://localhost:37701`
- La memoria se acumula en `~/.claude-mem/` (local, no se sincroniza).
- Conflicto de peer deps `tree-sitter` resuelto con `--legacy-peer-deps` en la instalacion (benigno).
- Para desinstalar: `npx claude-mem uninstall` (cerrar todas las sesiones antes).
