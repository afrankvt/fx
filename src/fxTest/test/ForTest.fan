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
    verifySame(e1, e2)
    verifyEq(e2.children.size, 1)
    verifyElem(e2.children[0], "li", "1")

    e3 := render(c, ["list":[1,8,25]])
    verifySame(e2, e3)
    verifyEq(e3.children.size, 3)
    verifyElem(e3.children[0], "li", "1")
    verifyElem(e3.children[1], "li", "8")
    verifyElem(e3.children[2], "li", "25")

    e4 := render(c, ["list":[1,8]])
    verifySame(e3, e4)
    verifyEq(e4.children.size, 2)
    verifyElem(e4.children[0], "li", "1")
    verifyElem(e4.children[1], "li", "8")
  }

  Void testFor2()
  {
    // test [for] with [if] conditionals

    c := build("""struct Item {
                    Str name
                    Bool flag
                  }
                  comp Foo {
                    data { Item[] items }
                    template {
                      <ul>
                      [for item in items]
                        <li>
                          {item.name}
                          [if item.flag]<span>Flag</span>[/if]
                        </li>
                      [/for]
                      </ul>
                    }
                    Void onUpdate(FxMsg msg)
                    {
                      if (msg.name == "init")
                      {
                        items.add(Item { it.name="Item #1" })
                        items.add(Item { it.name="Item #2" })
                        items.add(Item { it.name="Item #3" })
                        items.add(Item { it.name="Item #4" })
                        items.add(Item { it.name="Item #5" })
                      }
                      if (msg.name == "flag")
                      {
                        Int i := msg->index
                        items[i].flag = !items[i].flag
                      }
                    }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.children.size, 0)

    c.send("init")
    e2 := render(c, [:])
    verifySame(e1, e2)
    verifyEq(e2.children.size, 5)
    verifyEq(e2.children[0].tagName, "li")
    verifyEq(e2.children[0].children.size, 1)
    verifyEq(e2.children[0].children[0].text, "Item #1")
    verifyEq(e2.children[2].tagName, "li")
    verifyEq(e2.children[2].children.size, 1)
    verifyEq(e2.children[2].children[0].text, "Item #3")
    verifyEq(e2.children[4].tagName, "li")
    verifyEq(e2.children[4].children.size, 1)
    verifyEq(e2.children[4].children[0].text, "Item #5")

    c.send("flag", ["index":2])
    e3 := render(c, [:])
    verifySame(e2, e3)
    verifyEq(e2.children.size, 5)
    verifyEq(e2.children[0].tagName, "li")
    verifyEq(e2.children[0].children.size, 1)
    verifyEq(e2.children[0].children[0].text, "Item #1")
    verifyEq(e2.children[2].tagName, "li")
    verifyEq(e2.children[2].children.size, 2)
    verifyEq(e2.children[2].children[0].text, "Item #3")
    verifyEq(e2.children[4].tagName, "li")
    verifyEq(e2.children[4].children.size, 1)
    verifyEq(e2.children[4].children[0].text, "Item #5")

    c.send("flag", ["index":2])
    e4 := render(c, [:])
    verifySame(e3, e4)
    verifyEq(e2.children.size, 5)
    verifyEq(e2.children[2].tagName, "li")
    verifyEq(e2.children[2].children.size, 1)
    verifyEq(e2.children[2].children[0].text, "Item #3")
  }
}