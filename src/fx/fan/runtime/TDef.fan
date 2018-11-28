//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   30 Oct 2018  Andy Frank  Creation
//

*************************************************************************
** TDef
*************************************************************************

** TDef models the runtime template AST for FxComp.
@NoDoc @Js abstract const class TDef
{
  ** Child nodes.
  const TDef[] children := TDef#.emptyList
}

*************************************************************************
** TElemDef
*************************************************************************

** ElemDef models a DOM element.
@NoDoc @Js const class TElemDef : TDef
{
  new make(|This| f)
  {
    f(this)
    this.isComp = attrs.any |a| { a.name == "fx-comp " }
  }

  const Bool isComp                 // is comp
  const Str tag                     // elem tag name
  const TBindDef[] binds   := [,]   // elem var bindings
  const TAttrDef[] attrs   := [,]   // elem attrs
  const TEventDef[] events := [,]   // elem event handlers
}

*************************************************************************
** TBindDef
*************************************************************************

@NoDoc @Js const class TBindDef : TDef
{
  new make(|This| f) { f(this) }

  const Str local   // local var name
  const Str extern  // external var name
}

*************************************************************************
** TAttrDef
*************************************************************************

@NoDoc @Js const class TAttrDef : TDef
{
  new make(|This| f) { f(this) }

  const Str name   // attr name
  const Str val    // attr value (TODO: sub AST here; children?)
  const Str? cond  // if | if-not
  const Str? expr  // cond expr to eval at runtime
}

*************************************************************************
** TEventDef
*************************************************************************

@NoDoc @Js const class TEventDef : TDef
{
  new make(|This| f) { f(this) }

  const Str name   // event name
  const Obj msg    // message to fire to FxComp.send (TODO: sub AST here; children?)
}

*************************************************************************
** TTextDef
*************************************************************************

@NoDoc @Js const class TTextDef : TDef
{
  new make(|This| f) { f(this) }

  const Str text   // text content for node
}

*************************************************************************
** ExprDef
*************************************************************************

@NoDoc @Js const class TExprDef : TDef
{
  new make(|This| f) { f(this) }

  const Str expr  // variable expression to evaluate
}

*************************************************************************
** DirDef
*************************************************************************

@NoDoc @Js const class TDirDef : TDef
{
  new make(|This| f) { f(this) }

  const Str dir    // directive name
  const Str expr   // directive expr to evalute
}