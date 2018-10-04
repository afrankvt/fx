//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   21 Sep 2018  Andy Frank  Creation
//

**
** FxFanWriter
**
class FxFanWriter
{
  new make(FxNode[] nodes)
  {
    this.nodes   = nodes
    this.usings  = nodes.findType(FxUsingDef#)
    this.structs = nodes.findType(FxStructDef#)
    this.comps   = nodes.findType(FxCompDef#)
  }

  ** Write a new Fantom source file to 'OutStream'
  Void write(OutStream out)
  {
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
      // if (p.defVal != null) out.print(" := $p.defVal")
      out.printLine("")
    }
    out.printLine("}")
  }

  ** Write FxComp as a Fantom class source.
  private Void writeComp(FxCompDef comp, OutStream out)
  {
    // comp type
    out.printLine("@Js class $comp.name")
    out.printLine("{")

    // data
    comp.data.props.each |p|
    {
      out.print("  $p.type $p.name")
      if (p.defVal != null) out.print(" := $p.defVal")
      out.printLine(" { private set { &${p.name}=it; __dirty=true }}")
    }

    // update
    out.printLine("  Void __update(${comp.update.argType} ${comp.update.argName})")
    out.printLine("  {")
    comp.update.funcBody.splitLines.each |s|
    {
      t := s.trim
      if (t.size > 0) out.printLine("    $t")
    }
    out.printLine("  }")

    // TODO
    // // style
    // style := StrBuf()
    // comp.style.src.splitLines.each |line|
    // {
    //   s := line.trim
    //   if (s.size == 0) return
    //   if (s.contains("{")) style.add("[fx-comp='$comp.qname'] ")
    //   style.add(s).addChar('\n')
    // }
    // out.printLine("  static")
    // out.printLine("  {")
    // out.printLine("     dom::Win.cur.addStyleRules($style.toStr.toCode)")
    // out.printLine("  }")

    // template
    out.printLine("  Str __template := Str <|")
    indent := Str.spaces(26)
    comp.template.markup.splitLines.each |s|
    {
      t := s.trim
      if (t.size > 0) out.print(indent).printLine(t)
    }
    out.print(indent).printLine("|>")

    // internal flags
    out.printLine("  private Bool __dirty := true")

    out.printLine("}")
  }

  const FxNode[] nodes
  const FxUsingDef[] usings
  const FxStructDef[] structs
  const FxCompDef[] comps
}