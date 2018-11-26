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

    diffAttrs(a, b, patches)
    // diffEvents

    return patches
  }

  private static VPatch[] diffAttrs(VElem ae, VElem be, VPatch[] patches)
  {
    // TODO: should probably move some of this directly
    // into VNode to optimize the map creation/memory use

    amap := Str:VAttr[:]
    bmap := Str:VAttr[:]

    be.attrs.each |bv|
    {
      if (bv.val.size == 0) return
      bmap.add(toKey(bv), bv)
    }

    ae.attrs.each |av|
    {
      if (av.val.size == 0) return

      ak := toKey(av)
      amap.add(ak, av)
      bv := bmap[ak]

      if (bv == null)
      {
        // add attr
        patches.add(VPatch { it.op="removeAttr"; it.b=be; it.attrName=av.name; it.attrVal=av.val })
      }
      else if (av.val != bv.val)
      {
        // update attr
        patches.add(VPatch { it.op="updateAttr"; it.b=be; it.attrName=bv.name; it.attrVal=bv.val })
      }
    }

    // check for new attrs to add
    bmap.each |bv|
    {
      if (amap.containsKey(toKey(bv)) == false)
        patches.add(VPatch { it.op="addAttr"; it.b=be; it.attrName=bv.name; it.attrVal=bv.val })
    }

    return patches
  }

  private static VPatch[] diffText(VText a, VText b, VPatch[] patches)
  {
// TODO: nuke this concept of returning patch list...
    // todo?
    if (a.text != b.text) patches.add(VPatch { it.op="replace"; it.a=a; it.b=b })
    return patches
  }

  private static Str toKey(VAttr v)
  {
    if (v.name == "class") return "class_${v.val}"
    return v.name
  }

  static const VNode nullTree := VElem
  {
    it.tag    = "_null_"
    it.attrs  = VAttr#.emptyList
    it.events = VEvent#.emptyList
  }
}