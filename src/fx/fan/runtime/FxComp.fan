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
  Void sendLater(Obj msg, Duration timeout)
  {
    Win.cur.setTimeout(timeout) { send(msg) }
  }

//////////////////////////////////////////////////////////////////////////
// Internal API
//////////////////////////////////////////////////////////////////////////

  protected virtual Obj? __init() { null }

  // do not define an __onMsg method so subclasses can parameterize args
  // virtual Void __onMsg(...) {}

  protected abstract FxVdom __vdom()

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

  internal FxElem? __elem := null  // bound FxElem instance
  internal Bool __dirty   := true  // TODO: flag we need to re-render
}