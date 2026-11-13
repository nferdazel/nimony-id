import std/syncio

# A failure is a value first: an ordinary ErrorCode return, checked by the
# caller.
proc classify(ch: char): ErrorCode =
  if ch < '0' or ch > '9': return SyntaxError
  Success

for ch in ['7', 'x']:
  let code = classify(ch)
  if code == Success:
    echo "digit ", ch
  else:
    echo "rejected ", ch, " with ", code

# The same enum can be raised instead. The pragma is the declaration that the
# routine may fail this way.
proc digitValue(ch: char): int {.raises.} =
  if ch < '0' or ch > '9': raise SyntaxError
  result = ord(ch) - ord('0')

try:
  let a = digitValue('4')
  echo "value ", a
  let b = digitValue('z')
  echo "value ", b
except ErrorCode as e:
  case e
  of SyntaxError: echo "caught SyntaxError"
  else: echo "caught ", e

# A raising routine can hand the failure to its caller instead of handling it.
proc twoDigits(a, b: char): int {.raises.} =
  result = digitValue(a) * 10 + digitValue(b)

try:
  let n = twoDigits('1', '2')
  echo "number ", n
  let m = twoDigits('1', 'z')
  echo "number ", m
except ErrorCode as e:
  echo "second call failed with ", e

# A ref exception is the other raisable family, and the only one that carries a
# payload. It must inherit from Exception.
type ParseError = ref object of Exception
  at: int

proc checkAt(s: string; i: int) {.raises: ParseError.} =
  if i >= s.len: raise ParseError(at: i)

try:
  checkAt("abc", 9)
except ParseError as e:
  echo "no character at ", e.at

# finally runs on both paths, so a caller sees the cleanup even when the body
# fails.
proc guarded(): int =
  try:
    result = digitValue('q')
  except ErrorCode as e:
    echo "inside guarded: ", e
    result = -1
  finally:
    echo "finally ran"

let g = guarded()
echo "guarded ", g
