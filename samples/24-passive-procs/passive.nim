import std/syncio

var resumeA, resumeB: Continuation

proc double(x: int): int {.passive.} =
  result = x * 2

proc solo(name: string) {.passive.} =
  echo "solo ", name, " start"
  echo "solo ", name, " end"

proc worker(name: string; which: int) {.passive.} =
  echo "worker ", name, " start"
  if which == 0: resumeA = delay()
  else: resumeB = delay()
  suspend()
  echo "worker ", name, " end"

proc drive(c: Continuation) =
  var c = c
  while not stopping(c):
    c = advance(c)

echo "double 21 = ", double(21)

let built = delay(solo("a"))
echo "built, not run"
complete(built)

drive(delay(worker("b", 0)))
drive(delay(worker("c", 1)))
echo "both parked"
drive(resumeA)
drive(resumeB)
echo "done"

{.feature: "assumeSync".}
