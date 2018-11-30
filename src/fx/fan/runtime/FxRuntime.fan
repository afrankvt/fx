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
// TODO: static or cur access??????
  @NoDoc static FxRuntime cur() { (curRef.val as Unsafe).val }
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

  ** Boot runtime.
  private Void boot()
  {
    // mount top level comps
    elems := Win.cur.doc.querySelectorAll("[fx-comp]")
    elems.each |e| { mount(e) }

    // make sure we do an inital render
    markDirty

    // setup renderer loop
    Win.cur.reqAnimationFrame { render }
  }

  internal FxComp elemToComp(Elem elem)
  {
    qname := elem.attr("fx-comp")
    type  := testPod==null
      ? Type.find(qname)
      : testPod.type(qname[qname.index("::")+2..-1])
    return type.make
  }

  ** Mount fxcomp into runtime.
  internal Void mount(Elem elem)
  {
    qname := elem.attr("fx-comp")
    type  := testPod==null
      ? Type.find(qname)
      : testPod.type(qname[qname.index("::")+2..-1])

    comp := (FxComp)type.make
    comp.__elem = elem
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
  internal Pod? testPod  := null    // used by test framework for type loading
}
