#!/usr/bin/env python3
"""Move the skip link to the start of <body>.

Quarto's `include-before-body` injects the anchor inside <main>, which is *after* the sidebar:
it becomes the 59th focusable element instead of the first, so it saves nobody any keystrokes.
This moves it up and makes <main> focusable, so following the link really moves focus.

Idempotent: pages that already have `tabindex="-1"` on <main> are left alone.
"""
import pathlib
import re

ANCHOR = re.compile(r'<a class="quarto-skip-link"[^>]*>[^<]*</a>\s*')
BODY = re.compile(r"<body[^>]*>")
MAIN = re.compile(r'<main[^>]*id="quarto-document-content"[^>]*>')

moved = 0
for path in sorted(pathlib.Path("public").rglob("*.html")):
    text = path.read_text(encoding="utf-8")
    anchor = ANCHOR.search(text)
    body = BODY.search(text)
    if not anchor or not body:
        continue

    text = text[: anchor.start()] + text[anchor.end():]
    body = BODY.search(text)
    text = text[: body.end()] + anchor.group(0).strip() + text[body.end():]

    text = MAIN.sub(lambda m: m.group(0) if 'tabindex' in m.group(0)
                    else m.group(0)[:-1] + ' tabindex="-1">', text, count=1)

    path.write_text(text, encoding="utf-8")
    moved += 1

print(f"skip-link: {moved} halaman")
