# Railhunter — Steam Store Page Copy

> **Status**: Draft (S6-012)
> **Target price**: USD 7.99 (in the 5-12 USD indie short-form range)
> **Tags** (Steam, 3 max for primary, more secondary): Turn-Based, RPG, Sci-fi, Mechs, Short, Pixel Graphics
> **Release target**: Q3 2026 (post-polish)

---

## 1. Short description (300 chars max — appears above the fold)

> A turn-based 2D pixel sci-fi RPG. Pilot a customizable mech through an abandoned research satellite. Hunt hidden enemies, scavenge 8 weapons × 6 ammo types, piece together the truth one fragment at a time. 3-5 hours. Zero filler. Every room has a reward.

**Char count**: 286 (under 300 limit)

---

## 2. Long description (no Steam hard limit, but keep under 5000 words for readability)

### 2300. The Marrow research satellite has been silent for 50 years. You are the next pilot to walk its halls.

In **Railhunter**, you pilot a customizable mech called the **Rover** through the abandoned corridors of a deep-space research station. The satellite was sealed after an unexplained incident — but the salvage crews, the relic hunters, and the smugglers keep coming back. So do the things that hunt in the dark.

This is a **turn-based 2D pixel RPG** in the spirit of **FC 魔神英雄传 / Metal Max / Into the Breach** — every step into an unknown room is a gamble, every enemy you kill is a learnable encounter, and the truth about what happened here is not told to you. It is **collected**, one fragment at a time, from terminal logs, NPC dialogue, hidden rooms, and the weapons you leave behind.

### 🔫 Weapon × Ammo Build Depth

8 weapons and 6 ammo types. Every weapon has unique damage profiles, crit stats, and effects. Every ammo has a damage multiplier + status effect. Combine them and you have **48 distinct combat builds** before counting the mech parts.

Examples:
- **Railgun + Slug Ammo** → high single-target crit, no splash
- **Plasma Cannon + Plasma Rounds** → AoE burn, slow but devastating
- **Shotgun + Scatter Ammo** → close-range burst, weak at range
- **Mine Layer + Proximity Mines** → pre-place hazards, force enemy movement

### 🤖 Customizable Mech

3 mech part slots: **Torso / Left Arm / Right Arm**. Each part changes your stats and which weapons you can equip. Cycle parts in combat with **Q**. Mix and match to find your loadout.

### 🌌 Story You Assemble, Not Read

12 story fragments. Find them in:
- Terminal logs (E to read)
- NPC dialogue choices
- Hidden rooms behind breakable walls
- The Codex menu (C to open)

The Marrow Sentinel boss fight in Room 9 isn't the end of the story. The ending you see depends on which fragments you collected. **3 endings total**, only 1 is the "true" ending.

### 🎮 3-5 Hours, Zero Filler

No random encounters that waste your time. No padding levels. No "talk to every NPC twice" fetch quests. Every room has a reason to be there. Every NPC has a story. When the credits roll, you'll feel like you played a **tight, complete** experience.

### ♿ Accessibility

- Full keyboard + gamepad support
- Toggle between **Manual** (you pick every attack) and **Auto** (M) modes for any combat
- 60+ FPS on any laptop made in the last 5 years
- Scaled text and colorblind-friendly palette (neon-on-dark, no red/green-only color signals)

### 🛠️ Made By

A solo developer in their first year of building games. **Railhunter** is the first commercial release from the project — built in **Godot 4.6** with a custom GDScript + C# + Python pipeline (the synth-art generator is in the repo, MIT-licensed, so anyone can fork it).

---

## 3. Capsule images (required by Steam)

| Asset | Size | Status | Notes |
| --- | --- | --- | --- |
| **Header capsule** | 460×215 | TODO | Game logo + mech sprite + "TURN-BASED ROGUE RPG" tag |
| **Main capsule** | 616×353 | TODO | Hero shot of mech in front of Marrow Sentinel silhouette |
| **Small capsule** | 120×45 | TODO | Logo only |
| **Library hero** | 3840×2160 | TODO | Wide battle scene with explosions |
| **Library logo** | 1280×720 | TODO | Logo on transparent bg |

All capsule art needs to be created in a follow-up task. **Do not** ship placeholder art to Steam.

---

## 4. Screenshots (6 recommended, 1920×1080 each)

Planned screenshots (to be captured during S6-014 final F5 walkthrough):

1. **Title screen** — main menu with logo + "PRESS START"
2. **Exploration** — mech standing in a tile-textured room, door + NPC visible
3. **Combat** — turn-based fight with HP bars + damage popup + flash feedback
4. **Boss fight** — Marrow Sentinel at 200 HP, camera shake mid-hit
5. **HUD closeup** — full UI with HP bar, weapon slots, mech part indicators
6. **Ending** — one of the 3 endings, showing the final fragment collected (e.g. `FRAGMENTS: 12/12`)

---

## 5. System requirements

| | Minimum | Recommended |
| --- | --- | --- |
| **OS** | Windows 10 / macOS 10.15 / Ubuntu 18.04 | Windows 11 / macOS 12+ / Ubuntu 22.04 |
| **CPU** | 2.0 GHz dual-core | 3.0 GHz quad-core |
| **RAM** | 2 GB | 4 GB |
| **GPU** | OpenGL 3.3 / Vulkan 1.0 | OpenGL 4.6 / Vulkan 1.2 / Metal 2 |
| **Storage** | 200 MB | 200 MB |
| **Display** | 1280×720 | 1920×1080 |

Game is **GPU-light** (2D pixel art, no shaders, no lighting) — frame budget is dominated by draw call count, which is well under 200 per scene.

---

## 6. Pricing & release

- **USD 7.99** (regional pricing will be set on Steamworks dashboard)
- **No** launch discount
- **No** microtransactions, DLC, or in-game purchases
- **Release target**: Q3 2026 (after final F5 walkthrough S6-014 confirms ship-readiness)

---

## 7. Submission checklist

- [ ] All 6 screenshots captured (1920×1080)
- [ ] Header capsule (460×215) — paid designer or use placeholder
- [ ] Main capsule (616×353) — paid designer or use placeholder
- [ ] Steam page text reviewed by 1+ outside reader
- [ ] Mature content questionnaire submitted
- [ ] Store tags chosen (Turn-Based / RPG / Sci-fi / Mechs / Short / Pixel Graphics)
- [ ] Pricing + regional matrix set in Steamworks
- [ ] Build uploaded (Linux + Windows + Mac)
- [ ] Depots configured per platform
- [ ] Release date set

**Estimated time to ship once approved**: 2-3 weeks (mostly waiting on Valve's review and capsule art).

---

## 8. Source files

- Game concept (elevator pitch, pillars): `design/gdd/game-concept.md`
- Art bible: `design/art/art-bible.md`
- Screenshot capture: will be F5-driven, saved to `production/store/screenshots/`
- Capsule art: TODO (separate task — outside S6-012 scope)
