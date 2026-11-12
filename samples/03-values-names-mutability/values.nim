import std/syncio

# const: the value is fixed before the program runs, and it may be computed there.
const Language = "nimony"
const Banner = Language & " / names and values"

proc double(x: int): int = x * 2
const Twice = double(4)

# let: bound once. This is the name you read from.
let limit = 3

# var: the one declaration that can be written more than once.
var total = 0

for i in 1 .. limit:
  total = total + i

echo Banner
echo Twice
echo total

# Case matters: these are two different names, both live.
let step = 2
let Step = 5
echo step
echo Step

# Scope: the inner name lives only inside its block; the outer one comes back.
block:
  let step = 100
  echo step

echo step

# A var may be declared without a value: at module level it starts at 0, and both branches write it anyway.
var chosen: int
if total > 5:
  chosen = 1
else:
  chosen = 2
echo chosen
