import std/syncio

# Two mutable arguments may name disjoint fields of one object: neither
# mutation can reach the other's storage.
type Pair = object
  x, y: int

proc swap(a: var int, b: var int) =
  let tmp = a
  a = b
  b = tmp

var p = Pair(x: 1, y: 2)
swap(p.x, p.y)
echo "pair ", p.x, " ", p.y

# Iteration borrows the path it walks. A sibling field of that path stays
# writable until the loop ends.
type Config = object
  elements: seq[int]
  name: string

var c = Config(elements: @[1, 2], name: "old")
for e in c.elements:
  c.name = "new"
  echo "during ", e
echo "name ", c.name

# A returned view may borrow from the first parameter, because that parameter
# is the caller's own storage.
proc window(s: seq[int]): openArray[int] =
  result = toOpenArray(s)

let nums = @[10, 20, 30]
let w = window(nums)
echo "window ", w.len, " first ", w[0]

# move is a library call: it hands the value over and leaves the name behind
# in a moved-from state, empty here.
var text = "payload"
let taken = move(text)
echo "taken ", taken, " left ", text.len

# A moved reference leaves nil behind, so the old name can no longer reach the
# cell.
type Cell = ref object
  n: int

var cell = Cell(n: 7)
let owner = move(cell)
echo "cell ", owner.n, " gone ", cell == nil

# A sink parameter takes a copy here; the caller's variable is untouched.
proc consume(s: sink string): string =
  result = s

var payload = "shared"
let kept = consume(payload)
echo "kept ", kept, " payload ", payload
