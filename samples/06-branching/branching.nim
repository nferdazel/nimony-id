import std/syncio

# `if` as a statement.
let score = 72
if score >= 90:
  echo "A"
elif score >= 70:
  echo "B"
else:
  echo "C"

# `if` as an expression: the `else` part is required.
let label = if score >= 50: "pass" else: "fail"
echo label

# `case` as a statement, with `else` for the open domain.
let n = 3
case n
of 0: echo "zero"
of 1, 2: echo "small"
else: echo "large"

# `case` as an expression over an enum: exhaustive, no `else` needed.
type Color = enum red, green, blue
let c = green
let name = case c
  of red: "r"
  of green: "g"
  of blue: "b"
echo name

# `elif` is not accepted in a `case` at this pin: nest an `if` in `else`.
let grade = case score
  of 0..59: "F"
  else:
    if score >= 90: "A" else: "B"
echo grade

# A string selector needs no `else`, but give it one anyway.
let noun = "hammer"
let article = case noun
  of "apple", "orange": "an"
  of "hammer": "a"
  else: "a"
echo article

# `when` is a compile-time branch.
when sizeof(int) == 8:
  echo "64-bit int"
else:
  echo "not 64-bit"
let width = when sizeof(int) == 8: 64 else: 32
echo width

# A `block` can be an expression and a labelled escape.
let total = block:
  var sum = 0
  for i in 1..4:
    sum = sum + i
  sum
echo total

var hits = 0
block outer:
  for i in 0..3:
    for j in 0..3:
      if i * j == 4:
        hits = hits + 1
        break outer
echo hits

# An unlabelled `break` leaves only the innermost loop.
var pairs = 0
for i in 0..2:
  for j in 0..2:
    if j == 1:
      break
    pairs = pairs + 1
echo pairs
