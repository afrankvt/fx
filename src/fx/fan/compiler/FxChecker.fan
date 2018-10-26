//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   24 Oct 2018  Andy Frank  Creation
//

**
** FxChecker validates a FxAst tree.
**
class FxChecker
{
  ** Constructor.
  new make(FxDef[] defs)
  {
    this.defs = defs
  }

  ** Run checker on nodes.
  Void run()
  {
    defs.each |d|
    {
      if (d is FxCompDef)
      {
        f := ((FxCompDef)d).funcs.find |f| { f.funcName == "onUpdate" }
        if (f != null && !f.isUpdate)
          throw err(d, "Invalid onUpdate signature != 'Void onUpdate(FxMsg)'")
      }
    }
  }

  ** Create error to indicate validation failed.
  private Err err(FxDef def, Str msg)
  {
    Str? name
    if (def is FxStructDef) name = def->name
    if (def is FxCompDef)   name = def->name

    // TODO: include source path for node def: /x/y/y/Foo.fx(x,y): msg
    return Err(name==null ? msg : "${name}: $msg")
  }

  private FxDef[] defs
}