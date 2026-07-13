# Guia de uso

Como usar cada herramienta instalada en `setup-skills`. Para la ficha tecnica completa (rutas, version, alcance) ver `PROJECT_INSTRUCTIONS.md`.

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

## Context7 (MCP)

Trae documentacion actualizada de librerias y frameworks directo al contexto, evitando que Claude invente APIs o use ejemplos de versiones viejas. Se activa automaticamente al detectar preguntas sobre librerias; tambien se puede invocar explicito.

**Ejemplos:**
```
use context7 to show me how to set up middleware in Next.js 15
```
```
use context7 with /vercel/next.js for app router setup
```

---

## the-architect

Meta-agente de diseno de software. Se activa entrando a su propio directorio con Claude Code. Convierte una idea de proyecto en un blueprint de 16 secciones (stack, arquitectura, modelos de datos, deploy) tras 3 fases de preguntas, listo para que otra sesion de Claude Code lo ejecute.

**Ejemplos:**
```bash
cd setup-skills/the-architect
claude
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

No es una herramienta que se invoque: son reglas en `~/.claude/CLAUDE.md` que Claude lee automaticamente en cada sesion para reducir verbosidad (sin saludos, sin cierres, sin sobre-ingenieria). Aplica solo, sin ejemplos de invocacion.
