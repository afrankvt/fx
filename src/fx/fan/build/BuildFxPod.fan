//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   2 Oct 2018  Andy Frank  Creation
//

using build

abstract class BuildFxPod : BuildPod
{
  ** List of Uris relative to build script of directories
  ** containing '*.fx' source files to compile.
  Uri[]? fxDirs

  // TODO: should compile implict staticJs?
  @Target {}
  override Void compile()
  {
    super.compile
    staticJs
  }

  ** Compile Fan and fx code into pod file.
  @Target { help = "Compile to pod file and associated natives" }
  override Void compileFan()
  {
    // compile fx to temp dir
    fxTempDir := scriptDir + `__fxtmp/`
    fxTempDir.delete
    compileFx(fxTempDir)

    // add temp dir to srcDir list and compileFan
    srcDirs.add(`__fxtmp/`)
    super.compileFan
  }

  ** Compile '*.fx' source files into '*.fan' files under 'dir'.
  private Void compileFx(File outDir)
  {
    log.info("CompileFx [$podName]")
    fxDirs.each |dir|
    {
      (scriptDir + dir).listFiles.each |file|
      {
        if (file.ext != "fx") return
        ast := FxParser(podName, file.name, file.in).parse
        // ast.each |n| { n.dump }
        out := (outDir + `${file.basename}.fan`).out
        FxFanWriter(ast).write(out)
        out.sync.close
      }
    }
  }

  ** Write compiled JavaScript to a static file.
  @Target { help = "Write compiled JavaScript to a static file" }
  virtual Void staticJs()
  {
    log.info("staticJs [$podName]")
    log.indent

    libDir := Env.cur.workDir + `lib/fx/`
    fxJs   := libDir + `fx.js`
    podJs  := libDir + `${podName}.js`

    // write out fx.js
    out  := fxJs.out
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

    // include entire tzdb to keep things simple (15k gziped)
    tz := Env.cur.findAllFiles(`etc/sys/tz.js`).first
    out.print(tz.readAllStr)
    out.sync.close
    log.info("WriteJs [$fxJs.osPath]")

    // write out pod.js
    out = podJs.out
    Pod.find("${podName}").file(`/${podName}.js`).readAllLines.each |line|
    {
      // TODO: for now skip source maps...
      if (line.startsWith("//# sourceMappingURL=")) return
      out.printLine(line)
    }
    out.sync.close
    log.info("WriteJs [$podJs.osPath]")
  }
}