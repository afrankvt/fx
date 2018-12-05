//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   19 Nov 2018  Andy Frank  Creation
//

using dom

**
** TDefRender renders a TDef and data set to a VNode tree.
**
@NoDoc @Js const class TDefRender
{
  ** Render a TDef tree into virtual VNode DOM tree.
  static VElem render(TElemDef def, Str:Obj? data)
  {
    renderElem(null, 0, def, data)
  }

  private static VElem renderElem(VNode? parent, Int index, TElemDef def, Str:Obj? data)
  {
    return VElem
    {
      it.parent   = parent
      it.index    = index
      it.tag      = def.tag
      it.binds    = renderDefs(it, VBind#,  def.binds, data)
      it.attrs    = renderDefs(it, VAttr#,  def.attrs, data)
      it.events   = renderDefs(it, VEvent#, def.events, data)
      it.children = renderDefs(it, VNode#,  def.children, data)
    }
  }

  private static VNode[] renderDefs(VNode parent, Type type, TDef[] defs, Str:Obj? data, Int offsetIndex := 0)
  {
    vnodes := List(type, defs.size)
    defs.each |d,i|
    {
      v := renderDefFrag(parent, offsetIndex+i, d, data)
      if (v is VNode) vnodes.add(v)
      if (v is List)  vnodes.addAll(v)
    }
    return vnodes
  }

  private static Obj? renderDefFrag(VNode parent, Int index, TDef def, Str:Obj? data)
  {
    switch (def.typeof)
    {
      case TElemDef#:
        return renderElem(parent, index, def, data)

      case TTextDef#:
        TTextDef t := def
        return VText { it.parent=parent; it.index=index; it.text=t.text }

      case TBindDef#:
        TBindDef t := def
        return VBind { it.local=t.local; it.extern=t.extern; it.val=Unsafe(data[t.extern]) }

      case TAttrDef#:
        TAttrDef t := def
        if (t.cond != null)
        {
          val  := resolveExpr(t.expr, data)
          cond := t.cond == "if" ? isTruthy(val) : !isTruthy(val)
          return VAttr { it.name=t.name; it.val=cond ? t.val : "" }
        }
        else
        {
          val := t.val.toStr

          // TODO: move this to a compiler time thing...
          six  := val.index("{")
          eix  := val.index("}")
          while (six != null && eix != null)
          {
            expr := val[(six+1)..<eix]
            tval := resolveExpr(expr, data) ?: ""
            val  = val.replace("{$expr}", tval.toStr)
            six  = val.index("{", six+1)
            eix  = val.index("}", eix+1)
          }

          return VAttr { it.name=t.name; it.val=val }
        }

      case TEventDef#:
        TEventDef t := def
        // TODO: this needs to move to be a compile time thing...
        x := t.msg.toStr.split(' ')
        name := x.first
        edat := Str:Obj?[:]
        if (x.size > 1)
        {
          // TODO: shield your eyes young padawan
          x[1..-1].join(" ")[1..-2].split(',').each |kv|
          {
            y := kv.split(':')
            k := y[0]
            Obj? v := y[1]
            if (v.toStr[0] == '{') v = resolveExpr(v.toStr[1..-2], data)
            edat[k] = v
          }
        }
//        echo("# $t.name => $name / $edat")
        return VEvent { it.name=t.name; it.msg=name; it.data=edat }

      case TExprDef#:
        TExprDef t := def
        val := resolveExpr(t.expr, data) ?: ""
        return VText { it.parent=parent; it.index=index; it.text=val.toStr }

      case TDirDef#:
        TDirDef t := def
        switch (t.dir)
        {
          case "if":      // fall thru
          case "ifnot":
            val  := resolveExpr(t.expr, data)
            cond := t.dir == "if" ? isTruthy(val) : !isTruthy(val)
            return cond==false ? null : renderDefs(parent, VNode#, t.children, data, index)

          case "for":
            // TODO: handle this at compile time with pre-computed info
            p := t.expr.split(' ')
            var  := p[0]
            prop := p[2]
            copy := data.dup

            // TODO
            Str? ivar := null
            if (var.contains(","))
            {
              p = var.split(',')
              var  = p[0]
              ivar = p[1]
            }

            kids := VNode[,]
            List list := resolveExpr(prop, copy)
            list.each |item,i|
            {
              copy[var] = item
              if (ivar != null) copy[ivar] = i
              kids.addAll(renderDefs(parent, VNode#, t.children, copy, i))
            }
            return kids

          default: throw Err("Unknown directive '$t.dir'")
        }

      default: throw Err("TODO --> $def.typeof")
    }
  }

  ** Is value 'truthy'.
  private static Bool isTruthy(Obj? val)
  {
    if (val is Bool)  return val
    if (val is Str)   return ((Str)val).size > 0
    if (val is Int)   return val != 0
    if (val is Float) return val != 0 && val != Float.nan
    if (val != null)  return true
    return false
  }

  ** Resolve a property access path for data map.
  private static Obj? resolveExpr(Str expr, Str:Obj? data)
  {
    // TODO: compiler should pre-validate these in check phase
    path := expr.split('.')
    val  := data[path.first]
    for (i:=1; val != null && i<path.size; i++)
    {
      slot := val.typeof.slot(path[i], false)
      if (slot is Field) val = ((Field)slot).get(val)
      else if (slot is Method) val = ((Method)slot).call(val)
    }
    return val
  }
}