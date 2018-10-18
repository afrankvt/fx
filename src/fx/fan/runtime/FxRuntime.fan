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
@NoDoc @Js class FxRuntime
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
    comps.each |FxElem c| { c.mount; c.render; c.init }
    // echo(comps)

    dur := (Duration.now - ts).toMillis
    log.info("FxRuntime booted ($comps.size comps, ${dur}ms)")
  }

  ** Create a new FX element dom node.
  static Elem elem(Obj parentComp, Str qname, Str:Str attrs)
  {
    elem := FxElem { it.setAttr("fx-comp", qname) }
    elem.mount
    elem.comp.__parent = parentComp
    attrs.each |v,n| { elem.setAttr(n, v) }
    // attrs.each |v,n|
    // {
    //   if (n.startsWith("fx-bind"))
    //   {
    //     self  := n["fx-bind:".size..-1]
    //     field := elem.comp.typeof.field("__extern_${self}")
    //     field.set(elem.comp, parentComp.trap(v))
    //   }
    // }
    elem.render
    return elem
  }

  ** Dump struct field and values to Str.
  static Str structToStr(Obj struct)
  {
    buf := StrBuf()
    buf.add(struct.typeof.qname).add(" {")
    struct.typeof.fields.each |f|
    {
      if (!f.name.startsWith("__"))
        buf.add(f.name).addChar('=').add(f.get(struct) ?: "")
    }
    buf.add(" }")
    return buf.toStr
  }

  ** Fx log instance.
  static const Log log := Log.get("fx")
}