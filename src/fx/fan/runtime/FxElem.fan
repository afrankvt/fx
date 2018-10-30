//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   23 Sep 2018  Andy Frank  Creation
//

using dom

**
** FxElem
**
@Js internal class FxElem : Elem
{
  ** Ctor.
  new make(Str tag := "div") : super.make(tag) {}

  ** Mount FxElem with component defined in 'fx-comp' attr.
  Void mount()
  {
    this.type = Type.find(this.attr("fx-comp"))
    this.comp = type.make
    this.comp.__elem = this
  }

  ** Init component if 'init' message was specified.
  Void init()
  {
    msg := this.comp.__init
    if (msg != null) this.comp.send(msg)
  }

  ** Render component based on current state.
  Void render()
  {
    // short-circuit if not modified
    // if (!comp.__dirty) return

    // re-render component
    data := comp.__data
    frag := comp.__vdom.toElem(comp, data)
    this.removeAll.add(frag)
    // comp.__dirty = false
  }

  override Str toStr()
  {
    "FxComp { comp=$comp hash=$this.hash }"
  }

  internal Type? type    // comp type
  internal FxComp? comp  // comp instance
}
