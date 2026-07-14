# setup-ai-tools

Configuracion portable de herramientas de IA para terminal, con trazabilidad para moverla entre maquinas o compartirla. La fuente del proyecto es independiente de Claude Code y Codex.

## Empieza aqui

Si ya estas usando Claude Code, Codex u otro agente, solo dile exactamente esto:

> Clona `https://github.com/alvarezdev/setup-ai-tools.git` y ejecuta su instalador.

El agente que ejecuta el instalador funciona como operador: cualquier agente puede configurar cualquier plataforma registrada.

Eso es todo. No necesitas conocer comandos, elegir plataformas ni configurar archivos manualmente. El agente clonara el repositorio y ejecutara:

```bash
git clone https://github.com/alvarezdev/setup-ai-tools.git && cd setup-ai-tools && ./install.sh
```

El instalador detecta los agentes disponibles, configura lo compatible y arranca los servicios automaticamente.

Este repo versiona **solo trabajo propio**. Los proyectos de terceros no se copian aqui: se referencian por URL y commit en `third-party-repos.txt` y los clona `install.sh`.

## Que contiene este repo

- `skills/commit-style/` - skill propio (Conventional Commits desde el diff real)
- `PROJECT_INSTRUCTIONS.md` - fuente generica de instrucciones e inventario
- `third-party-repos.txt` - manifiesto de repos de terceros (URL + commit)
- `tool-versions.env` - versiones fijadas de paquetes instalados con otros gestores
- `platforms.txt` - registro extensible de plataformas, CLI y archivo de instrucciones
- `platform-compatibility.txt` - soporte y adaptaciones requeridas por plataforma
- `install.sh` - bootstrap idempotente para una maquina nueva
- `manage.sh` - administra herramientas y manifiestos; uso exclusivo del mantenedor
- `update.sh` - consulta y aplica actualizaciones de terceros de forma explicita
- `verify-compatibility.sh` - valida las herramientas de cualquier plataforma registrada
- `tests/` - pruebas de regresion y auditoria offline del instalador
- `.gitignore` - ignora los directorios de terceros que clona `install.sh`

## Uso en una maquina nueva

La instalacion normal no necesita opciones. Los siguientes comandos quedan solo para mantenimiento o pruebas:

```bash
./install.sh --platform claude
./install.sh --platform codex
./install.sh --platform claude --platform codex
```

Para generar solamente los archivos de instrucciones, sin clonar ni instalar herramientas:

```bash
./install.sh --platform claude --platform codex --instructions-only
```

`install.sh` hace, en orden:
1. Genera desde `PROJECT_INSTRUCTIONS.md` el archivo local declarado por cada plataforma: `CLAUDE.md`, `AGENTS.md` o ambos.
2. Verifica las herramientas declaradas para todas las plataformas seleccionadas.
3. Crea los repos ausentes y reconcilia los existentes contra su URL y version declaradas.
4. Instala en Claude y Codex los skills que tienen soporte verificado, sin sobrescribir instalaciones ajenas.
5. Instala claude-mem para cada plataforma, arranca su worker y registra Context7.

Las herramientas de Codex que todavia necesitan adaptación (`prompt-master`, `abogado-del-diablo`, `the-architect` y `claude-token-efficient`) se omiten de forma explícita; el resto queda funcionando automáticamente.

Los archivos generados llevan una marca de administracion. Si encuentra un `CLAUDE.md` o `AGENTS.md` ajeno, cambios Git rastreados, un `origin` diferente, una carpeta real o un symlink que apunta a otra fuente, se detiene sin reemplazar ese elemento.

El repositorio puede moverse a otra carpeta. `install.sh` conserva por defecto en `~/.local/state/setup-ai-tools/managed-roots` las rutas que ha administrado y, al ejecutarse desde la nueva ubicacion, migra los symlinks de Claude y Codex sin tocar destinos ajenos. Las instalaciones anteriores a este registro tambien se reconocen cuando existen varios symlinks rotos y consistentes con la estructura del proyecto.

Las instalaciones creadas cuando el proyecto se llamaba `setup-skills` se migran automaticamente: el instalador reconoce su marca y su estado en `~/.local/state/setup-skills`, y publica el estado actualizado bajo el nombre nuevo.

Si ya existe una herramienta instalada por otra fuente, el instalador no la reemplaza ni detiene las herramientas restantes. Para Superpowers compara `origin`, commit y estado Git: reutiliza una instalacion externa identica; si difiere, la conserva, omite solo esa integracion y muestra el conflicto al final. La transferencia de administracion debe ser explicita:

```bash
./install.sh --platform claude --migrate-tool superpowers
./install.sh --platform codex --migrate-tool superpowers
```

