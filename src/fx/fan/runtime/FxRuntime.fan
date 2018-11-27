//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   23 Sep 2018  Andy Frank  Creation
//

using concurrent
using dom

**
** FxRuntime
**
@NoDoc @Js class FxRuntime
{
  ** Get runtime instance for VM.
  private static FxRuntime cur() { (curRef.val as Unsafe).val }
  private static const AtomicRef curRef := AtomicRef(null)

  // define static block after `curRef` for unit testing
  static
  {
    // for unit testing
    if (Env.cur.runtime != "js") return FxRuntime {}

    // register onload handler to boot runtime
    Win.cur.onEvent("load", false)
    {
      fx := FxRuntime {}
      fx.boot
    }
  }

  ** Mark component tree as dirty for render.
  internal static Void markDirty() { FxRuntime.cur.dirty = true }

  ** Private ctor.
  private new make()
  {
    FxRuntime.curRef.compareAndSet(null, Unsafe(this))
  }

  // TODO: how should this work
  @NoDoc static Void _mount(Elem elem)
  {
    FxRuntime.cur.mount(elem)
  }

  ** Boot runtime.
  private Void boot()
  {
    // mount top level comps
    elems := Win.cur.doc.querySelectorAll("[fx-comp]")
    elems.each |e| { mount(e) }

    // setup renderer loop
    Win.cur.reqAnimationFrame { render }
  }

  ** Mount fxcomp into runtime.
  private Void mount(Elem elem)
  {
    qname := elem.attr("fx-comp")
    comp  := (FxComp)Type.find(qname).make
    comp.__elem = elem
    comp.__render

    msg := comp.__init
    if (msg != null) comp.send(msg)

    comps.add(comp)
  }

  // TODO: some mech for unmount?

  ** Render vdom if needed.
  private Void render()
  {
    try
    {
      if (!dirty) return

      ts := Duration.now
      comps.each |c| { c.__render }

      dur := (Duration.now - ts).toMillis
      log.info("FxRuntime.render ($comps.size comps, ${dur}ms)")
    }
    finally
    {
      dirty = false
      Win.cur.reqAnimationFrame { render }
    }
  }

  ** Dump struct field and values to Str.
  static Str structToStr(Obj struct)
  {
    buf := StrBuf()
    buf.add(struct.typeof.qname).add(" {")
    struct.typeof.fields.each |f|
    {
      if (!f.name.startsWith("__"))
        buf.add(" ").add(f.name).addChar('=').add(f.get(struct) ?: "")
    }
    buf.add(" }")
    return buf.toStr
  }

  ** Fx log instance.
  static const Log log := Log.get("fx")

  private FxComp[] comps := [,]     // top-level comps
  private Bool dirty     := false   // render dirty flag
}
