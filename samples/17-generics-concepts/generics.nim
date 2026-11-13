import std/syncio

type
  Addable = concept
    proc `+`(a, b: Self): Self

proc twice[T: Addable](x: T): T = x + x

proc sumAll[T: Addable](xs: seq[T]): T =
  var total = xs[0]
  for i in 1..<xs.len:
    total = total + xs[i]
  total

type Money = object
  cents: int

proc `+`(a, b: Money): Money = Money(cents: a.cents + b.cents)

echo twice(21)
echo sumAll(@[1, 2, 3])
echo sumAll(@[Money(cents: 5), Money(cents: 7)]).cents
