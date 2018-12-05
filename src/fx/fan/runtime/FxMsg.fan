//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   24 Oct 2018  Andy Frank  Creation
//

**
** FxMsg.
**
@Js /*const*/ class FxMsg
{
  ** Internal ctor.
  internal new make(|This| f) { f(this) }

  ** Message name.
  const Str name

// TODO: might be more trouble than its worth to pipe mutable runtime
//       data through as const objects...

  ** Message data.
  /*const*/ Str:Obj? data

  ** Convenience for 'data[key]'.
  override Obj? trap(Str name, Obj?[]? args := null)
  {
    data[name]
  }

  override Str toStr() { "$name $data" }
}