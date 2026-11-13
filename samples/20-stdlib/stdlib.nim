import std / [syncio, strutils, sequtils, tables, sets, atomics]

# A string helper that fails: parseInt is marked {.raises.}, so the caller
# handles an ErrorCode, exactly as chapter 15 taught.
proc number(s: string): int =
  try:
    result = parseInt(s)
  except ErrorCode as e:
    echo "not a number: ", s
    result = -1

echo number("42")
echo number("4x")

# Splitting, stripping, joining.
let record = "  tea : 2 "
let halves = record.strip.split(":")
echo halves.len
echo halves[0].strip
echo halves[1].strip

echo ["tea", "coffee"].join(" and ")
echo repeat("-", 3)

# Sequence helpers live in system and sequtils, not in a std/seqs module.
var xs = @[1, 2, 3]
xs.add(4)
echo xs.len
xs.setLen(3)
xs.delete(0)
echo xs.len, " ", xs[0]

# insert and the range form of delete are in sequtils, not in system.
xs.insert(@[9], 0)
echo xs.len, " ", xs[0]
xs.delete(0, 0)
echo xs.len, " ", xs[0]
echo concat(@[1], @[2, 3]).len

let doubled = @[1, 2, 3].map(proc (n: int): int = n * 2)
echo doubled[0], " ", doubled[2]

let even = @[1, 2, 3, 4].filter(proc (n: int): bool = n mod 2 == 0)
echo even.len

# Tables: reading a key is fallible, writing is not, and the guide does not
# promise an iteration order, so the sample sums instead of printing pairs.
var counts = initTable[string, int]()
counts["tea"] = 1
counts["coffee"] = 7
counts["tea"] = counts.getOrDefault("tea", 0) + 1

var total = 0
for k, v in counts.pairs:
  total = total + v
echo total
echo counts.hasKey("milk")

proc lookup(t: Table[string, int]; k: string): int =
  try:
    result = t[k]
  except ErrorCode:
    echo "missing: ", k
    result = 0

echo lookup(counts, "tea")
echo lookup(counts, "milk")

# Sets of values, not bitsets.
var tags = initHashSet[string]()
tags.incl("hot")
tags.incl("milk")
tags.incl("hot")
echo tags.len
echo tags.contains("milk")
echo tags.containsOrIncl("milk")
echo tags.containsOrIncl("sugar")

# Atomics are operations on an ordinary variable, not a wrapper type.
var hits = 0
discard atomicFetchAdd(hits, 1)
discard atomicFetchAdd(hits, 1)
echo atomicLoad(hits)
atomicStore(hits, 10)
echo atomicLoad(hits)
