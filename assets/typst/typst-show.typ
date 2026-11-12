#import "@preview/orange-book:0.7.1": book, chapter, appendices, part-change
#import "@preview/orange-book:0.7.1": (
  part-state,
  part-location,
  part-counter,
  main-color-state,
  appendix-state,
)

// ===========================================================================
//  Print layout — "Dasar Pemrograman Nim" (id) and "Learning Nim" (en).
//
//  One file for both editions. The direction is DESIGN.md: quiet editorial
//  pages, identity carried by type and hairlines instead of colour or
//  decoration, safe in black-and-white print, no external fonts, no images.
//
//  Trim 178 x 233 mm. The inner margin is wider than the outer one so the
//  binding has room; the folio lives at the foot and nowhere else.
// ===========================================================================

// --- Palette (DESIGN.md) ---------------------------------------------------
#let ink = rgb("#1a1c1f")         // body text
#let ink-soft = rgb("#4a4e55")    // running heads, captions, metadata
#let accent = rgb("#1f3a5f")      // chapter numbers, opening rules, links
#let rule = rgb("#d8d3c6")        // separators; never a block of colour
#let code-paper = rgb("#f4f1ea")  // code panel, one step off the paper
#let panel-fill = rgb("#f1f3f5")  // fill pandoc's syntax highlighter paints

// --- Indent grid (mm) ------------------------------------------------------
// One set of axes for every hanging or inset element, so a chapter number, a
// list marker and a table cell start on the same line from page to page and
// neither drifts when a heading gains a digit or a marker gains a character.
// The values are measured from the edge of the text block; the margins mirror,
// so the numbers hold on both the recto and the verso.
//
//   heading number   16 mm of margin, right-aligned, 4 mm clear of the text
//   list marker       4 mm in, 3 mm wide, so every marker is right-aligned at 7 mm
//   list body         9 mm (indent + marker column + gap) — one hanging indent
//                     for bullets and for numbers alike
//   numbered list    13.5 mm of the text block, shared by the table of
//                     contents and the part / appendix chapter lists
//   box inset         2.8 mm inside every code panel, table cell and callout
#let g-num-col = 16mm       // margin column that holds a hanging heading number
#let g-num-gap = 4mm        // from that number's right edge to the heading text
#let g-list-indent = 4mm    // left edge of the list marker column
#let g-list-mark = 3mm      // marker column width; markers are right-aligned in it
#let g-list-gap = 2mm       // from the marker column to the item body
#let g-list-num-col = 13.5mm // number column of the contents and part lists
#let g-box-inset = 2.8mm    // inner padding shared by panels, tables, callouts

// A hanging heading number. It is drawn in the margin instead of the text
// block, in a fixed-width box that is right-aligned inside the column, so the
// digit count changes the number's left edge and never its right one — a
// heading number therefore keeps one axis through the whole book. The margin
// column is placed as one box of known width, which is what makes the number's
// advance predictable; measuring the number itself is not, because `measure`
// runs before the heading's own text size takes effect and would report a
// narrower number than the one that is drawn.
#let hanging-number(n) = place(
  dx: -(g-num-col + g-num-gap),
  box(width: g-num-col, align(right, text(fill: accent)[#n])),
)

// Marks the page on which a part opening is drawn. The flag is raised before
// the page break and lowered right after it, so the header of the part page
// still reads `true` (the page is evaluated at its own start) while no later
// page inherits it.
#let part-page = state("part-page", false)

// --- Book metadata ---------------------------------------------------------
#let doc-title = [$title$]
#let doc-author = "$for(by-author)$$it.name.literal$$sep$, $endfor$"
#let doc-date-str = "$date$"
#let doc-lang = "$lang$"
// The title is a name and stays English in both editions; the subtitle is
// prose and is set in the edition's own language.
#let doc-subtitle = if doc-lang == "id" {
  [Belajar bahasanya terhadap satu commit tetap]
} else {
  [$subtitle$]
}

// Month names are listed here instead of taken from a locale: Typst ships
// month names for English only, and this book is published in two languages.
#let months-id = (
  "Januari", "Februari", "Maret", "April", "Mei", "Juni",
  "Juli", "Agustus", "September", "Oktober", "November", "Desember",
)
#let months-en = (
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
)

