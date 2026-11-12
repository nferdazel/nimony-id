import std/syncio
import std/strutils

# A string is a value. Length, index, last element, slice.
let title = "Nimony"
echo title.len            # 6
echo title[0]             # N
echo ord(title[0])        # 78
echo title[^1]            # y
echo title[0..2]          # Nim

# Build a string with `&`, or grow a `var` with `add`.
var line = "strings"
line.add " and "
line.add 'v'
line.add "alues"
echo line                 # strings and values

# Comparison is lexicographic over bytes.
echo "abc" == "abc"       # true
echo "abc" < "abd"        # true
echo "ABC" < "abc"        # true

# Assignment copies the value.
var copied = line
copied.add "!"
echo line                 # strings and values
echo copied               # strings and values!

# Escapes, raw strings, concatenation.
echo "a\tb"               # a, tab, b
echo r"a\tb"              # a\tb, backslash kept
echo "A" & "B"            # AB

# A char is one byte; `"" & c` turns it into a string.
echo "" & 'z'             # z
echo "n=" & $42           # n=42

# Indexing counts bytes, not unicode characters.
let utf = "héllo"
echo utf.len              # 6
echo ord(utf[1])          # 195

# A `var` string can be written in place at an index.
var buffer = "hello"
buffer[0] = 'H'
echo buffer               # Hello

# A slice that runs past the end is clamped, not an error.
echo "clamped"[0..20]     # clamped

# strutils does the text work.
let parts = "alpha,beta,gamma".split(",")
echo parts.len            # 3
echo parts[1]             # beta
echo "alpha".find("pha")  # 2
echo "alpha".find("zzz")  # -1

# cstring: the C boundary. `toCString` needs a `var` string, because it
# writes the terminating zero itself.
var mutable = "cstring"
let c = toCString(mutable)
echo len(c)               # 7, strlen stops at the written zero
echo $c                   # cstring, the `$` comes from strutils
echo fromCString(c)       # cstring

let lit = cstring"hi"
case lit
of "hi": echo "cstring case"
else: echo "no"
