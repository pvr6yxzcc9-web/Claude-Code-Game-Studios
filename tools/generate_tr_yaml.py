"""Append extracted TRs to docs/architecture/tr-registry.yaml."""
import json
import sys
from datetime import date

src = r'C:\Users\suxiu\Desktop\my-game\docs\architecture\tr-extracted.json'
dst = r'C:\Users\suxiu\Desktop\my-game\docs\architecture\tr-registry.yaml'

with open(src, 'r', encoding='utf-8') as f:
    trs = json.load(f)

today = '2026-06-12'

# Build YAML manually (avoid extra deps)
lines = []
lines.append('# Technical Requirement ID Registry')
lines.append('#')
lines.append('# PURPOSE: Persistent, stable IDs for every GDD technical requirement.')
lines.append('# Prevents TR-ID renumbering across /architecture-review runs, which would')
lines.append('# break story references.')
lines.append('#')
lines.append('# RULES:')
lines.append('#   - IDs are PERMANENT. Never renumber, never delete (use status: deprecated).')
lines.append('#   - Add new entries only at the END of each system\'s list.')
lines.append('#   - When a GDD requirement is reworded (same intent): update `requirement`')
lines.append('#     text and add a `revised` date. The ID stays the same.')
lines.append('#   - When a requirement is removed from the GDD: set status: deprecated.')
lines.append('#   - When a requirement is split or replaced: set status: superseded-by with')
lines.append('#     the new TR-ID(s).')
lines.append('#')
lines.append('# WRITTEN BY: /architecture-review (appends new entries, never overwrites)')
lines.append('# READ BY:    /create-stories (embed IDs in stories)')
lines.append('#             /story-done (look up current requirement text at review time)')
lines.append('#             /story-readiness (validate TR-ID exists and is active)')
lines.append('#')
lines.append('# ID FORMAT: TR-[system-slug]-[NNN]')
lines.append('#   system-slug = short slug matching the GDD system name')
lines.append('#   NNN = three-digit zero-padded sequence per system, starting at 001')
lines.append('#')
lines.append('# STATUS VALUES: active | deprecated | superseded-by: TR-[system]-NNN')
lines.append('')
lines.append(f'version: 2')
lines.append(f'last_updated: "{today}"')
lines.append('')
lines.append('requirements:')

for tr in trs:
    rid = tr['id']
    system = tr['system']
    gdd = tr['gdd']
    req = tr['requirement'].replace('"', '\\"').replace('\n', ' ')
    domain = tr['domain']
    risk = tr['engine_risk']
    lines.append(f'  - id: {rid}')
    lines.append(f'    system: {system}')
    lines.append(f'    gdd: {gdd}')
    lines.append(f'    domain: {domain}')
    lines.append(f'    engine_risk: {risk}')
    lines.append(f'    requirement: "{req}"')
    lines.append(f'    created: "{today}"')
    lines.append(f'    revised: ""')
    lines.append(f'    status: active')
    lines.append('')

with open(dst, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'Wrote {len(trs)} TRs to {dst}')