// Numeric-only test spelled out instead of via regex: this file is also a
// Pandoc template, where a lone dollar sign starts a variable.
#let human-date = (value, months) => {
  if value == "" { return "" }
  let parts = value.split("-")
  let numeric = (p) => p.len() > 0 and p.clusters().all(c => c in "0123456789")
  if parts.len() == 3 and parts.all(numeric) {
    str(int(parts.at(2))) + " " + months.at(int(parts.at(1)) - 1) + " " + parts.at(0)
  } else {
    value
  }
}

#let doc-date = human-date(doc-date-str, if doc-lang == "id" { months-id } else { months-en })

// Book version, read from the _variables.yml that tools/gen-version.sh writes
// from VERSION before every render.
#let doc-version = yaml("_variables.yml").at("version", default: "")

#let edition-label = if doc-lang == "id" { "Edisi Bahasa Indonesia" } else { "English edition" }
#let version-word = if doc-lang == "id" { "Versi" } else { "Version" }
#let license-line = if doc-lang == "id" {
  [Teks buku: CC BY-SA 4.0 · Kode contoh: MIT]
} else {
  [Book text: CC BY-SA 4.0 · Code samples: MIT]
}
#let pin-label = if doc-lang == "id" { "Disematkan pada commit" } else { "Pinned at commit" }
#let pin-caption = if doc-lang == "id" {
  [Satu commit tetap, satu toolchain.]
} else {
  [One fixed commit, one toolchain.]
}
#let doc-keywords = if doc-lang == "id" {
  ("Nimony", "Nim 3", "pemrograman", "buku", "bahasa Indonesia")
} else {
  ("Nimony", "Nim 3", "programming", "book", "English")
}

// --- Cover -----------------------------------------------------------------
// The jacket is this book's own, and the device is the book's premise: the pin.
// Forty hairlines stand for the forty hex characters of the commit the book is
// written against; the tick on the last character of the short hash is drawn
// taller in the accent colour, and the hash is set beneath it. Type and
// hairlines only: no image, no second typeface, no field of colour. The
// direction is recorded in DESIGN.md.
#let pin-hash = "4ba90a781b0b22d0821efaa153c129c37cef6143"
#let pin-short = pin-hash.slice(0, 7)
// 40 ticks across the 134 mm measure, each in the middle of its own slot, so
// the strip is evenly spaced without measuring text.
#let pin-step = 3.35mm
#let pin-strip = block(width: 100%, height: 14mm, {
  for i in range(0, pin-hash.len()) {
    let pin = i == pin-short.len() - 1
    place(bottom + left, dx: (i + 0.5) * pin-step, line(
      start: (0mm, 0mm),
      end: (0mm, if pin { -14mm } else { -8mm }),
      stroke: if pin { 0.9pt + accent } else { 0.5pt + rule },
    ))
  }
  // The ticks stand on one hairline, so the strip reads as a measured rule and
  // not as a row of marks floating in the page.
  place(bottom + left, line(length: 100%, stroke: 0.5pt + rule))
})
#let cover-page = block(width: 178mm, height: 233mm, fill: white)[
  #set text(fill: ink)
  // The title block is placed from the head of the jacket: edition furniture,
  // a hairline, the book's name, and the subtitle in the edition's language.
  #place(top + left, block(width: 178mm)[
    #pad(x: 22mm, top: 21mm)[
      #text(size: 8.5pt, tracking: 0.2em, fill: ink-soft)[#upper(edition-label)]
      #v(5mm)
      #line(length: 100%, stroke: 0.5pt + rule)
      #v(12mm)
      #text(size: 28pt, weight: "bold", hyphenate: false)[#doc-title]
      #v(4.5mm)
      #text(size: 11.5pt, style: "italic", fill: ink-soft)[#doc-subtitle]
    ]
  ])
  // The pin strip sits in the middle third. It is measured from the top, so a
  // longer subtitle in one edition cannot shift it.
  #place(top + left, dy: 96mm, block(width: 178mm)[
    #pad(x: 22mm)[
      #text(size: 7.5pt, tracking: 0.28em, fill: ink-soft)[#upper(pin-label)]
      #v(7mm)
      #pin-strip
      #v(4.5mm)
      #text(size: 15pt, tracking: 0.14em)[#pin-short]
      #v(2.5mm)
      #text(size: 9pt, style: "italic", fill: ink-soft)[#pin-caption]
    ]
  ])
  // The foot is a hairline and two lines of type, not a band of colour: the
  // imprint is placed up from the trim so it cannot drift with the copy above.
  #place(bottom + left, block(width: 178mm)[
    #pad(x: 22mm, bottom: 12mm)[
      #line(length: 100%, stroke: 0.5pt + rule)
      #v(5mm)
      #grid(
        columns: (1fr, auto),
        align: (left, right),
        text(size: 12.5pt)[#doc-author],
        text(size: 9pt, fill: ink-soft)[#version-word #doc-version],
      )
      #v(4mm)
      #text(size: 8pt, fill: ink-soft)[#license-line]
    ]
  ])
]

