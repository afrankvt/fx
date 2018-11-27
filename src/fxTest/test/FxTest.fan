//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   27 Nov 2018  Andy Frank  Creation
//

using dom
using fx

abstract class FxTest : Test
{
  ** Verify an element tag name and optional text
  protected Void verifyElem(Elem elem, Str tag, Str? text := null)
  {
    verifyEq(elem.tagName, tag)
    if (text != null) verifyEq(elem.children[0].text, text)
  }

  ** Compile fx source code into a FxComp instance.
  protected FxComp build(Str src)
  {
    // compile
    t := BuildFxScript.build(src, tempDir)

    // init
    elem := Elem("div")
    body := Elem("body") { it.add(elem) }

    comp := (FxComp)t.make
    comp->__elem = elem
    comp->__render

    // TODO
    //msg := comp.__init
    //if (msg != null) comp.send(msg)

    return comp
  }

  ** Re-render FxComp with given data and return resulting DOM elem.
  protected Elem render(FxComp comp, Str:Obj? data)
  {
    data.each |v,n| { comp->__setData(n,v) }
    comp->__render
    return comp->__elem
  }

  ** Print DOM tree.
  protected Void dumpElem(Elem e, Int indent := 0)
  {
    Env.cur.out
      .print(Str.spaces(indent))
      .print(e.tagName)
      .print(" ").print(e.text)
      .printLine

    e.children.each |k| { dumpElem(k, indent+2) }
  }
}