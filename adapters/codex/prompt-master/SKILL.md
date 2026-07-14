---
name: prompt-master
description: Crea prompts listos para pegar en Codex, adaptando las reglas upstream al flujo de un agente de código.
---

# Prompt Master para Codex

Lee primero `upstream/SKILL.md`. Conserva sus reglas de extracción de intención,
preguntas de aclaración y formato de salida. Si hace falta una plantilla, lee solo
la sección pertinente de `upstream/references/templates.md`.

Cuando el destino sea Codex, entrega un único prompt listo para pegar que incluya:

- objetivo y contexto relevante;
- alcance exacto y archivos o áreas permitidas;
- restricciones y acciones explícitamente prohibidas;
- verificación que Codex debe ejecutar o reportar;
- condición de terminación: qué resultado marca la tarea como terminada.

Para tareas agentic, pide a Codex inspeccionar el estado real antes de cambiarlo,
no expandir el alcance y detenerse para pedir autorización antes de acciones
externas o destructivas. No incluyas instrucciones exclusivas de Claude.