// --- Inner title page ------------------------------------------------------
// The second page carries its own imprint only: the date of the edition at the
// foot. The version and the two licences are printed once, on the cover, and
// the full colophon is the manuscript's copyright page
// (books/*/copyright.qmd); nothing here repeats them.
#let front-page = [
  #place(top + center, block(width: 100%)[
    #v(42mm)
    #set align(center)
    #text(size: 9pt, tracking: 0.16em, fill: ink-soft)[#upper(edition-label)]
    #v(6mm)
    #text(size: 22pt, weight: "bold")[#doc-title]
    #v(2mm)
    #line(length: 48mm, stroke: 1.2pt + accent)
    #v(5mm)
    #text(size: 12pt, style: "italic", fill: ink-soft)[#doc-subtitle]
    #v(10mm)
    #text(size: 12pt)[#doc-author]
  ])
  // Quiet title-page furniture, one line, as a printed book has at the foot.
  #place(bottom + center, pad(bottom: 32mm,
    text(size: 9pt, tracking: 0.08em, fill: ink-soft)[#doc-date],
  ))
]


// ---------------------------------------------------------------------------
// Table of contents
//
// Orange-book builds its outline inside `book`, and the tinted panel it puts
// around the title and the roman numeral it puts beside each part are drawn
// there, before any show rule declared after the book call can reach them. A
// rule placed *before* the call is part of the style chain the outline is
// realised in, so the whole outline is redrawn here instead.
//
// What replaces it: a quiet title, a small label for each part (no roman
// numeral, because the part titles already read "Bagian 0" to "Bagian C"), and
// chapter and section rows with dot leaders and a folio. The rule answers only
// for the main table of contents; the two list outlines orange-book also emits
// (figures, tables) have no depth and are left alone.
// ---------------------------------------------------------------------------
#let toc-title = if doc-lang == "id" { "Daftar Isi" } else { "Contents" }

