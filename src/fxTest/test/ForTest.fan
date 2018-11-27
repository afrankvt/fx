//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   27 Nov 2018  Andy Frank  Creation
//

using dom
using fx

class ForTest : FxTest
{
  Void testFor1()
  {
    // test simple [for]

    c := build("""comp Foo {
                    data { Int[] list }
                    template {
                      <ul>
                      [for x in list]
                        <li>{x}</li>
                      [/for]
                      </ul>
                    }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.children.size, 0)

    e2 := render(c, ["list":[1]])
    verifyEq(e2.children.size, 1)
    verifyElem(e2.children[0], "li", "1")

    e3 := render(c, ["list":[1,8,25]])
    verifyEq(e2.children.size, 3)
    verifyElem(e2.children[0], "li", "1")
    verifyElem(e2.children[1], "li", "8")
    verifyElem(e2.children[2], "li", "25")
  }
}