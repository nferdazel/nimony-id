import std/syncio

# A managed reference: one cell, many names. Writing through a parameter needs
# no `var`, because the cell is shared, not copied.
type Counter = ref object
  n: int

proc bump(c: Counter) =
  c.n += 1

# A list says nil in the type at every link, so the walk has to prove the link
# is not nil before it reads the field.
type Node = ref object
  data: int
  next: nil Node

proc total(list: nil Node): int =
  var it = list
  var sum = 0
  while it != nil:
    sum += it.data
    it = it.next
  sum

# A fresh cell starts in a nullable variable. The guard is what makes the
# result acceptable as a `ref int`: the type of the value handed back is
# not-nil, and only a proven non-nil value may initialise it.
proc boxed(v: int): ref int =
  var tmp: nil ref int = nil
  new(tmp)
  if tmp == nil: quit "out of memory"
  tmp[] = v
  tmp

proc main =
  let c = Counter(n: 0)
  bump(c)
  bump(c)
  echo c.n

  let list = Node(data: 1, next: Node(data: 2, next: Node(data: 3)))
  echo total(list)
  echo total(nil)

  let b = boxed(41)
  echo b[] + 1

  var local = 10
  let p: ptr int = addr local
  p[] = 20
  echo local

main()
