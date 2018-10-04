//
// Copyright (c) 2011, Xored Software Inc.
// Licensed under the MIT License
//

@Js internal class LambdaValue {
  Obj? context
  Obj? object
  Func? func
  Bool callOnInstance
  Str otag
  Str ctag
  Str childrenSource
  [Str:Mustache]partials
  Obj?[] callStack
  Str indentStr
  MustacheToken? cachedTree

  new make(|This|? f := null) { f?.call(this) }

  override Str toStr() { "LambdaValue{context=$context, object=$object, func=$func, callOnInstance=$callOnInstance, childrenSource=$childrenSource, partials=$partials, callStack=$callStack, indentStr=\"$indentStr\", cachedTree=$cachedTree}" }
}

**
** base mixin for all the token implementations
**
@Js const mixin MustacheToken {

  abstract Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr)

  abstract Str templateSource()

  **    1) Split the name on periods; the first part is the name to resolve, any
  **    remaining parts should be retained.
  **    2) Walk the context stack from top to bottom, finding the first context
  **    that is a) a hash containing the name as a key OR b) an object responding
  **    to a method with the given name.
  **    3) If the context is a hash, the data is the value associated with the
  **    name.
  **    4) If the context is an object and the method with the given name has an
  **    arity of 1, the method SHOULD be called with a String containing the
  **    unprocessed contents of the sections; the data is the value returned.
  **    5) Otherwise, the data is the value returned by calling the method with
  **    the given name.
  **    6) If any name parts were retained in step 1, each should be resolved
  **    against a context stack containing only the result from the former
  **    resolution.  If any part fails resolution, the result should be considered
  **    falsey, and should interpolate as the empty string.
  static Obj? valueOf(
    Str name
    , Obj? context
    , [Str:Mustache]partials
    , Obj?[] callStack
    , Str indentStr
    , Str otag
    , Str ctag
    , Str childrenSource
    , MustacheToken? cachedTree := null
  ) {
    if (name == ".") return context

    value := context
    path := name.split('.')
    afterDot := false
    path.each |Str el| {
      value = getValue(el, value, partials, callStack, indentStr, otag, ctag, childrenSource, cachedTree, afterDot)
      afterDot = true
    }

    return value
  }

  private static Obj? getValue(
    Str name
    , Obj? context
    , [Str:Mustache]partials
    , Obj?[] callStack
    , Str indentStr
    , Str otag
    , Str ctag
    , Str childrenSource
    , MustacheToken? cachedTree
    , Bool afterDot
  ) {

    Obj[]? l := singleShot(name, context, context, childrenSource, partials, callStack
                  ,indentStr, cachedTree, otag, ctag)
    Bool found := (l[0] as Bool)?:false
    Obj? value := l[1]

    if (!found && !afterDot) {
      callStack.eachWhile |Obj o->Bool?| {
        l = singleShot(name, context, o, childrenSource, partials, callStack
                  ,indentStr, cachedTree, otag, ctag)
        found = (l[0] as Bool)?:false
        value = l[1]
        return found?true:null
      }
    }

    if (value is Func) {
      value = LambdaValue {
        it.context = context
        it.object = null
        it.func = value
        it.callOnInstance = false
        it.childrenSource = childrenSource
        it.partials = partials
        it.callStack = callStack
        it.indentStr = indentStr
        it.cachedTree = cachedTree
        it.otag = otag
        it.ctag = ctag
      }
    }
//    echo("value is $value")
    return value
  }

  static Obj?[]singleShot(Str name, Obj? context, Obj? object
                  ,Str childrenSource, [Str:Mustache] partials, Obj?[] callStack
                  ,Str indentStr, MustacheToken? cachedTree, Str otag, Str ctag) {
    if (context == null)
      return [false, null]

    found := false
    value := null

    if (object is Map) {
      m := object as Map
      value = m.get(name)
      found = m.containsKey(name)
    }

    if (!found) {
      slot := object.typeof.slot(name,false)

      if (slot is Field) {
        value = (slot as Field).get(object)
        found = true
      } else if (slot is Method) {
        value = LambdaValue {
          it.context = context
          it.object = object
          it.func = (slot as Method).func
          it.callOnInstance = true
          it.childrenSource = childrenSource
          it.partials = partials
          it.callStack = callStack
          it.indentStr = indentStr
          it.cachedTree = cachedTree
          it.otag = otag
          it.ctag = ctag
        }
        found = true
      } else if (slot == null) {
        try {
          value = object.trap(name)
          found = true
        } catch (UnknownSlotErr e) { }
      }
    }
    return [found, value]
  }

  static Obj? format(Obj? value) {
    needsExpansion := false

    Obj? context := null
    Obj? instance := null
    Bool callOnInstance := false
    Str childrenSource := ""
    [Str:Mustache] partials := [:]
    Obj?[] callStack := [,]
    Str indentStr := ""
    Str otag := "{{"
    Str ctag := "}}"
    MustacheToken? cachedTree := null


    if (value is LambdaValue) {
      v := value as LambdaValue
      context = v.context
      callOnInstance = v.callOnInstance
      instance = v.object
      childrenSource = v.childrenSource
      partials = v.partials
      callStack = v.callStack
      indentStr = v.indentStr
      value = v.func
      cachedTree = v.cachedTree
      otag = v.otag
      ctag = v.ctag
    }

    while (value is Func) {
      needsExpansion = true

      f := (value as Func)
      paramsCount := f.params.size - (callOnInstance?1:0)

      args := callOnInstance? [instance] : [,]

      render := |Str toRender->Str| {
          result := StrBuf()

          if (toRender == childrenSource) cachedTree.render(result, context, partials, callStack, indentStr)
          else MustacheParser {
            in = toRender.in
            it.otag = "{{"
            it.ctag = "}}"
          }.parse.render(result,context,partials,callStack, indentStr)

          return result.toStr
        }

      if (paramsCount > 0) { args.add(childrenSource) }
      if (paramsCount > 1) {
        if (f.params[(callOnInstance?2:1)].type.base == Func#) {
          args.add(
              |Str nameArg ->Obj?| {
                return valueOf(nameArg, context, partials
                                , callStack, indentStr, otag, ctag, childrenSource, cachedTree)
              }
            )
        } else { args.add(context) }
      }
      if (paramsCount > 2) { args.add(render) }
//      echo("context is $context")
//      echo("f is $f ($value) args: $args")
      value = f.callList(args)
//      echo("result is $value")
      callOnInstance = false
    }

    if (needsExpansion && value is Str) {
      template := value as Str
      value = Mustache(template.in, otag, ctag).render(context, partials, callStack)
    }

    if (value is Decimal) {
      str := value.toStr
      while (str.size>1 && str.endsWith("0")) {
        str = str[0..-2]
      }
      if (str.endsWith(".")) { str = str[0..-2] }
      return str
    }
    return value
  }

}

