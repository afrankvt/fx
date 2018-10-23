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
  new make(Str podName, FxNode[] nodes)
  {
    this.podName = podName
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
    out.printLine("  protected override Elem[] __elems()")
    out.printLine("  {")
    out.printLine("    return [")
    comp.template.nodes.each |n| { writeTemplateElem(n, out, 6) }
    out.printLine("    ]")
    out.printLine("  }")

    // init
    init := comp.init.msg.trimToNull
    if (init != null)
    {
      out.printLine("  protected override Obj? __init()")
      out.printLine("  {")
      out.printLine("    return ${init}")
      out.printLine("  }")
    }

    // onMsg
    out.printLine("  Void __onMsg(${comp.msg.argType} ${comp.msg.argName})")
    out.printLine("  {")
    comp.msg.funcBody.splitLines.each |s|
    {
      t := s.trim
      if (t.size > 0) out.printLine("    $t")
    }
    out.printLine("  }")

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

  ** Write FxStructDef as a Fantom class source.
  private Void writeTemplateElem(FxNode node, OutStream out, Int indent)
  {
    elem := node as FxTmElemNode
    if (elem != null)
    {
      if (elem.isComp)
      {
        attrs := StrBuf()
        elem.attrs.each |v,n|
        {
          // TODO: val?
          if (attrs.size > 0) attrs.addChar(',')
          attrs.add(n.toCode).addChar(':').add(v.toCode)
        }
        if (attrs.isEmpty) attrs.addChar(':')

        out.print("${Str.spaces(indent)}")
        out.printLine("FxRuntime.elem(this, ${elem.qname.toCode}, [${attrs}]),")
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

    // TODO: wrapping in <span> can mess up CSS; so should we
    // do this like React in comment blocks somehow?

    var := node as FxTmVarNode
    if (var != null)
    {
      out.print("${Str.spaces(indent)}")
      out.printLine("Elem(\"span\") { it.setAttr(\"fx-var\", \"$var.name\") },")
    }
  }

  const Str podName
  const FxNode[] nodes
  const FxUsingDef[] usings
  const FxStructDef[] structs
  const FxCompDef[] comps
}