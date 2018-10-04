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
    this.update
  }

  ** TODO
  Void update()
  {
    // short-circuit if not modified
// TODO: how does this work for things like modifiying lists?
    //if (comp->__dirty == false) return

    // build var map
    data := Str:Obj?[:]
    comp.typeof.fields.each |f|
    {
      if (!f.name.startsWith("__"))
        data[f.name] = f.get(comp)
    }
    Log.get("fx").info("${comp}.update { $data }")

    // compile/render template
    template := Mustache(comp->__template.toStr.in)
    html := template.render(data)

    // TODO: best way todo this?
    // create frag
    frag := Elem("div") { it.html=html }

    // TODO: ???
    // bind event handlers
    frag.querySelectorAll("[fx-click]").each |e|
    {
      e.onEvent("click", false)
      {
        val := e.attr("fx-click")
        comp->__update(val)
        this.update
      }
    }

    // TODO: createFrag won't work here
    // update dom
    this.removeAll
    frag.children.each |e| { frag.remove(e); this.add(e) }
    comp->__dirty = false
  }

  override Str toStr()
  {
    "FxComp { comp=$comp hash=$this.hash }"
  }

  private Type? type   // comp type
  private Obj? comp    // comp instance
}