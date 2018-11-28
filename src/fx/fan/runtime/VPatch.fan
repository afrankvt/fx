//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   19 Nov 2018  Andy Frank  Creation
//

using dom


*************************************************************************
** VPatch
*************************************************************************

@Js const class VPatch
{
  ** It-block ctor.
  new make(|This| f) { f(this) }

// TODO: convert this to index; use enum/static lookups..

  **
  ** Patch op to peform:
  **  - 'add':         add a element
  **  - 'replace':     replace an element
  **  - 'remove':      remove an element
  **  - 'addAttr':     add attr value
  **  - 'updateAttr':  update attr value
  **  - 'removeAttr':  remove attr value
  **
  const Str op

  ** Element.
  const VNode? a

  ** Element.
  const VNode? b

  ** Attribute name.
  const Str? attrName

  ** Attribute value
  const Str? attrVal := null
}

*************************************************************************
** Patcher
*************************************************************************

@Js class VPatcher
{
  static Elem patch(FxComp c, Elem root, VPatch[] patches)
  {
    // echo("-- Patch [$patches.size] --")

    // premap source elements since our index paths
    // may change as we add/remove children
    elemMap := VNode:Elem[:]
    patches.each |p|
    {
      if (p.a == null) return
      elemMap[p.a] = lookupElem(root, p.a)
    }

    // now iterate to apply changes
    patches.each |p,i|
    {
      // echo(" $i: ${p.op} a:${p.a?.parent}/${p.a} b:${p.b?.parent}/${p.b}")
      switch (p.op)
      {
        case "add":
          ea := elemMap[p.a]
          eb := nodeToElem(c, p.b)
          ea.add(eb)

        case "remove":
          ea := elemMap[p.a]
          ea.parent.remove(ea)

        case "replace":
          eb := nodeToElem(c, p.b)
          if (p.b.parent == null)
          {
            // replace root
            root = eb
          }
          else
          {
            // replace child
            ea := elemMap[p.a]
            ea.parent.replace(ea, eb)
          }

        case "addAttr":
          elem := lookupElem(root, p.b)
          if (p.attrName == "class") elem.style.addClass(p.attrVal)
          else elem.setAttr(p.attrName, p.attrVal)

        case "removeAttr":
          elem := lookupElem(root, p.b)
          if (p.attrName == "class") elem.style.removeClass(p.attrVal)
          else elem.removeAttr(p.attrName)

        case "updateAttr":
          elem := lookupElem(root, p.b)
          elem.setAttr(p.attrName, p.attrVal)
      }
    }

    return root
  }

  ** Return the backing DOM node for this VNode.
  private static Elem lookupElem(Elem root, VNode vnode)
  {
    // short-circuit if root
    if (vnode.parent == null) return root

    // walk up to find index path
    path := Int[vnode.index]
    vn := vnode.parent
    while (vn != null)
    {
      path.add(vn.index)
      vn = vn.parent
    }

    // walk back down dom to node
    elem := root
    for (j:=path.size-2; j>=0; j--)
    {
      i := path[j]
      elem = elem.children[i]
    }
    return elem
  }

  ** Return the DOM index path.
  private static Str lookupPath(VNode vnode)
  {
    s := "$vnode.index"

    // short-circuit if root
    if (vnode.parent == null) return s

    // walk up to find index path
    path := Int[vnode.index]
    vn := vnode.parent
    while (vn != null)
    {
      s += ",${vn.index}"
      vn = vn.parent
    }

    return s
  }

  ** Compile a VNode to DOM Elem instance.
  static Elem nodeToElem(FxComp c, VNode node)
  {
    switch (node.typeof)
    {
      case VElem#:
        VElem v := node
        if (v.isComp)
        {
          e := Elem(v.tag) { it.setAttr("fx-comp", v.qname) }
          FxRuntime.cur.mount(e)
          return e
        }
        else
        {
          e := Elem(v.tag)
          v.attrs.each |k|
          {
            VAttr va := k
            if (va.val.size > 0)
            {
              if (va.name == "class") e.style.addClass(va.val)
              else e.setAttr(va.name, va.val.toStr)
            }
          }
          v.events.each |k|
          {
            VEvent ve := k
            e.onEvent(ve.name, false) { c.send(ve.msg, ve.data) }
          }
          v.children.each |k|
          {
            e.add(nodeToElem(c, k))
          }
          return e
        }

      case VText#:
        VText v := node
        return Elem("_text") { it.text=v.text }

      default: throw Err("TODO --> $node.typeof")
    }
  }
}