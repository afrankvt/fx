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

    // style
    style := StrBuf()
    scope := "[fx-comp='$comp.qname']"
    comp.style.css.splitLines.each |line|
    {
      s := line.trim
      if (s.size > 0) style.add(s.replace("&", scope)).addChar('\n')
    }
    out.printLine("  static")
    out.printLine("  {")
    out.printLine("     dom::Win.cur.addStyleRules($style.toStr.toCode)")
    out.printLine("  }")

    // template
    out.printLine("  private Elem[] __elems()")
    out.printLine("  {")
    out.printLine("    return [")
    comp.template.nodes.each |n| { writeTemplateElem(n, out, 6) }
    out.printLine("    ]")
    out.printLine("  }")

    // internal flags
    out.printLine("  private Bool __dirty := true")

    out.printLine("}")
  }

  ** Write FxStructDef as a Fantom class source.
  private Void writeTemplateElem(FxNode node, OutStream out, Int indent)
  {
    elem := node as FxTmElemNode
    if (elem != null)
    {
      if (elem.isComp)
      {
        out.print("${Str.spaces(indent)}")
        out.printLine("FxRuntime.elem(${elem.qname.toCode}),")
        return
      }

      out.printLine("${Str.spaces(indent)}Elem(\"$elem.tagName\") {")
      elem.attrs.each |v,n| { out.printLine("${Str.spaces(indent)}  it.setAttr($n.toCode, $v.toCode)") }
      elem.kids.each |n| { writeTemplateElem(n, out, indent+2) }
      out.printLine("${Str.spaces(indent)}},")
      return
    }

    text := node as FxTmTextNode
    if (text != null)
    {
      out.printLine("${Str.spaces(indent)}Elem(\"span\") {")
      out.printLine("${Str.spaces(indent)}  it.text=${text.text.toCode}")
      out.printLine("${Str.spaces(indent)}},")
      return
    }

    var := node as FxTmVarNode
    if (var != null)
    {
      out.print("${Str.spaces(indent)}")
      out.printLine("Elem(\"span\") { it.setAttr(\"fx-var\", \"$var.name\") },")
    }
  }

  const FxNode[] nodes
  const FxUsingDef[] usings
  const FxStructDef[] structs
  const FxCompDef[] comps
}