La migracion solo reemplaza symlinks; nunca elimina carpetas reales. La ruta, el origin y el commit anteriores quedan registrados en `~/.local/state/setup-ai-tools/migrations.log` para facilitar una restauracion manual.

Context7 funciona de inmediato en el tier anonimo; agregar una API key es opcional.

## Terceros

Los proyectos referenciados (superpowers, prompt-master, abogado-del-diablo, context7, claude-token-efficient, the-architect) son repos independientes con licencia MIT, propiedad de sus autores. Aqui solo se referencian por URL; su codigo no forma parte de este repo. Ver `third-party-repos.txt` y la seccion correspondiente en `PROJECT_INSTRUCTIONS.md`.

## Versiones al clonar en una maquina nueva

- `pinned` (superpowers, prompt-master, abogado-del-diablo, the-architect): la maquina nueva queda en el mismo commit que la anterior. Reproducible.
- `shallow` (context7, claude-token-efficient): traen el ultimo estado de la rama al momento de correr `install.sh`, NO una version fija. Es intencional porque son solo referencia (el MCP de context7 corre remoto y las reglas de token-efficient ya viven en `~/.claude/CLAUDE.md`). Si el autor upstream las cambia, recibiras la version nueva.

Para fijar uno de los `shallow`: en `third-party-repos.txt` cambia su modo a `pinned` y pon un commit; borra su carpeta y vuelve a correr `install.sh`.

## Actualizar herramientas

Las instalaciones normales permanecen reproducibles. Las actualizaciones se hacen de forma explicita:

```bash
./update.sh check
./update.sh apply
```

`check` compara los commits fijados y la version de claude-mem con upstream sin modificar archivos. `apply` actualiza los clones locales, valida que conserven sus archivos esenciales y guarda los nuevos commits `pinned` en `third-party-repos.txt` y la nueva version de claude-mem en `tool-versions.env`.

Los repositorios `shallow` siguen intencionalmente el ultimo commit de su rama porque solo se conservan como referencia. Si un repositorio tiene cambios rastreados, `apply` se detiene antes de actualizar; los archivos no rastreados se conservan y Git evita sobrescribirlos si entran en conflicto.

## Administrar herramientas (solo mantenedor)

Los usuarios finales no necesitan `manage.sh`: solo ejecutan `install.sh`. `manage.sh` modifica localmente la fuente de verdad del repositorio, pero nunca instala, borra clones, crea commits ni hace push. Los permisos del repositorio remoto determinan quien puede publicar esos cambios.

Operaciones principales:

```bash
./manage.sh list
./manage.sh tool add <nombre> <url> <rama> pinned <commit>
./manage.sh tool update <nombre> latest
./manage.sh compatibility set <herramienta> <plataforma> <soporte> <ruta|-> "<detalle>"
./manage.sh tool remove <nombre>
./manage.sh validate
./manage.sh audit
```

Para un skill o MCP nuevo, registra primero su repositorio o version y luego una fila de compatibilidad por plataforma. Si la herramienta necesita comandos, hooks o rutas de instalacion diferentes a las existentes, tambien debe agregarse su provisionamiento a `install.sh` y una prueba de regresion. El gestor no supone automaticamente como integrar codigo de terceros desconocido.

`tool remove` quita el repositorio y su compatibilidad de los manifiestos, pero conserva el directorio local y su regla en `.gitignore` para impedir que codigo tercero se agregue accidentalmente al repo. Usa `./manage.sh --help` para ver plataformas, versiones y todas las variantes disponibles.

`manage.sh tool update` cambia una herramienta puntual; `update.sh check|apply` sigue siendo el flujo para revisar o avanzar todas las dependencias desde upstream en una sola operacion. Despues de cualquier cambio de mantenimiento, actualiza `PROJECT_INSTRUCTIONS.md` y `GUIDE.md`, ejecuta `./manage.sh audit`, revisa el diff y solo entonces crea el commit.

## Verificar compatibilidad y regresiones

```bash
./verify-compatibility.sh --platform claude --phase post
./verify-compatibility.sh --platform codex --phase post
./tests/test_install.sh
./tests/test_compatibility.sh
./tests/test_instructions.sh
./tests/test_manage.sh
./tests/audit_project.sh
```

El verificador devuelve `0` cuando todo es compatible, `2` cuando faltan adaptadores y `1` ante incompatibilidades o archivos requeridos ausentes. El instalador configura automáticamente lo compatible y señala lo que todavía necesita adaptación.

La validacion y la eleccion del nombre del archivo no contienen una lista fija de plataformas. Para agregar otra, registra su nombre, CLI y archivo de instrucciones en `platforms.txt`, y agrega las filas correspondientes en `platform-compatibility.txt`; los scripts la descubriran sin cambios de codigo.
