//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   30 Oct 2018  Andy Frank  Creation
//

*************************************************************************
** VNode
*************************************************************************

** VNode models a DOM node in the virtual DOM
@Js const abstract class VNode
{
  ** Parent node of this node, or 'null' for root.
  const VNode? parent := null

  ** Index of node in parent, or 'null' for root.
  const Int? index := null

  ** Child nodes.
  const VNode[] children := VNode#.emptyList
}

*************************************************************************
** VElem
*************************************************************************

@Js const class VElem : VNode
{
  new make(|This| f)
  {
    f(this)
    comp := attrs.find |a| { a.name == "fx-comp" }
    this.qname = comp?.val
  }

  Bool isComp() { qname != null }

  const Str? qname        // comp type qname
  const Str tag           // tag name
  const VAttr[] attrs     // attributes
  const VEvent[] events   // event bindings
}

*************************************************************************
** VText
*************************************************************************

@Js const class VText : VNode
{
  new make(|This| f) { f(this) }
  const Str text
}

*************************************************************************
** VAttr
*************************************************************************

@Js const class VAttr : VNode
{
  new make(|This| f) { f(this) }
  const Str name   // attr name
  const Str val    // attr value
}

*************************************************************************
** VEvent
*************************************************************************

@Js const class VEvent : VNode
{
  new make(|This| f) { f(this) }
  const Str name       // event name
  const Obj msg        // event message
  const Str:Obj? data  // event data
}