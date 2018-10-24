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
  new make(FxNode[] nodes)
  {
    this.nodes = nodes
  }

  ** Run checker on nodes.
  Void run()
  {
    nodes.each |n|
    {
      if (n is FxCompDef)
      {
        f := ((FxCompDef)n).funcs.find |f| { f.funcName == "onUpdate" }
        if (f != null && !f.isUpdate)
          throw err(n, "Invalid onUpdate signature != 'Void onUpdate(FxMsg)'")
      }
    }
  }

  ** Create error to indicate validation failed.
  private Err err(FxNode node, Str msg)
  {
    Str? name
    if (node is FxStructDef) name = node->name
    if (node is FxCompDef)   name = node->name

    // TODO: include source path for node def: /x/y/y/Foo.fx(x,y): msg
    return Err(name==null ? msg : "${name}: $msg")
  }

  private FxNode[] nodes
}