#let toc-row(hn) = {
  let loc = hn.location()
  let appendix = appendix-state.at(loc) != none
  let numbers = counter(heading).at(loc)
  let numbered = hn.numbering != none and numbers.len() > 0
  let num = if not numbered { none } else if hn.level == 1 {
    numbering(if appendix { "A" } else { "1" }, numbers.first())
  } else {
    numbering(
      if appendix { "A.1" } else { "1.1" },
      ..numbers.slice(0, calc.min(2, numbers.len())),
    )
  }
  link(loc, grid(
    columns: (g-list-num-col, 1fr, auto),
    align: (left + horizon, left + horizon, right + horizon),
    text(size: 10pt, weight: "bold", fill: accent)[#if numbered [#num]],
    text(size: 10pt, weight: if numbered { "bold" } else { "regular" })[
      #hn.body #box(width: 1fr, repeat(text(fill: rule)[. #h(3pt)]))
    ],
    text(size: 10pt)[#hn.location().page()],
  ))
}

#show outline: it => {
  // The two list outlines orange-book also emits (figures, tables) carry no
  // depth; only the main table of contents is redrawn here.
  if it.depth == none or it.depth == auto { return none }
  let depth = it.depth
  context {
    // The package used to open this page with a break of its own, because the
    // outline's title was a level-1 heading it styled. The title is ours now,
    // so the break is ours too. It is not a break "to odd": that is what left
    // blank pages in front of every part.
    pagebreak()
    v(15mm)
    text(size: 23pt, weight: "bold", hyphenate: false)[#toc-title]
    v(5mm)
    line(length: 100%, stroke: 0.5pt + rule)
    v(8mm)
    let divider-word = if doc-lang == "id" { "Lampiran" } else { "Appendices" }
    // A part bar and the chapters under it are one unit. Left to break freely,
    // the bar ends up at the foot of a page with two rows after it, or the rows
    // carry on under a bar that stayed behind. A part with more chapters than a
    // page holds cannot be kept whole, so those groups stay breakable.
    let groups = ()
    let group = ()
    for hn in query(heading) {
      // `and` does not short-circuit in Typst, so the tests are separate.
      if hn.level == none or not hn.outlined { continue }
      if hn.level > depth { continue }
      if part-change.at(hn.location()) and group.len() > 0 {
        groups.push(group)
        group = ()
      }
      group.push(hn)
    }
    if group.len() > 0 { groups.push(group) }
    for group in groups {
      block({
        let head = group.first().location()
        if part-change.at(head) [
          #v(1.1em)
          #line(length: 100%, stroke: 0.4pt + rule)
          #v(0.35em)
          #text(size: 8.5pt, tracking: 0.12em, fill: ink-soft)[#upper(part-state.at(head))]
          #v(0.45em)
        ]
        for hn in group {
          // The divider page announces the appendices with the bar above;
          // listing its own heading would repeat the same word one line lower.
          if hn.numbering == none and hn.body.has("text") and hn.body.text == divider-word { continue }
          if hn.level == 1 { toc-row(hn) } else { pad(left: 5mm, toc-row(hn)) }
          v(0.4em)
        }
      }, breakable: group.len() > 25)
    }
  }
}

// ---------------------------------------------------------------------------
// Chapter opening
//
// Orange-book draws the title in a panel three centimetres wider than the text
// block, so long chapter titles run off the trim. This draws the shape DESIGN.md
// asks for instead: a small label, the title, and one hairline.
//
// The break is weak on purpose: a chapter starts on the next page, but no
// empty page is inserted to push it onto an odd one. That is where the blank
// pages came from.
// ---------------------------------------------------------------------------
#let chapter-opening(it, break-page: false) = {
  if break-page { pagebreak(weak: true) }
  part-change.update(x => false)
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(math.equation).update(0)
  block(above: 0pt, below: 0pt)[
    #v(14mm)
    #if it.numbering != none [
      #context {
        let n = str(counter(heading).display(it.numbering)).trim(".").trim()
        let word = if appendix-state.at(here()) != none {
          if doc-lang == "id" { "Lampiran" } else { "Appendix" }
        } else if doc-lang == "id" { "Bab" } else { "Chapter" }
        text(size: 8.5pt, tracking: 0.16em, fill: ink-soft)[#upper(word) #n]
      }
      #v(3.5mm)
    ]
    #text(size: 23pt, weight: "bold", hyphenate: false)[#it.body]
    #v(5mm)
    #block(width: 100%, line(length: 100%, stroke: 0.5pt + rule))
    #v(7mm)
  ]
}

// Page numbering is drawn by the footer rule below, not by Quarto: the cover
// and the front matter carry no folio. This must be set before the book is
// built, because its own pages are created inside `book` and would otherwise
// already carry a number.
#set text(fill: ink)

#set page(numbering: none)

// Page geometry in one place. The code panel rule further down asks whether a
// listing fits on a page before it decides whether the listing may break, and
// that answer has to use the same numbers the page itself was set with.
#let page-w = 178mm
#let page-h = 233mm
#let m-top = 21mm
#let m-bottom = 25mm
#let text-height = page-h - m-top - m-bottom

