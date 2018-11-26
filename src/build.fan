#! /usr/bin/env fan

using build

class Build : BuildGroup
{
  new make()
  {
    childrenScripts =
    [
      `fx/build.fan`,
      `fxSample/build.fan`,
    ]
  }
}
