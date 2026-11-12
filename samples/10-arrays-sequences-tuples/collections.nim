import std/syncio

# An array's length lives in its type, so it is fixed before the program runs.
var grid: array[2, array[2, int]]
grid[0] = [1, 2]
grid[1] = [3, 4]
echo grid.len
echo grid[1][0]

# `array[5, T]` is five elements; `array[0..5, T]` is six.
var five: array[5, int]
var six: array[0..5, int]
echo five.len
echo six.len
echo five[4]

# A non-zero base moves the valid indexes, not the length.
type Row = array[1..3, int]
var row: Row = [5, 6, 7]
echo row[1]
echo row.low
echo row.high

# Any ordinal type can index an array, an enum included.
type Color = enum red, green, blue
var counts: array[Color, int]
counts[green] = 5
echo counts[green]
echo counts.low

# A seq starts from a literal (`@[...]`) or from `newSeq`, and grows one
# element at a time.
var xs = @[1, 2, 3]
xs.add 4
echo xs.len
echo xs.pop
echo xs.len
echo xs[0]
echo xs.high

# Slicing a seq returns a fresh seq with copies, and clamps the bounds.
var mid = xs[1..2]
mid.add 99
echo mid.len
echo xs.len
echo xs[2..10].len
echo xs[5..1].len
echo xs[1..^1].len

# `@` converts an array into a seq, and assignment copies.
let fromArray = @[7, 8]
var copy = xs
copy.add 9
echo fromArray.len
echo copy.len
echo xs.len

# An openArray parameter accepts an array or a seq without a conversion.
func total(v: openArray[int]): int =
  result = 0
  for x in v:
    result = result + x

echo total([1, 2, 3])
echo total(xs)

# An array has no slice operator; `toOpenArray` makes a view instead.
var letters = [10, 20, 30, 40]
let view = letters.toOpenArray(1, 2)
view[0] = 99
echo view.len
echo letters[1]

# A tuple is heterogeneous and ordered; fields may be named.
type Person = tuple[name: string, age: int]
var person: Person = ("Ada", 36)
echo person.name
echo person[1]

# Assignment copies the tuple, field by field.
var other = person
other.age = 37
echo person.age
echo other.age

# Unpacking works with `_` for the parts you skip, and nests.
proc pair(): (int, int) = (4, 2)
let (a, b) = pair()
echo a
echo b
let (x, _, z) = (1, 2, 3)
echo x
echo z
let (m, (n, o)) = (1, (2, 3))
echo m
echo n
echo o