@Js internal const mixin NodeToken {

  protected Void renderChildren(
    MustacheToken[]children
    , StrBuf output
    , Obj? context
    , [Str:Mustache]partials
    , Obj?[] callStack
    , Str indentStr
  ) {
    children.each { it.render(output,context,partials,callStack, indentStr) }
  }

}

@Js internal const class RootToken : MustacheToken, NodeToken {
  const MustacheToken[] children

  new make(MustacheToken[] children) {
    this.children = children
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
    renderChildren(children, output, context, partials, callStack, indentStr)
  }

  override Str templateSource() {
    b := StrBuf()
    children.each |MustacheToken t| { b.add(t.templateSource) }
    return b.toStr
  }

  override Str toStr() { "root[ $children ]" }

}

@Js internal const class ChangeDelimiterToken : MustacheToken {
  const Str otag
  const Str ctag

  const Str newOtag
  const Str newCtag

  new make(Str otag, Str ctag, Str newOtag, Str newCtag) {
    this.otag = otag
    this.ctag = ctag

    this.newOtag = newOtag
    this.newCtag = newCtag
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
  }

  override Str templateSource() {
    b := StrBuf()
    b.add(otag)
    b.add("=")
    b.add(newOtag)
    b.add(" ")
    b.add(newCtag)
    b.add("=")
    b.add(ctag)
    return b.toStr
  }

  override Str toStr() { "delimiters( $newOtag , $newCtag )" }

}

@Js internal const class IncompleteSection : MustacheToken {
  const Str key
  const Bool inverted
  const Str otag
  const Str ctag

  new make(Str key,Bool inverted, Str otag, Str ctag) {
    this.key = key
    this.inverted = inverted
    this.otag = otag
    this.ctag = ctag
  }
  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
  }
  override Str templateSource() {
    return ""
  }

}

@Js internal enum class TextState { t, r, rn, n }

@Js internal const class StaticTextToken : MustacheToken
{
  const Str staticText

  new make(Str staticText) {
    this.staticText = staticText
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
//    echo("indent = $indent")
    if (indentStr.isEmpty) output.add(staticText)
    else {
      //output.add(indentStr)

      state := TextState.t
      staticText.each {
//        echo("it: $it")
        switch (state) {
          case TextState.t:
            switch (it) {
              case '\r': state = TextState.r
              case '\n': state = TextState.n
              default: output.addChar(it);
            }
          case TextState.r:
            switch (it) {
              case '\n': state = TextState.rn
              default: output.addChar('\r'); output.add(indentStr); output.addChar(it); state = TextState.t
            }
          case TextState.rn:
            output.add("\r\n"); output.add(indentStr); output.addChar(it); state = TextState.t
          case TextState.n:
            output.addChar('\n'); output.add(indentStr); output.addChar(it); state = TextState.t
        }
      }

      switch (state) {
          case TextState.r: output.addChar('\r')
          case TextState.rn: output.add("\r\n")
          case TextState.n: output.addChar('\n')
      }
    }
  }

  override Str templateSource() {
    return staticText
  }

  override Str toStr() { "text \"$staticText\"" }
}