#show: book.with(
  width: page-w,
  height: page-h,
  // Equal margins on both sides. There is no print edition, so a mirrored gutter
  // buys nothing and costs 5 mm of shift between one page and the next, which is
  // exactly what "the indentation is not uniform" looks like. The measure stays
  // 119 mm either way, so nothing reflows; the top is tight so the running head
  // sits close to the text block.
  margin: (left: 29.5mm, right: 29.5mm, top: m-top, bottom: m-bottom),
  font-size: 11pt,
  // Space between paragraphs, no first-line indent (DESIGN.md): with an indent
  // and this spacing together the start of a paragraph becomes ambiguous.
  first-line-indent: false,
  // The cover and the inner title page are drawn in full above, so the
  // built-in title block stays empty (and invisible).
  title: "",
  subtitle: "",
  author: "",
  date: "$date$",
  lang: "$lang$",
  main-color: accent,
  logo: {
    let logo-info = brand-logo.at("medium", default: none)
    if logo-info != none { image(logo-info.path, alt: logo-info.at("alt", default: none)) }
  },
$if(toc-depth)$
  outline-depth: $toc-depth$,
$endif$
$if(quarto.language.crossref-ch-prefix)$
  supplement-chapter: "$quarto.language.crossref-ch-prefix$",
$endif$
  // Part openings are drawn by the rule below, not by orange-book: its default
  // fills the page with a tinted field, which conflicts with the black-and-white
  // brief in DESIGN.md. Only the chapter list from the package is kept.
  part-font-size: 6em,
  outline-small-depth: 1,
  cover-background: rgb(0, 0, 0, 0),
  cover: cover-page,
  copyright: front-page,
)

// ---------------------------------------------------------------------------
// Chapter opening
//
// Orange-book draws the title in a panel three centimetres wider than the text
// block, so long chapter titles run off the trim. This replaces it with the
// shape DESIGN.md asks for: a small chapter label, the title, and one hairline.
// The heading element itself stays in place, so the outline and the running
// head keep working.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Appendix divider
//
// Quarto opens the appendices with an unnumbered level-1 heading. It is the
// same page as a part opening, so it lists what follows: the four appendices
// with their letters and pages, instead of a bare word on an empty page.
// ---------------------------------------------------------------------------
#let appendix-divider(it) = {
  pagebreak(weak: true)
  part-change.update(x => true)
  // The divider starts a new group in the table of contents; without this the
  // bar would still carry the last chapter part's title.
  part-state.update(x => it.body)
  [
    #context {
      set par(justify: false)
      v(34mm)
      text(size: 24pt, weight: "bold", hyphenate: false)[#it.body]
      v(5mm)
      line(length: 100%, stroke: 0.5pt + rule)
      v(10mm)
      let items = query(heading.where(level: 1)).filter(hn =>
        hn.numbering != none and appendix-state.at(hn.location()) != none)
      for hn in items {
        let num = numbering("A", counter(heading).at(hn.location()).first())
        link(hn.location(), grid(
          columns: (g-list-num-col, 1fr, auto),
          align: (left + horizon, left + horizon, right + horizon),
          text(size: 9.5pt, fill: accent, weight: "bold")[#num],
          text(size: 9.5pt)[#hn.body #box(width: 1fr, repeat(text(size: 9.5pt, fill: rule)[. #h(3pt)]))],
          text(size: 9.5pt)[#hn.location().page()],
        ))
        v(3mm)
      }
    }
  ]
}

#show heading.where(level: 1): it => {
  // The appendix divider carries no number and no chapter furniture.
  let divider-word = if doc-lang == "id" { "Lampiran" } else { "Appendices" }
  if it.numbering == none and it.body.has("text") and it.body.text == divider-word {
    appendix-divider(it)
  } else {
    chapter-opening(it, break-page: true)
  }
}

// ---------------------------------------------------------------------------
// Part opening
//
// A quiet page: the part title, a hairline, and the chapters it contains.
// No colour field, no roman numeral (the titles already carry "Bagian 0" to
// "Bagian C", so a second number would only contradict them).
// ---------------------------------------------------------------------------
#let part(title) = {
  part-page.update(x => true)
  pagebreak(weak: true)
  part-page.update(x => false)
  part-change.update(x => true)
  part-state.update(x => title)
  part-counter.step()
  [
    #context {
      let her = here()
      part-location.update(x => her)
    }
    #context {
      set par(justify: false)
      v(34mm)
      text(size: 24pt, weight: "bold", hyphenate: false)[#part-state.get()]
      v(5mm)
      line(length: 100%, stroke: 0.5pt + rule)
      v(10mm)
      let chapters = query(heading.where(level: 1)).filter(it =>
        it.numbering != none
          and appendix-state.at(it.location()) == none
          and part-state.at(it.location()) == title)
      for hn in chapters {
        let raw = numbering(hn.numbering, ..counter(heading).at(hn.location()))
        let num = if raw.ends-with(".") { raw.slice(0, -1) } else { raw }
        link(hn.location(), grid(
          columns: (g-list-num-col, 1fr, auto),
          align: (left + horizon, left + horizon, right + horizon),
          text(size: 9.5pt, fill: accent, weight: "bold")[#num],
          text(size: 9.5pt)[#hn.body #box(width: 1fr, repeat(text(size: 9.5pt, fill: rule)[. #h(3pt)]))],
          text(size: 9.5pt)[#hn.location().page()],
        ))
        v(3mm)
      }
    }
  ]
}

// ---------------------------------------------------------------------------
// Running head and folio
//
// One number per page, at the foot. Orange-book also prints a number inside
// the header, so the header is rebuilt here to carry the running head alone:
// the book title on the left-hand pages, the chapter title on the right-hand
// ones. A chapter opening carries neither.
// ---------------------------------------------------------------------------
#set page(header: context {
  let pn = counter(page).at(here()).first()
  // Part openings carry the field and the numeral; no running head on top.
  // The state is read at the page number rather than at `here()`: the part is
  // drawn after the page has started, so the update lands inside the page.
  if part-page.at(here()) { return }
  let openers = query(heading.where(level: 1))
  // A chapter that starts on this page needs no running head.
  if openers.any(it => it.location().page() == pn) { return }
  // Running heads belong to the numbered main matter: front matter and the
  // table of contents come before the first numbered chapter.
  let numbered = openers.filter(it => it.numbering != none and it.location().page() < pn)
  if numbered.len() == 0 { return }
  let recto = calc.odd(pn)
  let label = if recto { numbered.last().body } else { doc-title }
  set text(size: 8.5pt, fill: ink-soft)
  block(
    width: 100%,
    inset: (bottom: 4pt),
    stroke: (bottom: 0.4pt + rule),
    align(if recto { right } else { left }, label),
  )
})

