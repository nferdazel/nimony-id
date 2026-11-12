#!/usr/bin/env python3
"""Widen the column that carries an unbreakable long token.

Pandoc turns a pipe table's separator line into percentage column widths, so the
chapter 2 table hands half the measure to a 64-character sha256 and the token
runs past the trim. This script rewrites the separator line of any staged table
that carries a token of 48 characters or more, weighting every column by its
longest token. The chapter sources are never touched: build-site.sh runs this
over .build/<lang>/chapters after staging.

The matching typst rule (assets/typst/typst-show.typ) sets those long spans a
little smaller, because even a full-width column cannot hold the checksum at the
normal inline size.
"""

import pathlib
import re
import sys

SEPARATOR = re.compile(r"^\s*\|[\s:|-]+\|\s*$")
LONG_TOKEN = 48


def cells(line):
    return [cell for cell in line.strip().strip("|").split("|")]


def longest_token(cell):
    return max((len(token.strip("`")) for token in cell.split()), default=0)


def column_weights(rows):
    widths = [20] * len(cells(rows[0]))
    for row in rows:
        for index, cell in enumerate(cells(row)[: len(widths)]):
            widths[index] = max(widths[index], longest_token(cell) + 4)
    return widths


def rebuild_separator(separator, weights):
    out = []
    for index, cell in enumerate(cells(separator)):
        left = cell.startswith(":")
        right = cell.endswith(":")
        width = weights[index] if index < len(weights) else 20
        out.append((":" if left else "") + "-" * max(width, 3) + (":" if right else ""))
    return "|" + "|".join(out) + "|"


def fix_file(path):
    lines = path.read_text().splitlines()
    changed = 0
    index = 0
    while index < len(lines):
        if not lines[index].startswith("|"):
            index += 1
            continue
        end = index
        while end < len(lines) and lines[end].startswith("|"):
            end += 1
        block = lines[index:end]
        if len(block) >= 3 and SEPARATOR.match(block[1]):
            rows = [block[0]] + block[2:]
            if max(longest_token(cell) for row in rows for cell in cells(row)) >= LONG_TOKEN:
                weights = column_weights(rows)
                block[1] = rebuild_separator(block[1], weights)
                lines[index:end] = block
                changed += 1
        index = end
    if changed:
        path.write_text("\n".join(lines) + "\n")
    return changed


def main():
    total = 0
    for arg in sys.argv[1:]:
        for path in sorted(pathlib.Path(arg).rglob("*.md")):
            total += fix_file(path)
    print(f"fix-tables: widened {total} table(s) with a long token")
    return 0


if __name__ == "__main__":
    sys.exit(main())
