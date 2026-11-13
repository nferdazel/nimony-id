import std / [syncio, paths, dirs, tempfiles, files, envvars, cmdline, osproc, os]

proc contents(f: Path): string =
  # readFile is {.raises.}: a missing file is an ErrorCode, not a crash.
  try:
    result = readFile($f)
  except ErrorCode as e:
    echo "read failed: ", e
    result = ""

try:
  let work = createTempDir("book21", "")
  let note = work / path("note.txt")

  writeFile($note, "first\n")
  echo contents(note).len

  # A second writeFile replaces the file; it never appends.
  writeFile($note, "second\n")
  echo contents(note)

  # Appending needs an open mode, and a File you close yourself.
  var f: File
  discard open(f, $note, fmAppend)
  f.writeLine("third")
  close(f)
  echo contents(note).len

  var g: File
  var lines = 0
  if open(g, $note, fmRead):
    var line = ""
    while readLine(g, line):
      lines = lines + 1
    close(g)
  echo lines

  echo getFileSize($note)
  echo fileExists($note), " ", fileExists($(work / path("nope.txt")))
  echo tryRemoveFile(note)
  echo fileExists($note)

  # The environment: reads are total, writes can fail.
  echo getEnv("BOOK21_MISSING", "fallback")
  putEnv("BOOK21_VALUE", "visible")
  echo getEnv("BOOK21_VALUE")
  delEnv("BOOK21_VALUE")
  echo existsEnv("BOOK21_VALUE")

  # Arguments under the verifier: there are none.
  echo paramCount()

  # A child process: argv is a list, so an argument with a space stays one.
  let printed = execProcess("/usr/bin/printf", args = ["%s|", "a b", "c"],
                            options = {poUsePath})
  echo printed

  # stderr is folded into stdout, and the exit code comes back separately.
  let (noise, code) = execCmdEx("/bin/sh -c 'echo err 1>&2; exit 7'")
  echo noise.len, " ", code

  removeDir(work)
except ErrorCode as e:
  echo "failed: ", e
