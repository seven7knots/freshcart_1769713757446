import re

with open('lib/main.dart', 'rb') as f:
    raw = f.read()

text = raw.decode('utf-8').replace('\r\n', '\n')
lines = text.splitlines()

# Remove any lines containing timing probe markers
probe_patterns = [
    'final t0 = DateTime.now();',
    'int ms() =>',
    "[TIMING]",
]

new_lines = []
removed = 0
for line in lines:
    if any(p in line for p in probe_patterns):
        print(f'  removed: {line.strip()}')
        removed += 1
    else:
        new_lines.append(line)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines) + '\n')

print(f'main.dart: removed {removed} timing probe line(s) OK')
print('fix15 done')
