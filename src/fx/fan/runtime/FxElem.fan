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
//    Log.get("fx").info("${comp}.update { $data }")

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
        this.children.each |k| { this.pullForms(k) }
        this.comp->__update(val)
        this.update
      }
    }

    child.children.each |k| { bindEvents(k) }
  }

  //
  //
  // TODO: terminology here: what are {{foo}} called?; 'render'?
  //
  // Is {{foo}} a macro???  what do other toolkits called them?
  // Mustache usees "tag" which is prob not a good term for us...?
  //
  //

  ** Walk elements updating templates.
  private Void render(Elem child, Str:Obj data)
  {
    // stop if we reach a sub-comp
//    if (child.attr("fx-comp") != null) return
// TODO!!!!
isComp := child.attr("fx-comp") != null

    forloop := child.attr("fx-for")
    if (forloop != null)
    {
      // TODO: yikes
      p := forloop.split(' ')
      var  := p[0]
      prop := p[2]
      parent := child.parent

      // TODO: yikes
      Str? ivar := null
      if (var[0] == '(')
      {
        p = var[1..-2].split(',')
        var  = p[0]
        ivar = p[1]
      }

      // super primitive to get basic list looping working...
      List list := data[prop]
      if (list.isEmpty)
      {
        // remove template if list is emty
        parent.remove(child)
      }
      else
      {
        list.each |item,i|
        {
          data[var] = item
          if (ivar != null) data[ivar] = i

          clone := child.clone
          clone.removeAttr("fx-for")
          clone.children.each |k| { render(k, data) }

          if (i == 0) parent.replace(child, clone)
          else parent.add(clone)
        }
      }
      return
    }

    // check for fx-if conditionals
    attrs := child.attrs.keys
    for (i:=0; i<attrs.size; i++)
    {
      attr := attrs[i]
      if (!attr.startsWith("fx-if")) continue

      // node level
      if (child.attr("fx-if") != null)
      {
        var := child.attr("fx-if")
        val := data[var]
        if (!isTruthy(val)) { child.parent.remove(child); return }
      }
      else
      {
        // attr level
        // TODO: not sure how this should work?
        var := child.attr(attr)
        if (attr.contains(":class:"))
        {
          cname := attr["fx-if:class:".size..-1]
          val   := resolveVar(var, data)
          child.style.toggleClass(cname, isTruthy(val))
        }
      }
    }

    // check for vars
    var := child.attr("fx-var")
    if (var != null)
    {
      val := resolveVar(var, data)
      child.text = val?.toStr ?: ""
    }

    // TODO: super hack!!!!
    x := child.attr("fx-click")
    if (x != null && x.contains("select {{index}}"))
      child.setAttr("fx-click", x.replace("{{index}}", data["index"]?.toStr ?: ""))

    // child.children.each |k| { render(k, data) }
    if (!isComp) child.children.each |k| { render(k, data) }
  }

  ** Pull form values from inputs back into data array.
  private Void pullForms(Elem elem)
  {
    // short-circut if we reach a sub-comp
    if (elem.attr("fx-comp") != null) return

    // TODO!!!
    form := elem.attr("fx-form")
    if (elem.tagName == "input" && form != null)
    {
      this.comp.__setData(form, elem->value)
    }
    else
    {
      elem.children.each |k| { pullForms(k) }
    }
  }

  ** Resolve a variable to a data value.
  private Obj? resolveVar(Str var, Str:Obj data)
  {
    path := var.split('.')
    val  := data[path.first]
    for (i:=1; i<path.size; i++)
    {
      val = val.typeof.field(path[i]).get(val)
    }
    return val
  }

  ** Is value 'truthy'
  private Bool isTruthy(Obj? val)
  {
    if (val is Bool) return val
    if (val is Str)  return ((Str)val).size > 0
    if (val != null) return true
    return false
  }

  override Str toStr()
  {
    "FxComp { comp=$comp hash=$this.hash }"
  }

  internal Type? type    // comp type
  internal FxComp? comp  // comp instance
}
