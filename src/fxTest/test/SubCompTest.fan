//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   28 Nov 2018  Andy Frank  Creation
//

using dom
using fx

class SubCompTest : FxTest
{
  Void testSubComp1()
  {
    // test simple sub comp use

    // TODO: prevent <Sub /> from being root element!
    //c := build("""comp Parent { template { <Sub /> }}
    //              comp Sub { template { <div>Child</div> }}""")

    c := build("""comp Parent { template { <div><Sub/></div> }}
                  comp Sub { template { <p>Child</p> }}""")

    e1 := render(c, [:])
    verifyEq(e1.tagName, "div")
    verifyElem(e1.firstChild, "p", "Child")
  }
}