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
  }

  ** TODO
  Void update()
  {
    // short-circuit if not modified
// TODO: how does this work for things like modifiying lists?
    //if (comp->__dirty == false) return

    data := comp.__data
    Log.get("fx").info("${comp}.update { $data }")

    // TODO: holy moly how should this work
    // update dom
    this.removeAll
    comp.__elems.each |kid|
    {
      this.add(kid)
      render(kid, data)
    }

    // TODO -- not sure how this works; but as things stand
    // this should prob go into `render()`??
    // bind events
    children.each |kid| { bindEvents(kid) }

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

  // TODO: terminology here: what are {{foo}} called?; 'render'?

  ** Walk elements updating templates.
  private Void render(Elem child, Str:Obj data)
  {
    // stop if we reach a sub-comp
    if (child.attr("fx-comp") != null) return

    forloop := child.attr("fx-for")
    if (forloop != null)
    {
      // TODO: yikes
      p := forloop.split(' ')
      var  := p[0]
      prop := p[2]
      parent := child.parent

      // super primitive to get basic list looping working...
      (data[prop] as List).each |item,i|
      {
        data[var] = item

        clone := child.clone
        clone.removeAttr("fx-for")
        clone.children.each |k| { render(k, data) }

        if (i == 0) parent.replace(child, clone)
        else parent.add(clone)
      }
    }
    else
    {
      var := child.attr("fx-var")
      if (var != null)
      {
        path := var.split('.')
        val  := data[path.first]
        for (i:=1; i<path.size; i++)
        {
          val = val.typeof.field(path[i]).get(val)
        }
        child.text = val?.toStr ?: ""
      }
      child.children.each |k| { render(k, data) }
    }
  }

  override Str toStr()
  {
    "FxComp { comp=$comp hash=$this.hash }"
  }

  internal Type? type    // comp type
  internal FxComp? comp  // comp instance
}
