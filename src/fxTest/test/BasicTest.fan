//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   26 Nov 2018  Andy Frank  Creation
//

using dom
using fx

class BasicTest : Test
{
  Void testBasic1()
  {
    c := build("comp Foo { template { <div></div> } }")
    e := render(c, [:])
    verifyEq(e.tagName, "div")
  }

  Void testBasic2()
  {
    c := build("comp Foo { template { <h1></h1> } }")
    e := render(c, [:])
    verifyEq(e.tagName, "h1")
  }

  Void testBasic3()
  {
    c := build("comp Foo { template { <div><span>Hello, World</span></div> } }")
    e := render(c, [:])
    verifyEq(e.tagName, "div")
    verifyEq(e.children.size, 1)
    verifyEq(e.children[0].tagName, "span")
    // verifyEq(e.children[0].text,    "Hello, World")
  }

  private FxComp build(Str src)
  {
    // compile
    t := BuildFxScript.build(src, tempDir)

    // init
    elem := Elem("div")
    body := Elem("div") { it.add(elem) }

    comp := (FxComp)t.make
    comp->__elem = elem
    comp->__render

    // TODO
    //msg := comp.__init
    //if (msg != null) comp.send(msg)

    return comp
  }

  private Elem render(FxComp comp, Str:Obj? data)
  {
    // TODO: data setters
    return comp->__elem
  }
}