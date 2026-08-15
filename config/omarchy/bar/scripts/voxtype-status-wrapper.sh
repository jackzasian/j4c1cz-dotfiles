#!/usr/bin/env bash
# Wraps the packaged `omarchy-voxtype-status` (/usr/share/omarchy/bin/, read-only)
# which emits {"alt": ..., "class": ..., "tooltip": ...} with no "text" field.
# The bar's CustomCommandModule only reads data.text, and dumps the raw JSON
# onto the bar when that field is missing or empty. Remap alt -> text here
# rather than touching the packaged command, and print nothing at all when
# there is no glyph to show, which is what actually hides the module.
omarchy-voxtype-status | python3 -c '
import json, sys
d = json.load(sys.stdin)
text = d.get("alt") or d.get("text") or ""
if not text:
    sys.exit(0)
d["text"] = text
print(json.dumps(d))
'
