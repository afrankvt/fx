#! /usr/bin/env fan

using build

class Build : BuildGroup
{
  new make()
  {
    childrenScripts =
    [
      `fx/build.fan`,
      `fxTest/build.fan`,

      // Samples will not build in-process since it depends
      // on reloading the compiler fx; so build samples after
      // core fx pod has been built.
      // `fxSample/build.fan`,
    ]
  }
}
