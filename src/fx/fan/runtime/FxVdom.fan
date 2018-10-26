//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   25 Oct 2018  Andy Frank  Creation
//

using dom

*************************************************************************
** FxVdom
*************************************************************************

@NoDoc @Js const class FxVdom
{
  new make(|This| f) { f(this) }

  ** Convert this vdom to a DOM tree fragment.
  Elem toElem(FxComp comp, Str:Obj data)
  {
    root.toDom(comp, data).first
  }

  const FxVelem root
}

*************************************************************************
** FxVNode
*************************************************************************

@NoDoc @Js abstract const class FxVnode
{
  ** Virtual node children.
  const FxVnode[] children := [,]

  ** Convert virtual node to a DOM element.
  abstract Obj[] toDom(FxComp comp, Str:Obj data)

  ** Resolve a variable expr to a data value.
  protected Obj? resolveVar(Str expr, Str:Obj? data)
  {
    // TODO: I think we want to expect compiler to pre-validate these?
    path := expr.split('.')
    val  := data[path.first]
    for (i:=1; val != null && i<path.size; i++)
    {
      slot := val.typeof.slot(path[i], false)
      if (slot is Field) val = ((Field)slot).get(val)
      else if (slot is Method) val = ((Method)slot).call(val)
    }
    return val
  }
}

*************************************************************************
** FxVElem
*************************************************************************

@NoDoc @Js const class FxVelem : FxVnode
{
  new make(|This| f) { f(this) }
  const Str tag
  const FxVbind[] binds := [,]
  const FxVattr[] attrs := [,]
  override Obj[] toDom(FxComp comp, Str:Obj data)
  {
    if (tag.contains("::"))
    {
      // TODO FIXIT
      elem := FxElem { it.setAttr("fx-comp", tag) }
      elem.mount
      elem.comp.__parent = comp
      attrs.each |a| { elem.setAttr(a.name, a.val) }
      elem.render
      elem.init
      return [elem]
    }

    elem := Elem(tag)
    attrs.each |a|
    {
      // TODO: @<event>
      if (a.name == "fx-click")
      {
        elem.onEvent("click", false) { comp.send(a.val) }
      }
      else
      {
        elem.setAttr(a.name, a.val)
      }
    }
    children.each |k|
    {
      // TODO: need to cleanup how text nodes are handled on dom
      //       thinking maybe use a special Elem instance? then
      //       all existing APIs should work and behave the same
      //       way (I think.....)
      k.toDom(comp, data).each |x|
      {
        if (x is Elem) elem.add(x)
        else Win.cur.doc.addTextNode(elem, x)
      }
    }
    return [elem]
  }
}

*************************************************************************
** FxVbind
*************************************************************************

@NoDoc @Js const class FxVbind
{
  new make(|This| f) { f(this) }
  const Str local
  const Str extern
}

*************************************************************************
** FxVattr
*************************************************************************

@NoDoc @Js const class FxVattr
{
  new make(|This| f) { f(this) }
  const Str name
  const Obj val
}

*************************************************************************
** FxVtext
*************************************************************************

@NoDoc @Js const class FxVtext : FxVnode
{
  new make(|This| f) { f(this) }
  const Str text
  override Obj[] toDom(FxComp comp, Str:Obj data) { [text] }
}

*************************************************************************
** FxVexpr
*************************************************************************

@NoDoc @Js const class FxVexpr : FxVnode
{
  new make(|This| f) { f(this) }
  const Str expr
  override Obj[] toDom(FxComp comp, Str:Obj data)
  {
    [resolveVar(expr, data)?.toStr ?: ""]
  }
}

*************************************************************************
** FxVexpr
*************************************************************************

@NoDoc @Js const class FxVdir : FxVnode
{
  new make(|This| f) { f(this) }

  const Str dir
  const Str expr

  override Obj[] toDom(FxComp comp, Str:Obj data)
  {
    if (dir == "if" || dir == "ifnot")
    {
      val  := data[expr]
      cond := isTruthy(val)
      if (dir == "ifnot") cond = !cond
      if (cond)
      {
        kids := Obj[,]
        children.each |k| { kids.addAll(k.toDom(comp, data)) }
        return kids
      }
      return Obj#.emptyList
    }
    else if (dir == "for")
    {
      // TODO: handle this at compile time with pre-computed info
      p := expr.split(' ')
      var  := p[0]
      prop := p[2]
      copy := data.dup

      // TODO
      Str? ivar := null
      if (var.contains(","))
      {
        p = var.split(',')
        var  = p[0]
        ivar = p[1]
      }

      kids := Obj[,]
      List list := copy[prop]
      list.each |item,i|
      {
        copy[var] = item
        if (ivar != null) copy[ivar] = i
        children.each |k| { kids.addAll(k.toDom(comp, copy)) }
      }
      return kids
    }
    return Obj#.emptyList
  }

  ** Is value 'truthy'
  private Bool isTruthy(Obj? val)
  {
    if (val is Bool) return val
    if (val is Str)  return ((Str)val).size > 0
    if (val != null) return true
    return false
  }
}