// ---------------------------------------------------------------------------
// Folio
//
// Quarto prints the page number with `numbering`, which also puts it on the
// cover, the title page, and the table of contents. The number is drawn here
// instead, so it starts with the first numbered chapter and appears nowhere
// else. Part openings and chapter openings keep their folio; only the front
// matter loses it.
// ---------------------------------------------------------------------------
#set page(
  numbering: none,
  footer: context {
    let pn = counter(page).at(here()).first()
    // Front matter carries no folio at all, and the first number appears on the
    // first chapter: the table of contents is drawn inside the book block and
    // never reaches this rule, so a fixed page number would be a guess.
    let openers = query(heading.where(level: 1)).filter(it => it.numbering != none)
    if openers.len() == 0 { return }
    if pn < openers.first().location().page() { return }
    set text(size: 8.5pt, fill: ink-soft)
    // Margins are symmetrical (29.5mm on both sides), so the folio sits
    // directly on the center axis through the book without shift.
    place(center + horizon, numbering("1", pn))
  },
)
//
// Ragged right on purpose: justified text at this measure would open rivers
// of space (DESIGN.md). Typst ships no hyphenation patterns for Indonesian —
// 0 soft hyphens in 408 pages, against 9 in the English edition — so keeping
// `hyphenate` on buys the Indonesian edition nothing and the ragged edge has to
// be carried by the breaker instead.
// ---------------------------------------------------------------------------
#show par: set par(
  justify: false,
  // Typst's default breaker is greedy: it fills each line and leaves whatever
  // is left for the last one. "optimized" weighs the paragraph as a whole, which
  // pulls one- and two-word closing lines back into the line above. Measured on
  // this book: widows fell from 9 to 1 in ID and from 8 to 0 in EN, with the page
  // count unchanged (408 / 401) and the panel splits unchanged (2 / 4).
  linebreaks: "optimized",
  leading: 0.75em,
  // DESIGN.md, "PDF": 1.3 em between paragraphs, with no first-line indent.
  spacing: 1.3em,
  first-line-indent: 0pt,
)

