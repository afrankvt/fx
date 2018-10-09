//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Sep 2018  Andy Frank  Creation
//

*************************************************************************
** FxNode
*************************************************************************

abstract const class FxNode
{
  virtual Void dump() {}
}

*************************************************************************
** FxUsingDef
*************************************************************************

const class FxUsingDef : FxNode
{
  new make(|This| f) { f(this) }

  const Str pod

  override Void dump()
  {
    echo("using $pod")
  }
}

*************************************************************************
** FxStructDef
*************************************************************************

const class FxStructDef : FxNode
{
  new make(|This| f) { f(this) }

  const Str qname
  const Str name
  const FxPropDef[] props

  override Void dump()
  {
    echo("stuct $qname")
    echo("{")
    props.each |p| { p.dump }
    echo("}")
  }
}

*************************************************************************
** FxCompDef
*************************************************************************

const class FxCompDef : FxNode
{
  new make(|This| f) { f(this) }

  const Str qname
  const Str name
  const FxDataDef data
  const FxUpdateDef update
  const FxStyleDef style
  const FxTemplateDef template

  override Void dump()
  {
    echo("comp $qname")
    echo("{")
    data.dump
    update.dump
    template.dump
    echo("}")
  }
}

*************************************************************************
** FxDataProp
*************************************************************************

const class FxPropDef : FxNode
{
  new make(|This| f) { f(this) }

  const Str type      // prop qname
  const Str name      // prop name
  const Str? defVal   // opt defVal expr

  override Void dump()
  {
    if (defVal == null)
      echo("  $type $name")
    else
      echo("  $type $name := $defVal")
  }
}

*************************************************************************
** FxDataDef
*************************************************************************

const class FxDataDef : FxNode
{
  new make(|This| f) { f(this) }

  const FxPropDef[] props := [,]

  override Void dump()
  {
    echo("  data")
    echo("  {")
    props.each |p| { Env.cur.out.print("  "); p.dump }
    echo("  }")
  }
}

*************************************************************************
** FxUpdateDef
*************************************************************************

const class FxUpdateDef : FxNode
{
  new make(|This| f) { f(this) }

  const Str argType  := "Obj?"  // arg type qname
  const Str argName  := "msg"   // arg identifier
  const Str funcBody := ""      // fantom source func body

  override Void dump()
  {
    echo("  update($argType $argName)")
    echo("  {")
    funcBody.splitLines.each |s|
    {
      t := s.trim
      if (t.size > 0) echo("    $t")
    }
    echo("  }")
  }
}

*************************************************************************
** FxStyleDef
*************************************************************************

const class FxStyleDef : FxNode
{
  new make(|This| f) { f(this) }

  ** Style CSS source.
  const Str css := ""

  override Void dump()
  {
    echo("  style")
    echo("  {")
    css.splitLines.each |s|
    {
      t := s.trim
      if (t.size > 0) echo("    $t")
    }
    echo("  }")
  }
}

*************************************************************************
** FxTemplateDef
*************************************************************************

const class FxTemplateDef : FxNode
{
  new make(|This| f) { f(this) }

  ** Template source markup.
  const Str markup := ""

  override Void dump()
  {
    echo("  template")
    echo("  {")
    markup.splitLines.each |s|
    {
      t := s.trim
      if (t.size > 0) echo("    $t")
    }
    echo("  }")
  }
}