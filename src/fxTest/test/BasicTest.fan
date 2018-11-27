//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   26 Nov 2018  Andy Frank  Creation
//

using dom
using fx

class BasicTest : FxTest
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
    // TODO: fix upstream text nodes...
    // verifyEq(e.children[0].text,    "Hello, World")
  }

  Void testBasic4()
  {
    c := build("""comp Foo {
                    data { Int x }
                    template { <div>{x}</div> }
                  }""")
    e1 := render(c, [:])
    verifyEq(e1.tagName, "div")
    // TODO: fix upstream text nodes...
    verifyEq(e1.children[0].text, "0")

    e2 := render(c, ["x":1])
    // TODO: fix upstream text nodes...
    verifyEq(e2.children[0].text, "1")

    e3 := render(c, ["x":52])
    // TODO: fix upstream text nodes...
    verifyEq(e3.children[0].text, "52")
  }
}