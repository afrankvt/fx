/*

TODO: old code we might still use

//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Sep 2018  Andy Frank  Creation
//

using compiler

**
** FxScript
**
class FxScript
{
  static Int main()
  {
    file := Env.cur.args.first

    if (file == null)
    {
      echo("usage: fxc <file>")
      return 1
    }

    in  := File.os(file)
    ast := FxParser("test__", in.in).parse

    echo("--- AST ---")
    ast.each |n| { n.dump }

    echo("\n--- Fan ---")
    buf := Buf()
    FxFanWriter(ast).write(buf.out)
    fan := buf.flip.readAllStr
    File.os("test.fan").out.print(fan).sync.close
    echo(fan)

    echo("--- JS ---")
    input := CompilerInput.make
    input.podName   = "test__"
    input.summary   = ""
    input.version   = Version("0")
    input.log.level = LogLevel.err
    input.isScript  = true
    input.srcStr    = fan
    input.srcStrLoc = Loc.makeFile(in)
    input.mode      = CompilerInputMode.str
    input.output    = CompilerOutputMode.js

    // TODO: source maps...
    js := Compiler(input).compile.js
    js = js.splitLines.findAll |s| { !s.startsWith("//# sourceMappingURL=") }.join("\n")
    File.os("test.js").out.print(js).sync.close

    // output core fx.js
    writeFxJs

    return 0
  }

  ** Write 'fx.js' which is single combined js file containing
  ** all the core dependices for fx pod.
  static Void writeFxJs()
  {
    out  := File.os("fx.js").out
    deps := ["sys", "concurrent", "graphics", "web", "dom", "fx"]

    deps.each |pod|
    {
      Pod.find("${pod}").file(`/${pod}.js`).readAllLines.each |line|
      {
        // TODO: for now skip source maps...
        if (line.startsWith("//# sourceMappingURL=")) return
        out.printLine(line)
      }
    }

    // TODO: timezones...
    tz := Env.cur.findAllFiles(`etc/sys/tz.js`).first
    out.print(tz.readAllStr)

    out.sync.close
  }
}
*/