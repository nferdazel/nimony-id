#!/usr/bin/env python3
"""Fail when the book that was just built and the latest release are not the
same book.

Both sides are read the same way: the table of contents of the PDF, one row per
numbered chapter ("1    Apa Itu Nimony . . . 5", or "2    1. What Nimony Is
. . . 5" from a build that still numbered the chapter inside the title).
Comparing the PDFs and not the sources is the point — the reader compares the
file on the release page with the page the site serves, so the check has to read
what they read. The two editions are translations, so their titles differ by
design: an edition is compared to the release of the same edition by title, and
the two editions are compared to each other by which chapters they carry.

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

# A contents row: a row number in the left column, a title, the dot leader, the
# folio. Two layouts are in the wild and both have to be read. Quarto numbers
# nothing in that column and prints the chapter number as part of the title
# ("2    1. What Nimony Is . . . 5"), and that column counter also counts the
# front matter, so it is not the chapter number. Since the chapter headings
# were localized the counter is gone and the column carries the chapter number
# itself ("1    Apa Itu Nimony . . . 5"). The dot leader and the folio are
# required in both, so body text never matches.
ROW = re.compile(r"^\s*(\d{1,2})\s+(?:(\d{1,2})\.\s+)?(\S.*?)\s+(?:\.\s+){2,}\d+\s*$")


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

    rows = []
    for line in proc.stdout.splitlines():
        match = ROW.match(line)
        if not match:
            continue
        rows.append(
            (
                int(match.group(1)),
                int(match.group(2)) if match.group(2) else None,
                " ".join(match.group(3).split()),
            )
        )

    # One layout per PDF, decided from the rows themselves: if any row carries
    # its chapter number inline, this is the old Quarto layout and the left
    # column is only a counter that also counts the front matter, so the rows
    # without an inline number are not chapters. Otherwise the left column is
    # the chapter number.
    if any(inline is not None for _, inline, _ in rows):
        entries = [(inline, title) for _, inline, title in rows if inline is not None]
    else:
        entries = [(column, title) for column, _, title in rows]

    found = {}
    for number, title in entries:
        # The contents page comes before every other dotted row, so the first
        # reading of a number is the one the reader sees in the contents.
        if number in found:
            continue
        found[number] = title

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


def compare_editions(left_label, left, right_label, right):
    """The editions are translations: their titles are different words on
    purpose. What must hold is that they tell the same book, chapter by
    chapter — the same numbers in the same order, no chapter in one edition
    only."""
    left_numbers = [number for number, _ in left]
    right_numbers = [number for number, _ in right]
    if left_numbers == right_numbers:
        print(f"  ok  {left_label} and {right_label} carry the same {len(left)} chapters")
        return True
    print(f"  FAIL {left_label} lists different chapters than {right_label}", file=sys.stderr)
    for number in sorted(set(left_numbers) ^ set(right_numbers)):
        side = left_label if number in set(left_numbers) else right_label
        print(f"       chapter {number}: only in {side}", file=sys.stderr)
    unusual = [
        number
        for number in sorted(set(left_numbers) & set(right_numbers))
        if left_numbers.index(number) != right_numbers.index(number)
    ]
    for number in unusual:
        print(f"       chapter {number} is in a different position", file=sys.stderr)
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
    ok &= compare_editions("built id", built_id, "built en", built_en)
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
