//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   27 Nov 2018  Andy Frank  Creation
//

using dom
using fx

class ClassTest : FxTest
{
  Void testClass1()
  {
    // test simple class attr  setup

    c := build("""comp Foo {
                    template { <div class="foo"></div> }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.style.classes, Obj?["foo"])
  }

  Void testClass2()
  {
    // test simple multi class attr setup

    c := build("""comp Foo {
                    template { <div class="foo bar"></div> }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.style.classes, Obj?["foo", "bar"])
  }

  Void testClass3()
  {
    // test simple class attr changes

    c := build("""comp Foo {
                    data { Int x }
                    template {
                      <div if x class="foo"></div>
                    }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.style.classes, Obj?[,])

    e2 := render(c, ["x":10])
    verifySame(e1, e2)
    verifyEq(e2.style.classes, Obj?["foo"])

    e3 := render(c, ["x":0])
    verifySame(e1, e3)
    verifyEq(e2.style.classes, Obj?[,])
  }

  Void testClass4()
  {
    // test mixed class attr changes

    c := build("""comp Foo {
                    data { Int x }
                    template {
                      <div
                        class="foo"
                        if x class="bar"
                        >
                      </div>
                    }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.style.classes, Obj?["foo"])

    e2 := render(c, ["x":10])
    verifySame(e1, e2)
    verifyEq(e2.style.classes, Obj?["foo", "bar"])

    e3 := render(c, ["x":0])
    verifySame(e1, e3)
    verifyEq(e2.style.classes, Obj?["foo"])
  }

  Void testClass5()
  {
    // test mixed class attr changes (reverse static/dynamic order)

    c := build("""comp Foo {
                    data { Int x }
                    template {
                      <div
                        if x class="bar"
                        class="foo"
                        >
                      </div>
                    }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.style.classes, Obj?["foo"])

    e2 := render(c, ["x":10])
    verifySame(e1, e2)
    verifyEq(e2.style.classes, Obj?["foo", "bar"])

    e3 := render(c, ["x":0])
    verifySame(e1, e3)
    verifyEq(e2.style.classes, Obj?["foo"])
  }

  Void testClass6()
  {
    // test multiple mixed class attr changes

    c := build("""comp Foo {
                    data {
                      Int x
                      Int y
                      Int z
                    }
                    template {
                      <div
                        class="foo"
                        if x class="bar"
                        if y class="car"
                        if z class="rar"
                        >
                      </div>
                    }
                  }""")

    e1 := render(c, [:])
    verifyEq(e1.style.classes, Obj?["foo"])

    e2 := render(c, ["x":10])
    verifySame(e1, e2)
    verifyEq(e2.style.classes, Obj?["foo", "bar"])

    e3 := render(c, ["x":10, "y":1])
    verifySame(e1, e3)
    verifyEq(e3.style.classes, Obj?["foo", "bar", "car"])

    e4 := render(c, ["x":10, "y":1, "z":5])
    verifySame(e1, e4)
    verifyEq(e4.style.classes, Obj?["foo", "bar", "car", "rar"])

    e5 := render(c, ["x":10, "y":0, "z":5])
    verifySame(e4, e5)
    verifyEq(e5.style.classes, Obj?["foo", "bar", "rar"])

    e6 := render(c, ["x":0, "y":0, "z":5])
    verifySame(e4, e6)
    verifyEq(e6.style.classes, Obj?["foo", "rar"])

    e7 := render(c, ["x":0, "y":0, "z":0])
    verifySame(e1, e7)
    verifyEq(e7.style.classes, Obj?["foo"])
  }
}