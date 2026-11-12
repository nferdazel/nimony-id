import std/syncio

# `a..b` counts up and includes both ends.
for i in 0..3:
  echo "incl ", i

# `a..<b` stops before the upper bound.
for i in 0..<3:
  echo "half ", i

# A descending bound is empty, not reversed.
var seen = 0
for i in 3..0:
  seen = seen + 1
echo "descending count ", seen

# Counting down is a separate iterator.
for i in countdown(3, 1):
  echo "down ", i

# `countup` takes a step; `countdown` takes one too.
for i in countup(0, 6, 2):
  echo "step ", i

# `char` is an ordinal: the bounds are characters.
for c in 'a'..'c':
  echo "char ", c

# The string-index idiom: half-open bounds, so the last index is length minus one.
let word = "abc"
for i in 0..<len(word):
  echo "index ", i, " ", word[i]

# `continue` goes to the next iteration and skips the rest of this one.
for i in 0..5:
  if i mod 2 == 0:
    continue
  echo "odd ", i

# `while` tests first, so the body may never run.
var n = 0
while n < 3:
  echo "while ", n
  n = n + 1

var total = 0
for i in 1..4:
  total = total + i
echo "total ", total

# A range parameter needs the proof at the call. A comparison guard supplies it.
proc clamped(x: range[0..9]) =
  echo "digit ", x

proc showDigit(n: int) =
  if n >= 0 and n <= 9:
    clamped(n)
  else:
    echo "not a digit"

showDigit(7)
showDigit(70)
