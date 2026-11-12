#!/usr/bin/env python3
"""Remove the editorial freeze record from the staged chapter copies.

The dated checklist line is the process's record and stays in the chapter
source, but it is not reader content: it must not become a heading, a table of
contents entry, or a nearly empty PDF page. build-site.sh stages every chapter
into .build/<lang>/chapters before rendering; this script edits those copies
only, so the sources keep the record untouched.

Two forms exist in the chapters:

    ## Checklist chapter          (or ## Chapter checklist)
    <blank>
    draft ... · tech_review ... · editorial_pass ... · frozen ...

and chapter 1's bare form, after the closing horizontal rule:

    ---
    <blank>
    `draft ... · tech_review ... · editorial_pass ... · frozen ...`
"""

import pathlib
import re
import sys

STATUS = re.compile(
    r"^`?draft \d{4}-\d{2}-\d{2} · tech_review .+ · "
    r"editorial_pass \d{4}-\d{2}-\d{2} · frozen \d{4}-\d{2}-\d{2}`?$"
)
HEADING = re.compile(r"^#{1,6} (Checklist chapter|Chapter checklist)$")


def strip_record(text):
    lines = text.splitlines()
    while lines and not lines[-1].strip():
        lines.pop()
    if not lines or not STATUS.match(lines[-1].strip()):
        return text, False
    lines.pop()
    while lines and not lines[-1].strip():
        lines.pop()
    if lines and HEADING.match(lines[-1].strip()):
        lines.pop()
        while lines and not lines[-1].strip():
            lines.pop()
    # Chapter 1's closing rule separated the prose from the record; with the
    # record gone the rule has nothing left to close.
    if lines and lines[-1].strip() == "---":
        lines.pop()
        while lines and not lines[-1].strip():
            lines.pop()
    return "\n".join(lines) + "\n", True


def main():
    changed = 0
    left = 0
    for arg in sys.argv[1:]:
        for path in sorted(pathlib.Path(arg).rglob("*.md")):
            text = path.read_text()
            new, hit = strip_record(text)
            if hit:
                path.write_text(new)
                changed += 1
            for line in path.read_text().splitlines():
                if STATUS.match(line.strip()) or HEADING.match(line.strip()):
                    left += 1
    if left:
        print(f"strip-status: {left} freeze records still in staged copies", file=sys.stderr)
        return 1
    print(f"strip-status: removed {changed} freeze records from staged copies")
    return 0


if __name__ == "__main__":
    sys.exit(main())
