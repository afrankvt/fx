//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   23 Sep 2018  Andy Frank  Creation
//

using dom

**
** FxRuntime
**
@Js internal class FxRuntime
{
  static
  {
    // register onload handler to boot
    Win.cur.onEvent("load", false) { FxRuntime.boot }
  }

  ** Boot the FX runtime in browser.
  static Void boot()
  {
    ts := Duration.now

    comps := Win.cur.doc.querySelectorAllType("[fx-comp]", FxElem#)
    comps.each |FxElem c| { c.mount }
    echo(comps)

    dur := (Duration.now - ts).toMillis
    log.info("FxRuntime booted ($comps.size comps, ${dur}ms)")
  }

  ** Fx log instance.
  static const Log log := Log.get("fx")
}