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

  ** Send a message to this componen.
  Void send(Str name, Str:Obj? data := [:])
  {
    __elem.children.each |k| { __pullFormVals(k) }
    this->onUpdate(FxMsg { it.name=name; it.data=data })
    __elem?.render

    // TODO: huuuuge hack; but update parents for now until we
    // sort out how to fire off extern bound data props
    p := __elem?.parent
    while (p != null)
    {
      if (p is FxElem) ((FxElem)p).render
      p = p.parent
    }
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

  ** Delegate extern getter to parent.
  protected Obj? __getExtern(Str name) { __parent.typeof.field(name).get(__parent) }

  ** Delegate extern setter to parent.
  protected Void __setExtern(Str name, Obj val) { __parent.typeof.field(name).set(__parent, val) }

  internal FxComp? __parent := null   // parent instance for sub-comps
  internal FxElem? __elem   := null   // bound FxElem instance
  protected Str:Str __externs := [:]  // self:parent extern field name map
  protected Bool __dirty := false     // TODO
}