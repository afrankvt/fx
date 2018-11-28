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

  Void testSubComp2()
  {
    // test parent with multiple subcomps

    c := build("""comp Parent {
                    template {
                      <div>
                        <h1>Heading</h1>
                        <Sub/>
                        <Sub/>
                        <Sub/>
                      </div>
                    }
                  }
                  comp Sub { template { <p>Child</p> }}""")

    e1 := render(c, [:])
    verifyEq(e1.children.size, 4)
    verifyElem(e1.children[0], "h1", "Heading")
    verifyElem(e1.children[1], "p",  "Child")
    verifyElem(e1.children[2], "p",  "Child")
    verifyElem(e1.children[3], "p",  "Child")
  }

  Void testSubComp3()
  {
    // test extern bindings with sub comps

    c := build("""comp Foo {
                    data { Str[] zones }
                    template {
                      <div>
                        [for zone in zones]
                          <Zone &name="zone" />
                        [/for]
                      </div>
                    }
                    Void onUpdate(FxMsg m)
                    {
                      zones.add("Alpha")
                      zones.add("Beat")
                      zones.add("Gamma")
                    }
                  }
                  comp Zone {
                    data { extern Str name }
                    template { <p>Zone {name}</p> }
                  }""")

    c.send("init")
    e1 := render(c, [:])
dumpElem(e1)
  }
}