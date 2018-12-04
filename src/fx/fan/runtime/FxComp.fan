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
@Js abstract class FxComp
{

//////////////////////////////////////////////////////////////////////////
// Public API
//////////////////////////////////////////////////////////////////////////

  // TODO: not sure how this works yet
  @NoDoc static FxComp create(Str qname, Str:Obj? data := [:])
  {
    FxComp comp := Type.find(qname).make
    data.each |v,n| { comp.__setData(n, v) }
    FxRuntime.cur.addComp(comp)
    return comp
  }

  ** Parent instance for this component, or 'null' if root.
  // TODO: ???
  @NoDoc FxComp? parent := null

  ** Send a message to this componen.
  Void send(Str name, Str:Obj? data := [:])
  {
    __elem.children.each |k| { __pullFormVals(k) }
    this->onUpdate(FxMsg { it.name=name; it.data=data })
    FxRuntime.markDirty
  }

  ** Send a message to this component after the given internval.
// TODO: data
// sendLater(Duration timeout, Str name, Str:Obj? data := [:]) ??
  Void sendLater(Str name, Duration timeout)
  {
    Win.cur.setTimeout(timeout) { send(name) }
  }

//////////////////////////////////////////////////////////////////////////
// Internal API
//////////////////////////////////////////////////////////////////////////

  protected virtual Obj? __init() { null }

  ** Template AST; CWriter will generate the __tdeff field.
  internal TDef __tdef() { this->__tdeff }

  ** Render component.
  internal Void __render()
  {
    // check if we need init
    if (!hasInit)
    {
      hasInit = true
      msg := __init
      if (msg != null) send(msg)
    }

    // TODO: optimize static attributes and children; if set to 'const'
    // or some type of flag; we can safely skip that check at runtime

    orig    := __elem
    vtree   := TDefRender.render(__tdef, __data)
    patches := VDiff.diff(__vtree, vtree)
    elem    := VPatcher.patch(this, __elem, patches)

    elem.setAttr("fx-comp", typeof.qname)
    elem.setProp("fxComp", this)

    this.__vtree = vtree
    this.__elem  = elem

    // TODO: how should this work?
    elem.querySelectorAll("[fx-comp]").each |kid|
    {
      sub := kid.prop("fxComp") as FxComp
      sub.__render
      kid.parent.replace(kid, sub.__elem)
    }

    if (orig.parent != elem.parent) orig.parent.replace(orig, elem)
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
  protected Obj? __getExtern(Str local) { (__externs[local] as Unsafe).val }

  ** Delegate extern setter to parent.
  protected Void __setExtern(Str name, Obj val) { parent.typeof.field(name).set(parent, val) }

  private Bool hasInit    := false           // has init been called yet
  private VElem? __vtree  := VDiff.nullTree  // current virtual tree
  internal Elem? __elem   := Elem {}         // current dom elem
  internal Map? __externs := null            // local:extern name mapping
  internal Bool __dirty   := true            // TODO: flag we need to re-render
}