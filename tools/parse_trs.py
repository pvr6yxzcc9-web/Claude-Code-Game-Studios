import json
import sys
from collections import Counter

path = r'C:\Users\suxiu\.claude\projects\C--Users-suxiu-Desktop-my-game\dabcc041-8733-48ad-9e6e-4063433727e2\tool-results\call_function_wg4e3q4b1spw_1.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
text = data[0]['text']
idx = text.find('[\n  {\n    "id"')
if idx == -1:
    idx = text.find('[\n  {')
print(f'Start: {idx}')

depth = 0
end_idx = -1
in_string = False
escape_next = False

for i in range(idx, len(text)):
    ch = text[i]
    if escape_next:
        escape_next = False
        continue
    if ch == chr(92):  # backslash
        escape_next = True
        continue
    if ch == chr(34):  # double quote
        in_string = not in_string
        continue
    if in_string:
        continue
    if ch == '[':
        depth += 1
    elif ch == ']':
        depth -= 1
        if depth == 0:
            end_idx = i + 1
            break

print(f'End: {end_idx}')

if end_idx > 0:
    json_str = text[idx:end_idx]
    try:
        trs = json.loads(json_str)
        print(f'Parsed {len(trs)} TRs')
        c = Counter(t['system'] for t in trs)
        for s, n in sorted(c.items()):
            print(f'  {s}: {n}')
        risks = Counter(t['engine_risk'] for t in trs)
        print(f'Risks: {dict(risks)}')
        domains = Counter(t['domain'] for t in trs)
        print(f'Domains: {dict(domains)}')
        out = r'C:\Users\suxiu\Desktop\my-game\docs\architecture\tr-extracted.json'
        with open(out, 'w', encoding='utf-8') as f:
            json.dump(trs, f, ensure_ascii=False, indent=2)
        print('Written')
    except json.JSONDecodeError as e:
        print(f'Error: {e}')
        ctx = json_str[max(0, e.pos-80):e.pos+80]
        print(f'Context: {repr(ctx)}')
