//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   26 Nov 2018  Andy Frank  Creation
//

using compiler
using concurrent

// TODO: used for `fxTest` unit tests for now; not sure
//       if value beyond that...

**
** BuildFxScript
**
@NoDoc class BuildFxScript
{
  private static const AtomicInt index := AtomicInt(0)

  static Type build(Str src, File dir)
  {
    ix  := index.getAndIncrement
    pod := "script${ix}"
    ast := CParser(pod, "script${ix}.fx", Buf().print(src).flip.in).parse
    CChecker(ast).run

    fan := dir + `script${ix}.fan`
    out := fan.out
    CWriter(pod, ast).write(out)
    out.sync.close

    type := Env.cur.compileScript(fan)
    FxRuntime.cur.testPod = type.pod
    return type.pod.types.find |t| { t.fits(FxComp#) }
  }
}