// A list item's body hangs under the first line instead of under the marker, so
// a wrapped item stays readable at 10pt in a 119 mm measure. Every marker is
// right-aligned in the same 3 mm column — a bullet, "1." and "10." all end on
// one axis, and the body of a bulleted item starts where the body of a numbered
// one does. The marker column is fixed, so it does not grow when a list reaches
// a second digit.
#show list: set list(
  indent: g-list-indent,
  body-indent: g-list-gap,
  spacing: 0.4em,
  marker: box(width: g-list-mark, align(right, [•])),
)
#show enum: set enum(
  indent: g-list-indent,
  body-indent: g-list-gap,
  spacing: 0.4em,
  numbering: n => box(width: g-list-mark, align(right, numbering("1.", n))),
)

// ---------------------------------------------------------------------------
// Headings, levels 2 to 4
//
// Level 1 is the chapter opening, drawn above. Levels 2 to 4 share
// one shape: a bold title with the number hanging in the margin, in the
// accent colour. `sticky` keeps a heading with the text it introduces.
// ---------------------------------------------------------------------------
#show heading.where(level: 2): it => {
  set text(size: 1.32em, weight: "bold")
  let number = if it.numbering != none {
    hanging-number(counter(heading).display(it.numbering))
  }
  block(above: 1.7em, below: 0.6em, sticky: true, number + it.body)
}

#show heading.where(level: 3): it => {
  set text(size: 1.15em, weight: "bold")
  let number = if it.numbering != none {
    hanging-number(counter(heading).display(it.numbering))
  }
  block(above: 1.4em, below: 0.5em, sticky: true, number + it.body)
}

#show heading.where(level: 4): it => {
  set text(size: 1.02em, weight: "bold")
  let number = if it.numbering != none {
    hanging-number(counter(heading).display(it.numbering))
  }
  block(above: 1.2em, below: 0.4em, sticky: true, number + it.body)
}

// ---------------------------------------------------------------------------
// Code
//
// Every fenced listing arrives through pandoc's `Skylighting`, which is a
// plain `block` filled with #f1f3f5 — not a block-level `raw`, so the obvious
// `show raw.where(block: true)` rule would never fire. The panel is caught
// here by its fill and redrawn as a warm near-white sheet with a hairline
// border: it survives a black-and-white printer without turning into a grey
// slab, and it never becomes the darkest element on the page. One size for
// every panel — a book does not resize its code from page to page — and long
// lines wrap at spaces, so a listing stays inside the measure and stays
// breakable. Inline code keeps Typst's own 0.8 em, which matches the serif at
// this size.
// ---------------------------------------------------------------------------
#let code-size = 9pt
#let panel-inset-y = 7pt
#let panel-keep = 220pt
// `raw` prints at 0.8 em of the text around it, so the ambient size is raised
// until the token glyphs themselves land on `code-size`.
#let code-panel-size = code-size * 1.25

#show block: it => {
  if it.fill == panel-fill {
    let body = text(size: code-panel-size, fill: rgb("#003b4f"), it.body)
    context {
      // A listing up to about twenty lines is never split: it stands where it is
      // or moves whole to the next page, so a sample cannot turn into a stray line
      // at the top of a page. Longer listings stay breakable, because holding them
      // whole would leave most of a page empty. The limit is a height rather than a
      // line count, because a long line wraps.
      let utuh = measure(body).height + 2 * panel-inset-y <= panel-keep
      block(
        fill: code-paper,
        stroke: 0.4pt + rule,
        radius: 2pt,
        inset: (x: g-box-inset, y: panel-inset-y),
        above: 0.85em,
        below: 0.85em,
        width: 100%,
        breakable: not utuh,
        body,
      )
    }
  } else {
    it
  }
}

