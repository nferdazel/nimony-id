import std / [assertions, syncio]

proc check(name: string; cond: bool; checks, failures: var int) =
  inc checks
  if cond:
    echo "ok - ", name
  else:
    inc failures
    echo "not ok - ", name

func double(x: int): int =
  assert x > 0, "double wants a positive argument"
  x * 2

var checks = 0
var failures = 0

check("double of 4", double(4) == 8, checks, failures)
check("length of hello", "hello".len == 5, checks, failures)
check("empty string", "".len == 0, checks, failures)
echo checks, " checks, ", failures, " failed"
quit(if failures == 0: 0 else: 1)
