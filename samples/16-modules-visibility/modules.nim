import std/syncio
import support/report
from support/shapes import nil
include support/notes

let square = shape("square", 4)
echo describe(square)
echo summary(square)
echo shapes.describe(square)
echo shout(square)
echo note(square)
echo square.name, " has ", square.sides, " sides"
