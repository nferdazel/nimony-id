import std/syncio

type Shape* = object
  name*: string
  sides*: int

proc shape*(name: string; sides: int): Shape =
  Shape(name: name, sides: sides)

proc interior(s: Shape): int =
  (s.sides - 2) * 180

proc describe*(s: Shape): string =
  s.name & ": " & $s.sides & " sides, " & $interior(s) & " degrees"
