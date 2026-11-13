import std/syncio
import shapes
export shapes

proc summary*(s: Shape): string =
  $s.sides & " sides"

proc shout*(s: Shape): string =
  var acc = ""
  for ch in s.name:
    if ch >= 'a' and ch <= 'z':
      acc.add chr(ord(ch) - 32)
    else:
      acc.add ch
  acc
