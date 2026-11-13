import std / syncio

# The same argument reaches the plugin through two parameter kinds.
template shape(x: untyped) {.plugin: "deps/shape".}
template typedShape(x: typed) {.plugin: "deps/shape".}

shape(2 + 3 * 4)
typedShape(2 + 3 * 4)

proc twice(n: int): int = n + n

# A plugin that builds a value out of the argument it was given.
template double(x: typed): int {.plugin: "deps/double".}

echo double(21)

# A module plugin rewrites the module after semantic analysis.
{.plugin: "deps/erase".}

block:
  echo "erased"
