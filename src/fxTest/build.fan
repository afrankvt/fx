#! /usr/bin/env fan

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "fxTest"
    summary = "Unit tests for FX Framework"
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
      "concurrent 1.0",
      "compiler 1.0",
      "build 1.0",
      "graphics 1.0",
      "web 1.0",
      "dom 1.0"
    ]
    srcDirs = [`test/`]
  }
}
