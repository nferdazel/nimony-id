import std/syncio

template twice(x: untyped): untyped =
  var acc = x
  acc + acc

template setup() =
  proc report() {.inject.} = echo "report ready"
  let limit {.inject.} = 3

proc squares(n: int): seq[int] =
  var acc: seq[int] = @[]
  for i in 0 ..< n:
    acc.add i * i
  acc

var acc = 100
echo twice(3)
echo acc
setup()
report()
echo limit

const Folded = [2, 4, 6]
const Size = Folded.len
const Table = squares(4)

echo Size
echo Table[3]
echo Folded[2]
