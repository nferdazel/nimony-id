#!/usr/bin/env python3
"""Fail when the book that was just built and the latest release are not the
same book.

Both sides are read the same way: the table of contents of the PDF, one row per
numbered chapter ("2    1. What Nimony Is . . . 5"). Comparing the PDFs and not
the sources is the point — the reader compares the file on the release page
with the page the site serves, so the check has to read what they read.

usage:
  tools/check-parity.py --built-id PUBLIC/Nimony-A-Pinned-Guide.pdf \
                        --built-en PUBLIC/en/Nimony-A-Pinned-Guide.pdf \
                        --release-id RELEASE/Nimony-A-Pinned-Guide-ID.pdf \
                        --release-en RELEASE/Nimony-A-Pinned-Guide-EN.pdf

Exit 0 when both editions list the same chapters as the release and the two
editions list the same chapters as each other; exit 1 with the diff otherwise;
exit 2 when a PDF cannot be read or parsed, which is a broken check and never a
reason to cut a release.
"""
import argparse
import re
import subprocess
import sys

# A contents row: the row's own number, the chapter number and title, the dot
# leader, the folio. Body text and the part-opening lists carry no "N." after
# the row number, so they do not match.
ROW = re.compile(r"^\s*\d+\s+(\d{1,2})\.\s+(.*?)\s+(?:\.\s+){2,}\d+\s*$")


def die(message):
    """A check that cannot read its input is broken, not a mismatch: exit 2."""
    print(message, file=sys.stderr)
    sys.exit(2)


def chapters(pdf):
    try:
        proc = subprocess.run(
            ["pdftotext", "-layout", pdf, "-"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        die("pdftotext not found; install poppler-utils")
    except subprocess.CalledProcessError as exc:
        die(f"cannot read {pdf}: {exc.stderr.strip()}")

    found = {}
    for line in proc.stdout.splitlines():
        match = ROW.match(line)
        if not match:
            continue
        number = int(match.group(1))
        # The contents page comes before every other dotted row, so the first
        # reading of a number is the one the reader sees in the contents.
        if number in found:
            continue
        found[number] = " ".join(match.group(2).split())

    if not found:
        die(f"no chapter rows found in {pdf}")
    highest = max(found)
    if sorted(found) != list(range(1, highest + 1)):
        die(f"chapter numbers in {pdf} are not 1..{highest}: {sorted(found)}")
    return [(number, found[number]) for number in sorted(found)]


def compare(left_label, left, right_label, right):
    if [number for number, _ in left] == [number for number, _ in right] and left == right:
        print(f"  ok  {left_label} == {right_label} ({len(left)} chapters)")
        return True
    print(f"  FAIL {left_label} != {right_label}", file=sys.stderr)
    print(f"       {left_label}: {len(left)} chapters", file=sys.stderr)
    print(f"       {right_label}: {len(right)} chapters", file=sys.stderr)
    for number in sorted({n for n, _ in left} | {n for n, _ in right}):
        a = dict(left).get(number)
        b = dict(right).get(number)
        if a != b:
            print(f"       {number}: built {a!r} / release {b!r}", file=sys.stderr)
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    for side in ("built-id", "built-en", "release-id", "release-en"):
        parser.add_argument(f"--{side}", required=True, help=f"{side} PDF")
    args = parser.parse_args()

    built_id = chapters(args.built_id)
    built_en = chapters(args.built_en)
    release_id = chapters(args.release_id)
    release_en = chapters(args.release_en)

    print(f"built:   id {len(built_id)} chapters, en {len(built_en)} chapters")
    print(f"release: id {len(release_id)} chapters, en {len(release_en)} chapters")

    ok = True
    ok &= compare("built id", built_id, "release id", release_id)
    ok &= compare("built en", built_en, "release en", release_en)
    ok &= compare("built id", built_id, "built en", built_en)
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
