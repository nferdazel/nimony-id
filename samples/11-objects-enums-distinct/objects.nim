import std/syncio

# An object names its fields. Constructing it uses `field: value`, and any
# field left out takes its default: 0, false, or an empty string.
type Point = object
  x: int
  y: int

var p = Point(x: 1, y: 2)
echo p.x
echo p.y
p.y = 9
echo p.y

var empty = Point()
echo empty.x
echo empty.y

# Fields may carry a default of their own.
type Badge = object
  label: string = "new"
  level: int = 1

echo Badge().label
echo Badge(level: 4).level

# Assignment copies the object, field by field. The copy and the original are
# separate values, even when a field is a seq.
type Bag = object
  name: string
  items: seq[int]

var a = Bag(name: "a", items: @[1, 2])
var b = a
b.name = "b"
b.items[0] = 99
echo a.name
echo a.items[0]
echo b.name
echo b.items[0]

# A by-value parameter is not a place, so it cannot write the caller's object.
# A `var` parameter is.
proc sumOf(v: Point): int =
  result = v.x + v.y

proc moveRight(v: var Point) =
  v.x = v.x + 10

echo sumOf(p)
moveRight(p)
echo p.x

# `echo` writes built-in types only; a custom type needs `$` applied yourself.
func `$`(v: Point): string =
  "(" & $v.x & ", " & $v.y & ")"

echo $p

# An enum is ordered. `ord` gives the position, comparison follows the order,
# and a value may be qualified with its type.
type Color = enum
  red, green, blue

echo ord(red)
echo ord(blue)
echo red < blue
echo Color.green
echo green.ord

# An enum can index an array, and can be walked.
var counts: array[Color, int]
counts[green] = 5
echo counts[green]
echo counts.len
for c in Color:
  echo c

# Explicit ordinals are allowed in ascending order, with holes; a hole makes
# the enum non-ordinal, so `inc` no longer applies to it. A string may be
# attached to a value and becomes what `$` prints.
type Token = enum
  word = (2, "word")
  number = 4
  symbol = 89

echo ord(word)
echo ord(symbol)
echo word
echo number
echo symbol

# A distinct type shares its base's representation and nothing else.
# Building it and going back both need an explicit conversion.
type Meters = distinct int

let m = Meters(4)
echo int(m)
echo m.int
echo sizeof(Meters)
echo sizeof(int)

# Operators are not inherited. Each one the type needs is written, or borrowed
# from the base type.
func `+`(lhs, rhs: Meters): Meters {.borrow.}
func `$`(v: Meters): string = $int(v) & "m"

echo int(Meters(2) + Meters(3))
echo $m

# Distinct works over a non-numeric base too, including an object.
type Reading = object
  value: int

type Sample = distinct Reading

var s = Sample(Reading(value: 7))
echo s.Reading.value
