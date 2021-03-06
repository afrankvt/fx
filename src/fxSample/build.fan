#! /usr/bin/env fan

using build

class Build : fx::BuildFxPod
{
  new make()
  {
    podName = "fxSample"
    summary = "Samples for FX framework"
    version = Version("0.1")
    meta = [
      "proj.name":    "FX: Fantom JavaScript Framework",
      "proj.uri":     "https://github.com/afrankvt/fx",
      "license.name": "MIT",
      "vcs.name":     "Git",
      "vcs.uri":      "https://github.com/afrankvt/fx"
    ]
    depends = [
      "sys 1.0",
      "util 1.0",
      "concurrent 1.0",
      "xml 1.0",
      "graphics 1.0",
      "web 1.0",
      "dom 1.0",
      "fx 0+",
    ]
    srcDirs = [`fan/`]
    fxDirs = [`fx/`]
  }
}
