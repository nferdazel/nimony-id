import plugins

proc transform(n: NifCursor): NifBuilder =
  result = createTree()
  let info = n.info
  var arg = callArgs(n)
  let tag = arg.tagText
  result.withTree StmtsS, info:
    result.withTree CallS, info:
      result.addIdent "echo"
      result.addStrLit tag

var inp = loadPluginInput()
saveTree transform(inp)