// ---------------------------------------------------------------------------
// Code lines that do not fit
//
// Typst breaks an overlong word at an arbitrary character when it fills a code
// line, so a URL, a path or a checksum can split mid-token and a copied command
// stops being the command the book teaches. Each source line is one raw after
// `NormalTok` is reduced to its text; when that line carries a token of forty
// characters or more, the line is set smaller until it fits the measure as one
// line. Lines made only of short words keep the normal size and wrap at spaces,
// which is what a line of console output should do.
//
// All fenced blocks in this book are language-less, so NormalTok is the only
// highlighting token they use. A language-tagged block added later would come
// through the other token functions; its lines are left to wrap.
// ---------------------------------------------------------------------------
#let NormalTok(s) = raw(s)

#let Skylighting(fill: none, number: false, start: 1, sourcelines) = context {
  let blocks = []
  let lnum = start - 1
  let bgcolor = rgb("#f1f3f5")
  let measure-width = 119mm - 2 * g-box-inset
  for ln in sourcelines {
    if number {
      lnum = lnum + 1
      blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
    }
    let text-of-line = if ln.func() == raw { ln.text } else { "" }
    let factor = 1.0
    if text-of-line != "" {
      let longest = 0
      for word in text-of-line.split(" ") {
        if word.len() > longest { longest = word.len() }
      }
      if longest >= 40 {
        let natural = measure(text(size: code-panel-size, ln)).width
        if natural > measure-width {
          factor = calc.max(0.7, measure-width / natural)
        }
      }
    }
    blocks = blocks + text(size: code-panel-size * factor, ln) + EndLine()
  }
  block(fill: bgcolor, width: 100%, inset: 8pt, radius: 2pt, blocks)
}

// ---------------------------------------------------------------------------
// Tables
//
// Horizontal rules only, no zebra striping (DESIGN.md). The header row is
// bold and keeps its rule; cells get enough padding to breathe, and a wide
// table is allowed to break across pages rather than run off the trim.
// ---------------------------------------------------------------------------
#set table(inset: (x: g-box-inset, y: 5pt), stroke: none, align: left)
#set table.hline(stroke: 0.5pt + rule)
// Header rows repeat on every page a long table spans (Typst's default), so a
// reader who meets the glossary mid-table still knows the three columns.
// Cells are set one step below the body: a table is secondary matter, and the
// narrower size is also what keeps a long inline sample
// ("db.getAllRows(sql\"...\")") inside a narrow column instead of past the trim.
#show table: set text(size: 10pt)
#show table.header: set text(weight: "bold")
// Table cells are ragged right: justified cells open rivers in narrow columns.
#show table: set par(justify: false)
// A checksum or another long inline sample cannot break inside a cell. The
// tables that carry one are given a wide value column by tools/fix-tables.py,
// and the long span itself is set smaller so the whole token fits on one line
// instead of crossing the trim. Shorter spans keep the table's normal size.
#show table: it => {
  show raw: it => {
    if it.text.len() >= 48 { text(size: 6.2pt, it) } else { it }
  }
  it
}

// ---------------------------------------------------------------------------
// Footnotes
// ---------------------------------------------------------------------------
#set footnote(numbering: "1")
#show footnote: set text(size: 0.85em)

// ---------------------------------------------------------------------------
// PDF metadata
//
// The title page passes empty strings to orange-book, so the real metadata is
// set here: title, author, subject, and keywords.
// ---------------------------------------------------------------------------
#set document(
  title: doc-title,
  author: doc-author,
  description: doc-subtitle,
  keywords: doc-keywords,
)

// ---------------------------------------------------------------------------
// Callouts and links
//
// Quarto draws callouts with the palette of the HTML theme (a bright blue box),
// and links inherit Typst's default blue. Both would be the only colour on the
// page, so they are redrawn with the book palette: a paper-toned box, a rule on
// the binding side, and links in the accent colour.
// ---------------------------------------------------------------------------
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false,
    fill: code-paper,
    stroke: (left: 2pt + accent, rest: 0.4pt + rule),
    width: 100%,
    radius: 1pt,
    inset: (x: g-box-inset, y: 8pt),
    // The icon argument is accepted and ignored: DESIGN.md allows no
    // decorative glyphs, and the FontAwesome font is not embedded.
    block(below: 4pt, text(size: 0.95em, weight: "bold")[#title]) + block(above: 2pt, body),
  )
}

#show link: set text(fill: accent)
