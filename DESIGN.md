# Design direction — *Nimony: A Pinned Guide*

This book is the second volume in the series *Learning Nim* opened, so it keeps that volume's language and
not its jacket: the palette stays `#1a1c1f` for body text, `#4a4e55` for metadata, `#1f3a5f` for the accent
and `#d8d3c6` for hairlines; one serif family, no second typeface; identity carried by type and hairlines,
never by an image or a field of colour; black ink on white paper, so every page survives a one-colour press;
and the same 178 × 233 mm trim. Its own device is the pin: the cover draws one hairline per character of the
commit the book is written against — forty ticks — with the tick on the last character of the short hash
drawn taller in the accent colour and `4ba90a7` set beneath it, so the jacket states the book's premise, that
every example runs at one fixed commit and the toolchain does not move. The main title stays
`Nimony: A Pinned Guide` in both editions; the subtitle and the edition furniture are in the edition's own
language.

## Type

- One family, the serif the template already embeds. No new font, no image asset, no icon glyph.
- Cover: edition label, hairline, title, subtitle. Chapter opening: label, title, hairline.
- Part openings and appendices: title, hairline, the chapter list. No colour field, no numeral.
- Body ragged right, no first-line indent, 1.3 em between paragraphs.
- Headings 2–4 bold, with the number hanging in the margin in the accent colour.
- Tables: horizontal rules only, never zebra striping or a filled header.

## Ink

- The accent is a dark blue that prints as a mid grey; hairlines are `#d8d3c6`, never a block of colour.
- Code panels are a warm near-white sheet with a hairline border, never a grey slab.
- Nothing is set as an image: `pdfimages -list` stays empty for both editions.
- Nothing crosses the trim: the cover's furniture is placed from the edges, not flowed, so wording can
  change without pushing a line off the paper.
