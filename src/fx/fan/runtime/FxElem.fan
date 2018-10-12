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
    this.addAll(comp->__elems)
    children.each |kid| { bindEvents(kid) }
  }

  ** TODO
  Void update()
  {
    // short-circuit if not modified
// TODO: how does this work for things like modifiying lists?
    //if (comp->__dirty == false) return

    data := comp.__data
    Log.get("fx").info("${comp}.update { $data }")

    // update dom
    this.querySelectorAll("[fx-var]").each |e|
    {
      name := e.attr("fx-var")
      val  := data[name]
      e.text = val?.toStr ?: ""
    }

    // TODO: do we need to re-bind event handlers here?

    // mark clean
    comp->__dirty = false

    // TODO: huuuuge hack; but update parents for now until we
    // sort out how to fire off extern bound data props
    p := parent
    while (p != null)
    {
      if (p is FxElem) ((FxElem)p).update
      p = p.parent
    }
  }

  ** Walk element and bind event handlers.
  private Void bindEvents(Elem child)
  {
    // stop if we reach a sub-comp
    if (child.attr("fx-comp") != null) return

    // TODO
    val := child.attr("fx-click")
    if (val != null)
    {
      child.onEvent("click", false)
      {
        this.comp->__update(val)
        this.update
      }
    }

    child.children.each |k| { bindEvents(k) }
  }

  override Str toStr()
  {
    "FxComp { comp=$comp hash=$this.hash }"
  }

  internal Type? type    // comp type
  internal FxComp? comp  // comp instance
}
