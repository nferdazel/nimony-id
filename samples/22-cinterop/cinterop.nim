# Chapter 22 — The C Boundary.
#
# Two directions: Nimony calls C through `importc`, and a C name in the
# generated program can carry a Nimony proc. Everything here is run by
# tools/verify-samples.sh at the pinned toolchain.
import std / [syncio, strutils]

proc strlen(s: cstring): int {.importc, header: "<string.h>".}
proc memset(p: pointer, c: cint, n: csize_t): pointer {.importc, header: "<string.h>".}
proc getenv(name: cstring): nil cstring {.importc, header: "<stdlib.h>".}

type
  DivT {.importc: "div_t", header: "<stdlib.h>", nodecl.} = object
    quot: cint
    rem: cint

proc cdiv(a, b: cint): DivT {.importc: "div", header: "<stdlib.h>".}

# A Nimony string seen by C. `toCString` needs a `var`, and the view is writable.
var greeting = "hello"
let asC = toCString(greeting)
echo strlen(asC)
echo $asC

# A `cstring` literal is raw: the backslash is a character, not an escape.
echo strlen(cstring"a\nb"), " ", "a\nb".len

# A C struct returned by value.
let d = cdiv(7, 2)
echo d.quot, " ", d.rem

# A Nimony buffer written by C.
var buf: array[4, char]
discard memset(addr buf[0], cint(ord('x')), 3)
echo buf[0], buf[1], buf[2], " ", buf[3] == '\0'

# `sizeof` asks C about an importc type.
echo sizeof(cint), " ", sizeof(DivT)

# A C pointer that may be null has to be declared `nil cstring`.
let missing = getenv(cstring"BOOK22_NOPE")
echo isNil(missing)

# The view and the string are the same bytes.
asC[0] = 'H'
echo greeting

# C stops at the first zero byte, the Nimony string does not.
var withNul = "a\0b"
echo withNul.len, " ", strlen(toCString(withNul))

# An array of `nil cstring`: the check works on a local copy, not on the slot.
var slots: array[2, nil cstring]
slots[0] = cstring"one"
slots[1] = nil
let first: nil cstring = slots[0]
if first != nil:
  echo strlen(first)
echo isNil(slots[1])
