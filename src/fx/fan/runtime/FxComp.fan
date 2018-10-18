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
  protected virtual Obj? __init() { null }

  protected Void update(Obj? msg, Duration? timeout := null)
  {
    if (timeout == null)
    {
      this->__update(msg)
      __elem?.render
    }
    else
    {
      Win.cur.setTimeout(timeout) { update(msg, null) }
    }
  }

  // do not define an _update method so subclasses can parameterize args
  // virtual Void __update(...) {}

  protected virtual Elem[] __elems() { Elem#.emptyList }

  ** Get data map based on current state.
  internal Str:Obj __data()
  {
    data := Str:Obj[:]
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

  ** Delegate extern getter to parent.
  protected Obj? __getExtern(Str name) { __parent.typeof.field(name).get(__parent) }

  ** Delegate extern setter to parent.
  protected Void __setExtern(Str name, Obj val) { __parent.typeof.field(name).set(__parent, val) }

  internal FxComp? __parent := null   // parent instance for sub-comps
  internal FxElem? __elem   := null   // bound FxElem instance
  protected Str:Str __externs := [:]  // self:parent extern field name map
  protected Bool __dirty := false     // TODO
}