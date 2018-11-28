//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   12 Oct 2018  Andy Frank  Creation
//

using dom

**
** Base class of Fx components.
**
@NoDoc @Js abstract class FxComp
{

//////////////////////////////////////////////////////////////////////////
// Public API
//////////////////////////////////////////////////////////////////////////

  ** Parent instance for this component, or 'null' if root.
  FxComp? parent := null

  ** Send a message to this componen.
  Void send(Str name, Str:Obj? data := [:])
  {
    __elem.children.each |k| { __pullFormVals(k) }
    this->onUpdate(FxMsg { it.name=name; it.data=data })
    FxRuntime.markDirty
  }

  ** Send a message to this component after the given internval.
// TODO: data
  Void sendLater(Str name, Duration timeout)
  {
    Win.cur.setTimeout(timeout) { send(name) }
  }

//////////////////////////////////////////////////////////////////////////
// Internal API
//////////////////////////////////////////////////////////////////////////

  protected virtual Obj? __init() { null }

  // do not define an __onMsg method so subclasses can parameterize args
  // virtual Void __onMsg(...) {}

  //protected abstract FxVdom __vdom()

  ** Template AST; CWriter will generate the __tdeff field.
  internal TDef __tdef() { this->__tdeff }

  ** Render component.
  internal Void __render()
  {
// echo("# render: $this.typeof.qname")

    // TODO: optimize static attributes and children; if set to 'const'
    // or some type of flag; we can safely skip that check at runtime

    orig    := __elem
    vtree   := TDefRender.render(__tdef, __data)
    patches := VDiff.diff(__vtree, vtree)
// echo("### __render $__data ####")
// echo("--a--")
// _dump(__vtree)
// echo("--b--")
// _dump(vtree)
    elem := VPatcher.patch(this, __elem, patches)
//Win.cur.log(elem)
    elem.setAttr("fx-comp", typeof.qname)
    if (orig != null) orig.parent.replace(orig, elem)
    this.__vtree = vtree
    this.__elem  = elem
  }

private Void _dump(VNode n)
{
  // find depth
  d := 0
  VNode? p := n.parent
  while (p != null) { d++; p=p.parent }

  x := ""
  if (n is VElem) { x = " <${((VElem)n).tag}>" }
  if (n is VText) { x = " ${((VText)n).text}" }

  echo(Str.spaces(d*2) + "${n.index}: ${n.typeof}" + x)


  n.children.each |k| { _dump(k) }
}

  ** Get data map based on current state.
  internal Str:Obj? __data()
  {
    data := Str:Obj?[:]
    typeof.fields.each |f|
    {
      if (!f.name.startsWith("__"))
        data[f.name] = f.get(this)
    }
    return data
  }

  ** Set a field value.
  internal Void __setData(Str name, Obj val)
  {
    f := typeof.field(name, false)
    if (f == null) return

    // TODO: util to coerce types...
    if (f.type == Float#) val = Float.fromStr(val)

    f.set(this, val)
  }

  ** Pull form values from inputs back into data array.
  private Void __pullFormVals(Elem elem)
  {
    // short-circut if we reach a sub-comp
    if (elem.attr("fx-comp") != null) return

    // TODO!!!
    form := elem.attr("fx-form")
    if (elem.tagName == "input" && form != null)
    {
      this.__setData(form, elem->value)
    }
    else
    {
      elem.children.each |k| { __pullFormVals(k) }
    }
  }

  ** Property setter handler.
  protected Obj? __setter(Obj? oldval, Obj? newval)
  {
    if (oldval != newval) __dirty = true
    // TODO: list/map updates...
    return newval
  }

  ** Delegate extern getter to parent.
  protected Obj? __getExtern(Str name) { parent.typeof.field(name).get(parent) }

  ** Delegate extern setter to parent.
  protected Void __setExtern(Str name, Obj val) { parent.typeof.field(name).set(parent, val) }

  private VElem? __vtree := VDiff.nullTree  // current virtual tree
  internal Elem? __elem  := null           // current dom elem
  internal Bool __dirty  := true           // TODO: flag we need to re-render
}