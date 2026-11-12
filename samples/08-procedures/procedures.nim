import std/syncio

# A block body: the last expression in the body is the result.
proc double(x: int): int =
  x * 2

# The single-expression form of the same declaration.
proc triple(x: int): int = x * 3

# `result` is an ordinary variable, returned when the body ends.
proc shout(msg: string): string =
  result = msg & "!"
  result = result & "!"

echo "block ", double(21)
echo "single ", triple(5)
echo "result ", shout("hi")

# `return` with a value ends the proc at that line.
proc grade(n: int): string =
  if n >= 50:
    return "pass"
  echo "checked ", n
  "fail"

echo "early ", grade(70)
echo "late ", grade(10)

# A bare `return` returns whatever `result` holds.
proc sign(n: int): int =
  if n > 0:
    result = 1
    return
  result = 0

echo "bare ", sign(4), " ", sign(-4)

# A default value fills in an omitted argument.
proc pad(n: int; width: int = 3): int = n * width

echo "default ", pad(7)
echo "named ", pad(width = 2, n = 7)

# `var` parameters write back to the caller's variable.
proc bump(x: var int) =
  x = x + 1

var n = 5
bump(n)
echo "var ", n

# `out` parameters are written by the proc and must be set on every path.
proc split(a, b: int; q, r: out int) =
  q = a div b
  r = a mod b

var q, r: int
split(8, 5, q, r)
echo "out ", q, " ", r

# The other way to return two values: a tuple.
proc divmod(a, b: int): (int, int) = (a div b, a mod b)

let t = divmod(8, 5)
echo "tuple ", t[0], " ", t[1]

# A `sink` parameter may take over the argument's storage.
proc take(s: sink string) =
  echo "sink got ", s

var text = "abc"
take(text)
echo "sink after ", text

# `func` is a proc that is side-effect free by default.
func square(x: int): int = x * x

echo "func ", square(7)

# The default can be overridden when the side effect is deliberate.
func loud(x: int): int {.sideEffect.} =
  echo "override ran"
  x

let loudResult = loud(1)
echo "override ", loudResult

# A value is not a statement: it has to be used or discarded.
proc add(a, b: int): int = a + b

discard add(1, 2)
echo "dot ", 5.add(6)

# Command syntax drops the parentheses on a statement.
proc note(msg: string) =
  echo "note ", msg

note "no parens"

# A proc may call itself.
proc fact(n: int): int =
  if n <= 1:
    1
  else:
    n * fact(n - 1)

echo "fact ", fact(5)

# A call may appear before the declaration it resolves to.
echo "later ", later(4)

proc later(x: int): int = x + 1
