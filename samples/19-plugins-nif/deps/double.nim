import plugins

proc transform(n: NifCursor): NifBuilder =
  result = createTree()
  let info = n.info
  var arg = callArgs(n)
  result.withTree CallX, info:
    result.addIdent "twice"
    result.addSubtree arg

var inp = loadPluginInput()
saveTree transform(inp)
