---
name: pen
description: Utiliser Pen (pen.dev) depuis Claude Code via le serveur MCP `pencil` — pièges connus sur cette machine (socket, fichier ouvert, export). À lire dès qu'il s'agit de dessiner/modifier une maquette dans Pen, de piloter le canvas, ou d'un souci de connexion MCP `pencil`.
---

# Pen (pen.dev) via MCP `pencil`

L'app desktop Pen enregistre elle-même un serveur MCP `pencil` (stdio, scope user) dans Claude Code et Codex à chaque lancement. Elle doit tourner pour que les outils agissent sur le canvas.

## Avant de commencer

1. `get_app_state` : si "Currently active canvas editor" est absent, **aucun fichier n'est ouvert** — le Dashboard seul ne suffit pas, et `filePath` n'ouvre rien à ta place. Demander à Yanis d'ouvrir/créer un `.pen` dans Pen (Ctrl+O, "+ New File"), ou l'ouvrir soi-même via Ctrl+O si l'automatisation clavier est acceptable.
2. `read_skill` (SKILL.md) puis `read_skill({path:"execute.md"})` et `pen-schema.md` : c'est la doc officielle de l'API `execute`, ne pas travailler de mémoire.

## Pièges vérifiés (2026-09-15)

- **Ne jamais lancer `pen <fichier.pen>` (ni `xdg-open`) pendant que Pen tourne déjà.** La seconde instance recrée `~/.pencil/socket/pencil-desktop.sock`, passe la main à la première via le verrou single-instance, puis **supprime le socket en quittant**. Symptôme : `failed to connect to running Pencil app: desktop ... transport not connected`. Seul remède : quitter Pen complètement et le relancer (le fichier peut être passé en argument **au premier lancement seulement**).
- **Un seul client MCP à la fois** : des appels `pencil` lancés en parallèle échouent avec `you are probably referencing the wrong .pen file`. Sérialiser.
- **`Export`/`TakeScreenshot` dans le même appel que la création** peut rendre un écran incomplet (layout pas encore calculé, faux "fully clipped" dans `ctx.problems`). Vérifier et exporter dans un appel `execute` suivant.
- Les icônes `lucide` n'ont pas `chrome` ; utiliser `globe` (ou vérifier le nom dans les warnings retournés).

## Fichiers

- Doc de test : `~/Documents/pen/maquette-test.pen`, exports dans `~/Documents/pen/exports/`.
- Packaging NixOS de Pen et mise à jour de version : voir `~/nixos-config/CLAUDE.md` (section Pen) et `~/nixos-config/nixos/pen.nix`.
