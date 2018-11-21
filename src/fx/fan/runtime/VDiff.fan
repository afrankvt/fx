//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   31 Oct 2018  Andy Frank  Creation
//

using dom

**
**
**
@NoDoc @Js const class VDiff
{
  ** TODO
  static VPatch[] diff(VNode a, VNode b, VPatch[] patches := Obj[,])
  {
    // replace if types do not match
    if (a.typeof != b.typeof)
    {
      echo("--> $a.typeof ?= $b.typeof")
      return patches.add(VPatch { it.op="replace"; it.a=a; it.b=b })
    }

    switch (a.typeof)
    {
      case VElem#: diffElem(a, b, patches)
      case VText#: diffText(a, b, patches)
    }

    // TODO
    // if (a.children.size != b.children.size)
    //   return patches.add(VDom.compileNode(c, null, b))

    // switch (a.typeof)
    // {
    //   case VElem#:
    //     VElem va := a
    //     VElem vb := b
    //     if (va.tag != vb.tag) return patches.add(VDom.compileNode(c, null, b))
    //     if (va.attrs.size != vb.attrs.size) patches.add("TODO-attr")
    // }

    return patches
  }

  private static VPatch[] diffElem(VElem a, VElem b, VPatch[] patches)
  {
    // replace if elements do not match
    if (a.tag != b.tag)
      return patches.add(VPatch { it.op="replace"; it.a=a; it.b=b })

    // if kids match check 1:1
    if (a.children.size == b.children.size)
    {
      a.children.size.times |i|
      {
        ka := a.children[i]
        kb := b.children[i]
        diff(ka, kb, patches)
      }
    }
    else
    {
      // TODO
      a.children.each |ka| { patches.add(VPatch { it.op="remove"; it.a=ka }) }
      b.children.each |kb| { patches.add(VPatch { it.op="add";    it.a=a; it.b=kb }) }
    }

    if (a.attrs.size == b.attrs.size)
    {
      a.attrs.size.times |i|
      {
        aa := a.attrs[i]
        ab := b.attrs[i]
        if (aa.name != ab.name || aa.val != ab.val)
          patches.add(VPatch { it.op="updateAttr"; it.b=b; it.attrName=ab.name; it.attrVal=ab.val })
      }
    }
    else echo("TODO-attr")

    return patches
  }

  private static VPatch[] diffText(VText a, VText b, VPatch[] patches)
  {
// TODO: nuke this concept of returning patch list...
    // todo?
    if (a.text != b.text) patches.add(VPatch { it.op="replace"; it.a=a; it.b=b })
    return patches
  }

  static const VNode nullTree := VElem
  {
    it.tag    = "_null_"
    it.attrs  = VAttr#.emptyList
    it.events = VEvent#.emptyList
  }
}