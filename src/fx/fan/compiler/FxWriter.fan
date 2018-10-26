//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   21 Sep 2018  Andy Frank  Creation
//

**
** FxWriter
**
class FxWriter
{
  new make(Str podName, FxDef[] defs)
  {
    this.podName = podName
    this.defs    = defs
    this.usings  = defs.findType(FxUsingDef#)
    this.structs = defs.findType(FxStructDef#)
    this.comps   = defs.findType(FxCompDef#)
  }

  ** Write a new Fantom source file to 'OutStream'
  Void write(OutStream out)
  {
    // TODO: usings.unique
    out.printLine("using dom")
    out.printLine("using fx")

    usings.each  |u| { out.printLine("using $u.pod") }
    structs.each |s| { writeStruct(s, out) }
    comps.each   |c| { writeComp(c, out) }
  }

  ** Write FxStructDef as a Fantom class source.
  private Void writeStruct(FxStructDef struct, OutStream out)
  {
    out.printLine("@Js class $struct.name")
    out.printLine("{")
    out.printLine("  new make(|This| f) { f(this) }")
    struct.props.each |p|
    {
      out.print("  $p.type $p.name")
      if (p.defVal != null) out.print(" := $p.defVal")
      out.printLine("")
    }
    out.printLine("  override Str toStr() { FxRuntime.structToStr(this) }")
    out.printLine("}")
  }

  ** Write FxComp as a Fantom class source.
  private Void writeComp(FxCompDef comp, OutStream out)
  {
    // comp type
    out.printLine("@Js class $comp.name : FxComp")
    out.printLine("{")

    // data
    comp.data.props.each |p|
    {
      out.print("  $p.type $p.name")
      if (p.extern)
      {
        // TODO: __dirty?
        // no-storage getter/setter
        out.printLine(" {")
        out.printLine("    get { __getExtern($p.name.toCode) }")
        out.printLine("    set { __setExtern($p.name.toCode, it) }")
        out.printLine("  }")
      }
      else
      {
        if (p.defVal != null) out.print(" := $p.defVal")
        out.printLine(" { private set { &${p.name}=it; __dirty=true }}")
      }
    }

    // style
    style := StrBuf()
    scope := "[fx-comp='$comp.qname']"
    comp.style.css.splitLines.each |line|
    {
      xline := line.trim
      if (xline.isEmpty) return
      xline.split(' ').each |s|
      {
        if (s.size == 0) return
        if (s == "&") s = scope
        else if (s[0].isUpper)
        {
          if (!s.contains("::")) s = "${podName}::${s}"
          s = "[fx-comp=\"$s\"]"
        }
        style.add(s).addChar(' ')
      }
      style.addChar('\n')
    }
    out.printLine("  static")
    out.printLine("  {")
    out.printLine("     dom::Win.cur.addStyleRules($style.toStr.toCode)")
    out.printLine("  }")

    // template
    out.printLine("  protected override const FxVdom __vdom := FxVdom { it.root = ")
    writeVnode(comp.template.nodes.first, out, 4)
    out.printLine("\n  }")

    // init
    init := comp.init.msg.trimToNull
    if (init != null)
    {
      out.printLine("  protected override Obj? __init()")
      out.printLine("  {")
      out.printLine("    return ${init}")
      out.printLine("  }")
    }

    // funcs
    comp.funcs.each |f|
    {
      args := f.funcArgs.join(", ")
      out.printLine("  ${f.retType} ${f.funcName}($args)")
      out.printLine("  {")
      f.funcBody.splitLines.each |s|
      {
        t := s.trim
        if (t.size > 0) out.printLine("    $t")
      }
      out.printLine("  }")
    }

    // end class
    out.printLine("}")
  }

  ** Write vdom.
  private Void writeVnode(FxDef node, OutStream out, Int indent)
  {
    sp := Str.spaces(indent)
    switch (node.typeof)
    {
// TODO: cleanup this code to be more readable...
      case FxNodeDef#:
        FxNodeDef e := node
        out.print(sp).printLine("FxVelem {")
        out.print(sp).printLine("  it.tag = $e.tagName.toCode")
        // don't think we need this in js
        // if (e.binds.size > 0)
        // {
        //   out.print(sp).printLine("  it.binds = [")
        //   e.binds.each |b|
        //   {
        //     writeVnode(b, out, indent+4)
        //     out.printLine(",")
        //   }
        //   out.print(sp).printLine("  ]")
        // }
        if (e.attrs.size > 0)
        {
          out.print(sp).printLine("  it.attrs = [")
          e.attrs.each |a|
          {
            writeVnode(a, out, indent+4)
            out.printLine(",")
          }
          out.print(sp).printLine("  ]")
        }
        if (e.kids.size > 0)
        {
          out.print(sp).printLine("  it.children = [")
          e.kids.each |k|
          {
            writeVnode(k, out, indent+4)
            out.printLine(",")
          }
          out.print(sp).printLine("  ]")
        }
        out.print(sp).print("}")

      // case FxBindDef#:
      //   FxBindDef b := node
      //   out.print(sp).print("FxVbind { it.local=${b.local.toCode}; it.extern=${b.extern.toCode} }")

      case FxAttrDef#:
        FxAttrDef a := node
        out.print(sp).printLine("FxVattr { ")
        out.print(sp).printLine("  it.name=${a.name.toCode}")
        out.print(sp).printLine("  it.val=${a.val.toStr.toCode}")
        out.print(sp).print("}")

      case FxDirDef#:
        FxDirDef d := node
        out.print(sp).printLine("FxVdir {")
        out.print(sp).printLine("  it.dir=${d.dir.toCode}")
        out.print(sp).printLine("  it.expr=${d.expr.toCode}")
        if (d.kids.size > 0)
        {
          out.print(sp).printLine("  it.children = [")
          d.kids.each |k|
          {
            writeVnode(k, out, indent+4)
            out.printLine(",")
          }
          out.print(sp).printLine("  ]")
        }
        out.print(sp).print("}")

      case FxTextNodeDef#:
        FxTextNodeDef t := node
        out.print(sp).print("FxVtext { it.text=${t.text.toCode} }")

      case FxVarNodeDef#:
        FxVarNodeDef v := node
        out.print(sp).print("FxVexpr { it.expr=${v.name.toCode} }")
    }
  }

  const Str podName
  const FxDef[] defs
  const FxUsingDef[] usings
  const FxStructDef[] structs
  const FxCompDef[] comps
}