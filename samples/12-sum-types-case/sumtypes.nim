import std/syncio
import std/math

# One object, one discriminator, and fields that exist only for the matching
# value. Construction names the discriminator; the other branches are not
# written at all.
type
  ShapeKind = enum
    Circle, Rectangle, Triangle

  Shape = object
    case kind: ShapeKind
    of Circle:
      radius: float
    of Rectangle:
      width, height: float
    of Triangle:
      a, b, c: float

# The `case` has one branch per enum value and no `else`. Leave one out and
# the build stops with `not all cases are covered; missing: {...}`.
func area(s: Shape): float =
  case s.kind
  of Circle:
    result = PI * s.radius * s.radius
  of Rectangle:
    result = s.width * s.height
  of Triangle:
    let p = (s.a + s.b + s.c) / 2.0
    result = sqrt(p * (p - s.a) * (p - s.b) * (p - s.c))

func `$`(s: Shape): string =
  case s.kind
  of Circle:
    result = "circle(" & $s.radius & ")"
  of Rectangle:
    result = "rect(" & $s.width & "x" & $s.height & ")"
  of Triangle:
    result = "tri(" & $s.a & "," & $s.b & "," & $s.c & ")"

let c = Shape(kind: Circle, radius: 1.0)
let r = Shape(kind: Rectangle, width: 2.0, height: 3.0)
let t = Shape(kind: Triangle, a: 3.0, b: 4.0, c: 5.0)

echo $c
echo $r
echo $t
echo area(c)
echo area(r)
echo area(t)

# The `case` expression form yields a value, so it can be the right side of a
# declaration. This one has an `else`; that is allowed even when the enum is
# fully covered.
let label =
  case r.kind
  of Circle: "round"
  of Rectangle: "boxy"
  else: "pointy"

echo label

# A branch may name more than one value.
func sides(k: ShapeKind): int =
  case k
  of Circle: 0
  of Triangle: 3
  of Rectangle: 4

echo sides(Circle)
echo sides(Rectangle)

# A field the constructor leaves out takes its type's default, and a default
# written inside the branch applies too.
echo Shape(kind: Rectangle, width: 1.0).height
echo Shape(kind: Rectangle).width

# A variant is a value like any other: assignment copies it, `==` compares it
# field by field.
var copy = r
copy.width = 99.0
echo r.width
echo copy.width
echo copy.kind
echo r == Shape(kind: Rectangle, width: 2.0, height: 3.0)

# Variants nest. A tree is the case everyone writes.
type
  NodeKind = enum
    Leaf, Branch

  Node = object
    id: int
    case kind: NodeKind
    of Leaf:
      value: string
    of Branch:
      children: seq[Node]

func total(n: Node): int =
  case n.kind
  of Leaf:
    result = n.id
  of Branch:
    result = n.id
    for child in n.children:
      result = result + total(child)

let tree = Node(id: 1, kind: Branch, children: @[
  Node(id: 2, kind: Leaf, value: "a"),
  Node(id: 3, kind: Leaf, value: "b")])

echo tree.kind
echo tree.children.len
echo tree.children[0].value
echo total(tree)
