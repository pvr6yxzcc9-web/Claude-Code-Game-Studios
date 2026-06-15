# Railhunter — itch.io Page Config

> **Status**: Draft (S6-013)
> **Target price**: USD 7.99 (or "Name your price" with $7.99 minimum — better for early audience reach)
> **Channel**: itch.io (primary indie discovery)
> **Page type**: HTML (download + info)

---

## 1. Page text (paste into itch.io description editor)

> ### Railhunter
>
> **A turn-based 2D pixel sci-fi RPG. 3-5 hours. Zero filler. Every room has a reward.**
>
> In the year 2300, the Marrow research satellite has been silent for 50 years. You pilot a customizable mech called the **Rover** through its abandoned corridors. The salvage crews keep coming back. So do the things that hunt in the dark.
>
> **What's in this build:**
> - 10 hand-crafted rooms with combat, NPCs, terminals, and hidden areas
> - 8 weapons, 6 ammo types, 3 mech part slots
> - 12 story fragments, 3 endings
> - Full HUD with HP, weapon slots, mech status, fragment counter
> - State machine (title / exploration / battle / dialogue / terminal / menu / codex / save-load / game over)
> - 3-5 hour playthrough
>
> **How to play:**
> - WASD or arrow keys to move
> - E to interact (terminals, NPCs, doors)
> - 1/2/3 to switch weapons, Q to cycle mech parts
> - C to open Codex, M for manual/auto mode
> - Esc to pause, Tab to save/load
>
> **System requirements:** Any PC made in the last 5 years. GPU-light (2D pixel art).
>
> **License:** Single-user commercial. You buy a copy, you play it, you don't redistribute the binary.
>
> **Made with:** Godot 4.6 (MIT), GDScript + C#, Python (for art + audio synthesis pipeline).
>
> **Questions / bug reports:** Discord link or GitHub issues (see devlog)

---

## 2. Project metadata

| Field | Value |
| --- | --- |
| **Title** | Railhunter |
| **Author** | [developer handle] |
| **Kind of project** | Game |
| **Platform** | Windows, Linux, macOS |
| **Downloads orientation** | Child (downloads are the page content) |
| **Pricing** | "Name your price" with $0 minimum, $7.99 suggested |
| **Tags** | turn-based, RPG, sci-fi, mech, pixel-art, short, indie, single-player |

---

## 3. Build configuration (butler push)

`butler` is itch.io's official CLI for uploading builds.

### Install butler
```bash
# macOS
brew install slashmo/butler/butler

# Windows (scoop)
scoop install butler

# Linux
curl -L https://itch.io/api/download/butler/linux-amd64/latest -o butler
chmod +x butler && sudo mv butler /usr/local/bin/
```

### Login
```bash
butler login
```

### Project setup
```bash
# Create a new project on itch.io first, get the project ID
# Then create a channel for the build:
butler create [username]/railhunter
```

### Build the game (Linux example)
```bash
# Already covered in tools/build.sh — outputs build/railhunter.x86_64
bash tools/build.sh linux
```

### Push to itch.io
```bash
# Linux build
butler push build/railhunter.x86_64 [username]/railhunter:linux --userversion 0.1.0

# Windows build
butler push build/railhunter.exe [username]/railhunter:windows --userversion 0.1.0

# Mac build (when available)
butler push build/railhunter.dmg [username]/railhunter:mac --userversion 0.1.0
```

---

## 4. Build artifacts

After running `tools/build.sh`, the following should exist in `build/`:

| File | Platform | Approx size |
| --- | --- | --- |
| `railhunter.x86_64` | Linux/X11 | ~80 MB (Godot runtime + game data) |
| `railhunter.exe` | Windows | ~80 MB |
| `railhunter.dmg` (when built) | macOS | ~80 MB |

**Pessimistic first-time export sizes are ~80 MB.** Godot's export templates are ~30 MB; game assets (sprites + music + sfx) are currently ~7 MB. Rest is engine + Windows runtime.

---

## 5. Launch parameters (optional)

The game supports these command-line flags for testing:

```
--headless         run without rendering (for CI)
--quit-after=N     exit after N seconds
--validate-state   print state machine transitions to stdout
```

These are passed through Godot's `OS.get_cmdline_args()`.

---

## 6. Screenshot capture plan

For the itch.io page, we need:

1. **Title card** — main menu (`assets/sprites/title_card.png` to be added)
2. **Exploration shot** — mech in a room
3. **Combat shot** — turn-based battle mid-action
4. **Boss fight** — Marrow Sentinel
5. **Codex/HUD** — full UI visible
6. **Ending** — one of 3 endings

Capture method: F5 in Godot editor → use `screenshot-auto` script (Godot's `get_viewport().get_texture().get_image().save_png()`) or take a screen capture manually.

Output: `production/store/screenshots/0X_[name].png`, 1920×1080, ~50KB each.

---

## 7. HTML embed (advanced)

For a richer itch.io page, we can embed an HTML widget in the page body:

```html
<div class="railhunter-hero">
  <h1>Railhunter</h1>
  <p class="tagline">A turn-based 2D pixel sci-fi RPG.</p>
  <iframe width="640" height="360" src="https://www.youtube.com/embed/[VIDEO_ID]" 
          title="Railhunter gameplay trailer" frameborder="0" 
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
          allowfullscreen></iframe>
</div>
```

Trailer video: TODO. 30-60 second F5 capture showing room → combat → boss → ending, with text overlays. Outside S6-013 scope.

---

## 8. Distribution checklist

- [ ] itch.io project created
- [ ] butler installed and logged in
- [ ] Page text copied
- [ ] Tags set (turn-based, RPG, sci-fi, mech, pixel-art, short)
- [ ] Pricing set (name your price, $7.99 suggested)
- [ ] Linux build pushed (`build/railhunter.x86_64`)
- [ ] Windows build pushed (`build/railhunter.exe`)
- [ ] At least 3 screenshots uploaded
- [ ] Description page reviewed (no typos, links work)
- [ ] Page made public (or unlisted for soft launch)
- [ ] Devlog entry posted with launch announcement

**Estimated time from page creation to public listing**: 30 minutes. The build pushes take 5-10 minutes each depending on file size.

---

## 9. Differences from Steam (S6-012)

| Aspect | Steam | itch.io |
| --- | --- | --- |
| **Price floor** | $4.99 minimum | $0 (or no minimum) |
| **Review process** | Valve review (1-7 days) | None |
| **Discovery** | Search + recommendations | Less built-in, more community-driven |
| **Audience** | Broad PC gamers | Indie + game dev community |
| **Refund policy** | Steam's standard 2-hour refund | No refunds (or "name your price" means no purchase) |
| **Payout** | 70/30 after $10K | 100% minus payment processor (10% default) |

**Recommended strategy**: launch on **itch.io first** to build indie + dev community awareness, then go to **Steam** with a polished trailer. Many indie devs use itch.io as a "soft launch" platform for community feedback.

---

## 10. Source files

- Steam equivalent: `production/store/steam-page.md`
- Build script: `tools/build.sh`
- Game concept: `design/gdd/game-concept.md`
- Sprites + audio: `assets/sprites/`, `assets/audio/`
