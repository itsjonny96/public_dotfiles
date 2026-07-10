#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
query="${1#"${1%%[![:space:]]*}"}"

# Show cheat sheet when no query
if [ -z "$query" ]; then
  echo '{"items":[{"title":"BMM Bookmarks","subtitle":"⏎ Open │ ⌘⏎ Default browser │ ⇧⏎ Paste URL │ -a [url] | title | tags to add","valid":false}]}'
  exit 0
fi

# Add mode: bmm -a [url] | title | tags
if [[ "$query" == -a* ]]; then
  rest="${query#-a}"
  rest="${rest# }"
  clipboard=$(pbpaste 2>/dev/null)

  python3 - "$rest" "$clipboard" << 'PYEOF'
import json, sys, re, os

rest = sys.argv[1].strip() if len(sys.argv) > 1 else ""
parts = [p.strip() for p in rest.split('|')]
clipboard = sys.argv[2].strip() if len(sys.argv) > 2 else ""

uri = ''
title = ''
tags = ''

if parts[0] and re.match(r'https?://', parts[0]):
    uri = parts[0]
    title = parts[1] if len(parts) > 1 else ''
    tags = parts[2] if len(parts) > 2 else ''
else:
    uri = clipboard
    title = parts[0] if parts[0] else ''
    tags = parts[1] if len(parts) > 1 else ''

if not uri or not re.match(r'https?://', uri):
    print(json.dumps({'items': [{'title': 'No valid URL found', 'subtitle': 'Copy a URL first or provide one: -a https://... | title | tags', 'valid': False}]}))
    sys.exit(0)

subtitle = uri
if tags:
    subtitle += f'  [tags: {tags}]'

print(json.dumps({'items': [{
    'title': f'Save: {title}' if title else f'Save: {uri}',
    'subtitle': subtitle,
    'arg': uri,
    'variables': {'action': 'add', 'uri': uri, 'title': title, 'tags': tags},
}]}))
PYEOF
  exit 0
fi

# Search mode: load all bookmarks, fuzzy filter with fzf
bmm list --format json 2>/dev/null | python3 -c "
import json, sys, subprocess

try:
    data = json.load(sys.stdin)
except:
    data = []

if not data:
    print(json.dumps({'items': [{'title': 'No bookmarks found', 'valid': False}]}))
    sys.exit(0)

query = '''$query'''.strip()

# Build lines for fzf: index\ttitle\turi\ttags
lines = []
for i, b in enumerate(data):
    uri = b.get('uri', '')
    title = b.get('title', '') or uri
    tags = b.get('tags', '') or ''
    lines.append(f'{i}\t{title}\t{uri}\t{tags}')

fzf_input = '\n'.join(lines)

if query:
    try:
        result = subprocess.run(
            ['fzf', '--filter', query, '--delimiter', '\t', '--with-nth', '2,3,4'],
            input=fzf_input, capture_output=True, text=True
        )
        matched_lines = [l for l in result.stdout.strip().split('\n') if l]
    except:
        matched_lines = []
else:
    matched_lines = lines

if not matched_lines:
    print(json.dumps({'items': [{'title': 'No results', 'subtitle': f'No bookmarks matching \"{query}\"', 'valid': False}]}))
    sys.exit(0)

items = []
for line in matched_lines:
    parts = line.split('\t')
    idx, title, uri, tags = parts[0], parts[1], parts[2], parts[3] if len(parts) > 3 else ''
    browser = 'default'
    if 'browser-chrome' in tags:
        browser = 'chrome'
    elif 'browser-safari' in tags:
        browser = 'safari'
    elif 'browser-firefox' in tags:
        browser = 'firefox'
    items.append({
        'title': title,
        'subtitle': uri,
        'arg': uri,
        'variables': {'action': 'open', 'uri': uri, 'browser': browser},
        'match': f'{title} {uri}',
        'mods': {
            'cmd': {
                'subtitle': 'Open in system default browser',
                'arg': uri,
                'variables': {'action': 'open-default', 'uri': uri},
            },
            'shift': {
                'subtitle': 'Paste URL',
                'arg': uri,
                'variables': {'action': 'paste', 'uri': uri},
            },
        },
    })

print(json.dumps({'items': items}))
"