@Js internal const class SectionToken : MustacheToken, NodeToken {
  const MustacheToken[] children
  const Str key
  const Bool invertedSection
  const Str beginOtag
  const Str endOtag
  const Str beginCtag
  const Str endCtag
  const RootToken childrenToken

  new make(Bool invertedSection, Str key, MustacheToken[] children, Str beginOtag, Str beginCtag, Str endOtag, Str endCtag) {
    this.key = key
    this.children = children
    this.childrenToken = RootToken(children)
    this.invertedSection = invertedSection
    this.beginOtag = beginOtag
    this.endOtag = endOtag
    this.beginCtag = beginCtag
    this.endCtag = endCtag
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
    Obj? value := valueOf(key, context, partials, callStack, indentStr, beginOtag, beginCtag, childrenSource(), childrenToken)

    if (value == null) {
      if (invertedSection) renderChildren(children, output, context, partials, callStack, indentStr)
      return
    }

    if (value is LambdaValue && invertedSection) {
      return
    }

    value = format(value)

    callStack.insert(0, value)

    if (value is Str) {
      output.add(value as Str)
    } else if (value is Bool) {
      Bool b := value
      if (invertedSection.xor(b))
          renderChildren(children, output, context, partials, callStack, indentStr)
    } else if (value is List) {
        list := (value as List)
        if (invertedSection) {
          if (list.isEmpty) renderChildren(children, output, context, partials, callStack, indentStr)
        } else {
          list.each { renderChildren(children, output, it, partials, callStack, indentStr) }
        }
    } else {
      if (!invertedSection) renderChildren(children, output, value, partials, callStack, indentStr)
    }
    callStack.removeAt(0)

  }

  private Str childrenSource() {
    b := StrBuf()
    children.each |MustacheToken t| { b.add(t.templateSource) }
    return b.toStr
  }

  override Str templateSource() {
    b := StrBuf()
    b.add(beginOtag)
    b.add(invertedSection?"^":"#")
    b.add(key)
    b.add(beginCtag)
    children.each |MustacheToken t| { b.add(t.templateSource) }
    b.add(endOtag)
    b.add("/")
    b.add(key)
    b.add(endCtag)
    return b.toStr
  }

  override Str toStr() { "section($invertedSection, $key, [ $children ])" }
}

@Js internal const class EscapedToken : MustacheToken {
  const Str key
  const Str otag
  const Str ctag
  const Bool afterNewLine

  new make(Str key, Str otag, Str ctag, Bool afterNewLine) {
    this.key = key
    this.otag = otag
    this.ctag = ctag
    this.afterNewLine = afterNewLine
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
    if (afterNewLine) output.add(indentStr)
    // TRICKY: According to specs lambda result expansion procedure expects standard
    // double/triple mustache tags. It is not affected by currently set delimiter.
    Obj? value := format(valueOf(key, context, partials, callStack, indentStr, "{{", "}}", ""))
    if (value == null)
      return
    Str str := value.toStr
    str.each {
      switch (it) {
        case '<': output.add("&lt;")
        case '>': output.add("&gt;")
        case '&': output.add("&amp;")
        case '"': output.add("&quot;")
        default: output.addChar(it)
      }
    }
  }

  override Str templateSource() {
    b := StrBuf()
    b.add(otag)
    b.add(key)
    b.add(ctag)
    return b.toStr
  }

  override Str toStr() { "escaped($afterNewLine, $key)" }

}

@Js internal const class UnescapedToken : MustacheToken {
  const Str key
  const Str otag
  const Str ctag
  const Bool afterNewLine

  new make(Str key, Str otag, Str ctag, Bool afterNewLine) {
    this.key = key
    this.otag = otag
    this.ctag = ctag
    this.afterNewLine = afterNewLine
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
    if (afterNewLine) output.add(indentStr)
    // TRICKY: According to specs lambda result expansion procedure expects standard
    // double/triple mustache tags. It is not affected by currently set delimiter.
    Obj? value := format(valueOf(key, context, partials, callStack, indentStr, "{{", "}}", ""))
    if (value == null)
      return
    output.add(value)
  }

  override Str templateSource() {
    b := StrBuf()
    b.add(otag)
    b.add("{")
    b.add(key)
    b.add("}")
    b.add(ctag)
    return b.toStr
  }

  override Str toStr() { "unescaped($afterNewLine, $key)" }
}

@Js internal const class PartialToken : MustacheToken {
  const Str key
  const Str otag
  const Str ctag
  const Str partialIndent

  new make(Str key, Str partialIndent, Str otag, Str ctag) {
    this.partialIndent = partialIndent
    this.key = key
    this.otag = otag
    this.ctag = ctag
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials, Obj?[] callStack, Str indentStr) {
    Mustache? template := partials[key]
    if (template == null)
      throw ArgErr("Partial \"$key\" is not defined.")
    else {
      callStack.insert(0,template)
      output.add(template.render(context, partials, callStack, indentStr+partialIndent))
      callStack.removeAt(0)
    }
  }

  override Str templateSource() {
    b := StrBuf()
    b.add(otag)
    b.add(">")
    b.add(key)
    b.add(ctag)
    return b.toStr
  }

  override Str toStr() { "partial($key)" }
}
