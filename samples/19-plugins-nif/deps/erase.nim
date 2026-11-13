import plugins

proc transform(n: NifCursor): NifBuilder =
  result = createTree()
  let info = n.info
  var body = firstChild(n)
  result.withTree StmtsS, info:
    while body.hasMore:
      if body.kind == TagLit and body.stmtKind == BlockS:
        skip body
      else:
        result.takeTree body

var inp = loadPluginInput()
saveTree transform(inp)
