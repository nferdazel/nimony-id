import std/syncio

# One name, two routines: the argument type picks the candidate.
func render(x: int): string = "int " & $x
func render(x: string): string = "text " & x

# Arity is part of the set, so these two coexist.
func twice(x: int): int = x * 2
func twice(x: int, y: int): int = x * 2 + y

# Any first parameter can be the receiver of a method call.
func wrap(s: string, n: int): string = s & $n

type Box = object
  v: int

# Reading an index is a plain `[]`; writing one needs its own `[]=`.
func `[]`(b: Box, i: int): int = b.v
func `[]=`(b: var Box, i: int, val: int) = b.v = val

echo render(3)
echo render("a")
echo twice(4)
echo twice(4, 1)
echo 5.twice
echo 5.twice(1)
echo "a".wrap(1)
var b = Box(v: 7)
b[0] = 9
echo b[0]

# A var result may borrow through heap storage, so a plain parameter is enough
# when the element lives behind a seq instead of in an inline field.
type Container = object
  data: seq[int]

func `[]`(c: Container, i: int): var int = c.data[i]

var c = Container()
c.data.add 1
c.data.add 2
echo c[0]
c.data[0] = 5
echo c[0]
