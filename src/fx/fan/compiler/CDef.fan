//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Sep 2018  Andy Frank  Creation
//

*************************************************************************
** CDef
*************************************************************************

abstract const class CDef
{
  // TODO
  // FxLoc loc { file, line }
}

*************************************************************************
** CUsingDef
*************************************************************************

const class CUsingDef : CDef
{
  new make(|This| f) { f(this) }

  const Str pod
}

*************************************************************************
** CStructDef
*************************************************************************

const class CStructDef : CDef
{
  new make(|This| f) { f(this) }

  const Str qname
  const Str name
  const CPropDef[] props
}

*************************************************************************
** CCompDef
*************************************************************************

const class CCompDef : CDef
{
  new make(|This| f) { f(this) }

  const Str qname
  const Str name
  const CDataDef data
  const CInitDef init
  const CStyleDef style
  const CTemplateDef template
  const CFuncDef[] funcs
}

*************************************************************************
** FxDataProp
*************************************************************************

const class CPropDef : CDef
{
  new make(|This| f)
  {
    f(this)

    // TODO: set defVals for non-null collection types
    if (defVal == null)
    {
      if (type.endsWith("[]")) defVal = "[,]"
      // TODO: maps
      if (type == "Str") defVal = "\"\""
    }
  }

  const Bool extern   // is extern (data.props only)
  const Str type      // prop qname
  const Str name      // prop name
  const Str? defVal   // opt defVal expr
}

*************************************************************************
** CDataDef
*************************************************************************

const class CDataDef : CDef
{
  new make(|This| f) { f(this) }

  const CPropDef[] props := [,]
}

*************************************************************************
** CInitDef
*************************************************************************

const class CInitDef : CDef
{
  new make(|This| f) { f(this) }

  const Str msg := ""  // message expression

}

*************************************************************************
** CFuncDef
*************************************************************************

const class CFuncDef : CDef
{
  new make(|This| f) { f(this) }

  const Str retType      // return type
  const Str funcName     // function name
  const Str[] funcArgs   // function args ["Type argname", ...]
  const Str funcBody     // fantom source func body

  Bool isUpdate()
  {
    retType == "Void"
      && funcArgs.size == 1
      && funcArgs.first.split(' ').first == "FxMsg"
  }
}

*************************************************************************
** CStyleDef
*************************************************************************

const class CStyleDef : CDef
{
  new make(|This| f) { f(this) }

  const Str css := ""
}

*************************************************************************
** CTemplateDef
*************************************************************************

const class CTemplateDef : CDef
{
  new make(|This| f) { f(this) }

  const CDef[] nodes := CDef#.emptyList
}

*************************************************************************
** CTDirDef
*************************************************************************

const class CTDirDef : CDef
{
  new make(|This| f) { f(this) }

  const Str dir
  const Str expr
  const CDef[] children
}

*************************************************************************
** CTElemDef
*************************************************************************

const class CTElemDef : CDef
{
  new make(|This| f)
  {
    f(this)
    if (isComp) tagName = qname
  }

  const Str tagName
  const CTBindDef[] binds
  const CTAttrDef[] attrs
  const CTEventDef[] events
  const CDef[] children
  const Str? podName

  Bool isComp() { tagName[0].isUpper }
  Str qname() { "${podName}::${tagName}" }
}

*************************************************************************
** CTBindDef
*************************************************************************

const class CTBindDef : CDef
{
  new make(|This| f) { f(this) }

  const Str local   // local var name
  const Str extern  // external var name
}

*************************************************************************
** CTAttrDef
*************************************************************************

const class CTAttrDef : CDef
{
  new make(|This| f) { f(this) }

  const Str name   // attr name
  const Obj val    // attr value
  const Str? cond  // if | if-not
  const Str? expr  // cond expr to eval at runtime
}

*************************************************************************
** CTEventDef
*************************************************************************

const class CTEventDef : CDef
{
  new make(|This| f) { f(this) }

  const Str event   // event name
  const Obj msg     // msg to send (TODO)
}

*************************************************************************
** CTTextNodeDef
*************************************************************************

const class CTTextDef : CDef
{
  new make(|This| f) { f(this) }

  const Str text   // text content for node
}

*************************************************************************
** CTVarNodeDef
*************************************************************************

const class CTVarDef : CDef
{
  new make(|This| f) { f(this) }

  const Str name  // var name for this node.
}