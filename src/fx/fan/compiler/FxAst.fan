//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Sep 2018  Andy Frank  Creation
//

*************************************************************************
** FxDef
*************************************************************************

abstract const class FxDef
{
  // TODO
  // FxLoc loc { file, line }
}

*************************************************************************
** FxUsingDef
*************************************************************************

const class FxUsingDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str pod
}

*************************************************************************
** FxStructDef
*************************************************************************

const class FxStructDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str qname
  const Str name
  const FxPropDef[] props
}

*************************************************************************
** FxCompDef
*************************************************************************

const class FxCompDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str qname
  const Str name
  const FxDataDef data
  const FxInitDef init
  const FxStyleDef style
  const FxTemplateDef template
  const FxFuncDef[] funcs
}

*************************************************************************
** FxDataProp
*************************************************************************

const class FxPropDef : FxDef
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
** FxDataDef
*************************************************************************

const class FxDataDef : FxDef
{
  new make(|This| f) { f(this) }

  const FxPropDef[] props := [,]
}

*************************************************************************
** FxInitDef
*************************************************************************

const class FxInitDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str msg := ""  // message expression

}

*************************************************************************
** FxFuncDef
*************************************************************************

const class FxFuncDef : FxDef
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
** FxStyleDef
*************************************************************************

const class FxStyleDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str css := ""
}

*************************************************************************
** FxTemplateDef
*************************************************************************

const class FxTemplateDef : FxDef
{
  new make(|This| f) { f(this) }

  const FxDef[] nodes
}

*************************************************************************
** FxDirDef
*************************************************************************

const class FxDirDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str dir
  const Str expr
  const FxDef[] kids
}

*************************************************************************
** FxNodeDef
*************************************************************************

const class FxNodeDef : FxDef
{
  new make(|This| f)
  {
    f(this)
    if (isComp) tagName = qname
  }

  const Str tagName
  const FxBindDef[] binds
  const FxAttrDef[] attrs
  const FxDef[] kids
  const Str? podName

  Bool isComp() { tagName[0].isUpper }
  Str qname() { "${podName}::${tagName}" }
}

*************************************************************************
** FxBindDef
*************************************************************************

const class FxBindDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str local   // local var name
  const Str extern  // external var name
}

*************************************************************************
** FxAttrDef
*************************************************************************

const class FxAttrDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str name  // attr name
  const Obj val   // attr value
}

*************************************************************************
** FxTextNodeDef
*************************************************************************

const class FxTextNodeDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str text   // text content for node
}

*************************************************************************
** FxVarNodeDef
*************************************************************************

const class FxVarNodeDef : FxDef
{
  new make(|This| f) { f(this) }

  const Str name  // var name for this node.
}