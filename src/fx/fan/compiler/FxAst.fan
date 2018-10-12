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
  new make(|This| f)
  {
    f(this)

    // TODO: set defVals for non-null collection types
    if (defVal == null)
    {
      if (type.endsWith("[]")) defVal = "[,]"
      // TODO: maps
    }

    // TODO
    if (type == "Str") defVal = "\"\""
  }

  const Bool extern   // is extern (data.props only)
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

  ** Template AST.
  const FxNode[] nodes

  override Void dump()
  {
    echo("  template")
    echo("  {")
    nodes.each |n| { n.dump }
    echo("  }")
  }
}

*************************************************************************
** FxTmElemNode
*************************************************************************

const class FxTmElemNode : FxNode
{
  new make(|This| f) { f(this) }

  const Str tagName
  const Str:Str attrs
  const FxNode[] kids
  const Str? podName

  Bool isComp() { tagName[0].isUpper }
  Str qname() { "${podName}::${tagName}" }

  override Void dump()
  {
    buf := StrBuf()
    buf.add("<${tagName}")
    attrs.each |v,n| { buf.add(" ${n}=\"${v}\"") }
    buf.add(">")
    echo("${buf.toStr}")
    kids.each |k| { k.dump }  // TODO: indent
    echo("</${tagName}>")
  }
}

*************************************************************************
** FxTmTextNode
*************************************************************************

const class FxTmTextNode : FxNode
{
  new make(|This| f) { f(this) }

  ** Text content for node.
  const Str text

  override Void dump() { echo(text) }
}

*************************************************************************
** FxTmTextNode
*************************************************************************

const class FxTmVarNode : FxNode
{
  new make(|This| f) { f(this) }

  ** Var name for this node.
  const Str name

  override Void dump() { echo("{{$name}}") }
}