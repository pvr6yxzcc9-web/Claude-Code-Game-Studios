# Lead Programmer — Agent Memory

## Skill Authoring Conventions

### Frontmatter
- Fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- Read-only analysis skills that run in isolation also carry `context: fork` and `agent:`
- Interactive skills (write files, ask questions) do NOT use `context: fork`
- `AskUserQuestion` is a usage pattern described in skill body text — it is NOT listed
  in `allowed-tools` frontmatter (no existing skill does this)

### File Layout
- Skills live in `.claude/skills/<name>/SKILL.md` (subdirectory per skill, never flat .md)
- Section headers use `##` for phases, `###` for sub-sections
- Phase names follow "Phase N: Verb Noun" pattern (e.g., "Phase 1: Find the Story")
- Output format templates go in fenced code blocks

### Known Canonical Paths (verify before referencing in new skills)
- Tech debt register: `docs/tech-debt-register.md` (NOT `production/tech-debt.md`)
- Sprint files: `production/sprints/`
- Epic story files: `production/epics/[epic-slug]/story-[NNN]-[slug].md`
- Control manifest: `docs/architecture/control-manifest.md`
- Session state: `production/session-state/active.md`
- Systems index: `design/gdd/systems-index.md`
- Engine reference: `docs/engine-reference/[engine]/VERSION.md`

## Engine Pitfalls (Godot 4.6)

- **Control._draw + draw_string + HiDPI = native crash** (Vulkan + Intel Iris, possibly other HiDPI displays). Symptom: pressing Esc/state_pause/etc triggers a state change whose listener calls `show()` on a Control using `draw_string(ThemeDB.fallback_font, ...)` — the `--- Debugging process stopped ---` line appears in console and the editor debugger detaches. Root cause: drawing text in `_draw()` at HiDPI-scaled Control size (e.g., 2560×1440 from 2× scale on a 1280×720 viewport) crashes Godot's render thread. **Fix: replace `draw_string`/`draw_rect` with real `Label` / `ColorRect` child nodes.** Position Labels absolutely; use `add_theme_color_override` / `add_theme_font_size_override` for styling. Keep `_draw` only for things that genuinely need procedural rendering (e.g., HP bars where you want a partial fill).
- The crash does NOT reproduce in GUT headless tests — only when the editor is actually running with a window. So passing tests ≠ working game. **Always F5 verify UI changes that touch `_draw` or `show()`.**

### Skills Completed
- `story-done` — end-of-story completion handshake (Phase 1-8, writes story file)
