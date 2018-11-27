//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   21 Sep 2018  Andy Frank  Creation
//

**
** CWriter
**
class CWriter
{
  new make(Str podName, CDef[] defs)
  {
    this.podName = podName
    this.defs    = defs
    this.usings  = defs.findType(CUsingDef#)
    this.structs = defs.findType(CStructDef#)
    this.comps   = defs.findType(CCompDef#)
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

  ** Write CStructDef as a Fantom class source.
  private Void writeStruct(CStructDef struct, OutStream out)
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
  private Void writeComp(CCompDef comp, OutStream out)
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
        out.printLine(" { private set { &${p.name}=__setter(&${p.name}, it) }}")
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
    if (style.size > 0)
    {
      out.printLine("  static")
      out.printLine("  {")
      out.printLine("     dom::Win.cur.addStyleRules($style.toStr.toCode)")
      out.printLine("  }")
    }

    // template
    if (comp.template.nodes.size > 0)
    {
      out.printLine("  private const TElemDef __tdeff := ")
      writeTDef(comp.template.nodes.first, out, 4)
      out.printLine("")
    }

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

  ** Write template def tree.
  private Void writeTDef(CDef def, OutStream out, Int indent)
  {
    sp := Str.spaces(indent)
    switch (def.typeof)
    {
      case CTElemDef#:
        CTElemDef e := def
        out.print(sp).printLine("TElemDef {")
        out.print(sp).printLine("  it.tag = $e.tagName.toCode")
        writeTDefList("attrs",    e.attrs,    out, indent+2)
        writeTDefList("events",   e.events,   out, indent+2)
        writeTDefList("children", e.children, out, indent+2)
        out.print(sp).print("}")

      case CTAttrDef#:
        CTAttrDef a := def
        out.print(sp).printLine("TAttrDef { ")
        out.print(sp).printLine("  it.name=${a.name.toCode}")
        out.print(sp).printLine("  it.val=${a.val.toStr.toCode}")
        if (a.cond != null)
        {
          out.print(sp).printLine("  it.cond=${a.cond.toCode}")
          out.print(sp).printLine("  it.expr=${a.expr.toCode}")
        }
        out.print(sp).print("}")

      case CTEventDef#:
        CTEventDef e := def
        out.print(sp).printLine("TEventDef { ")
        out.print(sp).printLine("  it.name=${e.event.toCode}")
        out.print(sp).printLine("  it.msg=${e.msg.toStr.toCode}")
        out.print(sp).print("}")

      case CTTextDef#:
        CTTextDef t := def
        out.print(sp).print("TTextDef { it.text=${t.text.toCode} }")

      case CTVarDef#:
        CTVarDef v := def
        out.print(sp).print("TExprDef { it.expr=${v.name.toCode} }")

      case CTDirDef#:
        CTDirDef d := def
        out.print(sp).printLine("TDirDef {")
        out.print(sp).printLine("  it.dir=${d.dir.toCode}")
        out.print(sp).printLine("  it.expr=${d.expr.toCode}")
        writeTDefList("children", d.children, out, indent+2)
        out.print(sp).print("}")

      default: throw Err("Invalid CDef '$def.typeof'")
    }
  }

  private Void writeTDefList(Str field, CDef[] defs, OutStream out, Int indent)
  {
    if (defs.size == 0) return
    sp := Str.spaces(indent)
    out.print(sp).printLine("it.${field} = [")
    defs.each |d|
    {
      writeTDef(d, out, indent+2)
      out.printLine(",")
    }
    out.print(sp).printLine("]")
  }

  const Str podName
  const CDef[] defs
  const CUsingDef[] usings
  const CStructDef[] structs
  const CCompDef[] comps
}