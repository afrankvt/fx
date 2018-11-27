//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   27 Nov 2018  Andy Frank  Creation
//

using dom
using fx

class IfTest : FxTest
{
  Void testIf1()
  {
    // TODO: test and support for inline text nodes:
    // [if x]Worked![/if]

    c := build("""comp Foo {
                    data { Int x }
                    template {
                      <div>
                      [if x]<span>Worked!</span>[/if]
                      </div>
                    }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.children.size, 0)

    e2 := render(c, ["x":5])
    verifyEq(e2.children.size, 1)
    verifyEq(e2.children[0].children[0].text, "Worked!")
  }
}