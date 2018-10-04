//
// Copyright (c) 2011, Xored Software Inc.
// Licensed under the MIT License
//

@Js enum class State { text, text_r, otag, tag, tag_r, ctag, end, end_r }

@Js class MustacheParser
{
  private static const Int[] whiteSpace := [
    ' '
    ,'\t'
    ,'\u00a0' //NO-BREAK SPACE
    ,'\u1680' //OGHAM SPACE MARK
    ,'\u2000' //EN QUAD
    ,'\u2001' //EM QUAD
    ,'\u2002' //EN SPACE
    ,'\u2003' //EM SPACE
    ,'\u2004' //THREE-PER-EM SPACE
    ,'\u2005' //FOUR-PER-EM SPACE
    ,'\u2006' //SIX-PER-EM SPACE
    ,'\u2007' //FIGURE SPACE
    ,'\u2008' //PUNCTUATION SPACE
    ,'\u2009' //THIN SPACE
    ,'\u200a' //HAIR SPACE
    ,'\u200b' //ZERO WIDTH SPACE
    ,'\u200f' //NARROW NO-BREAK SPACE
    ,'\u205f' //MEDIUM MATHEMATICAL SPACE
    ,'\u3000' //IDEOGRAPHIC SPACE
  ]

  InStream in
  Str otag := "{{"
  Str ctag := "}}"

  State state := State.text
  Bool standalone := true

  StrBuf buf := StrBuf()
  StrBuf tagbuf := StrBuf()
  StrBuf begin := StrBuf()
  StrBuf end := StrBuf()

  Int line := 1

  Int prev := -1
  Int cur := -1

  MustacheToken[] stack := [,]
  Int tagPosition := 0
  Bool curlyBraceTag

  new make(|This|? f := null) { f?.call(this) }

  MustacheToken parse () {
    consume
    while(cur!=-1) { /*dump;*/ automata[state]() }

    switch (state) {
      case State.text: addStaticText
      case State.otag: notOtag; addStaticText
      case State.tag: throw ParseErr("Line $line: Unclosed tag \"$buf\"")
      case State.ctag: notCtag; addStaticText
      case State.end: addStaticText; addTag
    }
    stack.each {
      if (it is IncompleteSection) {
        key := (it as IncompleteSection).key
        throw ParseErr("Line $line: Unclosed mustache section \"$key\"")
      }
    }

    return (stack.size==1)? stack[0] : RootToken(stack)
  }

  //TODO: move somewhere
  private Void nextLine() {
    standalone = true
    begin.clear
    end.clear
    line++
  }

  private [State:|->|] automata := [

    State.text: |->| {
      if (cur == '\r') shift(State.text_r)
      else if (cur == '\n') { buf.add(begin); nextLine; addCur }
      else if (standalone && whiteSpace.contains(cur)) addBCur
      else if (maybeOtag) {}
      else { dropStandalone; addCur }
      consume
    }

    ,State.text_r: |->| {
      buf.add(begin)
      buf.addChar('\r')
      nextLine

      if (cur == '\n') { addCur; consume }
      shift(State.text)
    }

    ,State.otag: |->| {
      if (cur == otag[tagPosition]) {
        if (tagPosition == otag.size-1) shiftTag
        else tagPosition++
      } else notOtag
      consume
    }

    ,State.tag: |->| {
      if (tagbuf.isEmpty && cur == '{') {
        curlyBraceTag = true
        addTCur
      } else if (curlyBraceTag && cur == '}') {
        curlyBraceTag = false
        addTCur
      } else if (cur==ctag[0]) {
        if (ctag.size>1) {
          tagPosition = 1
          state = State.ctag
        } else {
          if (standalone) { state = State.end }
          else { addTag; state = State.text }
        }
      } else addTCur

      consume
    }

    ,State.tag_r: |->| {
    }

    ,State.ctag: |->| {
      if (cur == ctag[tagPosition]) {
        if (tagPosition == ctag.size-1) {
          if (standalone) { state = State.end }
          else { addTag; state = State.text }
        } else tagPosition++;
      } else {
        state = State.tag
        notCtag
      }
      consume
    }

    ,State.end: |->| {
      if (cur == '\r') shift(State.end_r)
      else if (cur == '\n') { addECur; addTag; nextLine; shift(State.text) }
      else if (whiteSpace.contains(cur)) { addECur }
      else {
        notEnd
        state = State.text
        if (cur==otag[0]) {
          if (otag.size>1) {
            tagPosition = 1
            state = State.otag
          } else {
            addStaticText
            state = State.tag
          }
        } else addCur
      }
      consume
    }

    ,State.end_r: |->| {
      end.addChar('\r')
      if (cur == '\n') end.addChar('\n')
      addTag
      nextLine
      if (cur == '\n') consume
      shift(State.text)
    }

  ]

  Void shift(State newState) { state = newState }
  Void shiftOTag() { tagPosition = 1; shift(State.otag) }
  Void shiftTag() {
    if (!standalone) addStaticText
    curlyBraceTag = false
    shift(State.tag)
  }

  Bool maybeOtag() {
    if ( cur == otag[0]) {
      if (otag.size>1) shiftOTag
      else shiftTag
      return true
    }
    return false
  }

  Void addStaticText() {
    if (buf.size>0) {
      stack.add(StaticTextToken(buf.toStr))
      buf.clear
    }
  }

  Void addTag() {
    Str content := checkContent(tagbuf.toStr)

    switch (content[0]) {
      case '!': ignore // ignore comments
      case '&':
        buf.add(begin)
        begin.clear
        afterNewLine := isEndsWithNewLine
        addStaticText
        stack.add(unescapedToken(content[1..-1], afterNewLine))
        buf.add(end)
        end.clear
      case '{':
        if (content.endsWith("}")) {
          buf.add(begin)
          begin.clear
          afterNewLine := isEndsWithNewLine
          addStaticText
          stack.add(unescapedToken(content[1..-2], afterNewLine))
          buf.add(end)
          end.clear
        } else throw ParseErr("Line $line: Unbalanced \"{\" in tag \"$content\"")
      case '^':
        addStaticText
        stack.add(IncompleteSection(checkContent(content[1..-1]), true, otag, ctag))
      case '#':
        addStaticText
        stack.add(IncompleteSection(checkContent(content[1..-1]), false, otag, ctag))
      case '/':
        addStaticText
        name := checkContent(content[1..-1])
        MustacheToken[] children := [,]

        while(true) {
          last := stack.pop

          if (last == null)
            throw ParseErr("Line $line: Closing unopened section \"$name\"")

          if (last is IncompleteSection) {
            incomplete := (last as IncompleteSection)
            inverted := incomplete.inverted
            key := incomplete.key
            if (key == name) {
              stack.add(SectionToken(inverted,name,children.reverse
                ,incomplete.otag,incomplete.ctag
                ,otag,ctag))
              break
            } else throw ParseErr("Line $line: Unclosed section \"$key\"")
          } else children.add(last)
        }
      case '>':
      case '<':
//        if (!standalone) {
//        echo("tag is indented $indent")
          buf.add(begin)
          addStaticText
//        }
          stack.add(partialToken(content[1..-1], begin.toStr))
          begin.clear
//          buf.add(end)
//          end.clear
      case '=':
        if (content.size>2 && content.endsWith("=")) {
          changeDelimiter := checkContent(content[1..-2])
          newTags := changeDelimiter.split
          if (newTags.size==2) {
            stack.add(ChangeDelimiterToken(otag,ctag,newTags[0],newTags[1]))
            otag = newTags[0]
            ctag = newTags[1]
          } else {
            throw ParseErr("Line $line: Invalid change delimiter tag content: \"$changeDelimiter\"")
          }
        } else throw ParseErr("Line $line: Invalid change delimiter tag content: \"$content\"")
      default:
        buf.add(begin)
        begin.clear
        afterNewLine := isEndsWithNewLine
        addStaticText
        stack.add(defaultToken(content, afterNewLine))
        buf.add(end)
        end.clear
    }
    tagbuf.clear
  }

  private Bool isEndsWithNewLine() { s := buf.toStr; return (s.endsWith("\n") || s.endsWith("\r")) }

  virtual MustacheToken partialToken(Str content, Str indentStr) {
    PartialToken(checkContent(content),indentStr,otag,ctag)
  }

  virtual MustacheToken defaultToken(Str content, Bool afterNewLine) {
    EscapedToken(content,otag,ctag,afterNewLine)
  }

  virtual MustacheToken unescapedToken(Str content, Bool afterNewLine) {
    UnescapedToken(checkContent(content),otag,ctag,afterNewLine)
  }

  Void ignore() {}

  Str checkContent(Str content) {
    trimmed := content.trim
    if (trimmed.size == 0)
      throw ParseErr("Line $line: Empty tag")
    else
      return trimmed
  }

  Void dropStandalone() {
    if (standalone) {
      buf.add(begin)
      begin.clear
      standalone = false
    }
  }

  Void notEnd() {
    buf.add(begin)
    begin.clear
    addStaticText
    addTag
    buf.add(end)
    end.clear
    standalone = false
  }

  Void notOtag() {
    dropStandalone
    buf.add( otag[0..tagPosition-1] )
    addCur
    shift(State.text)
  }

  Void notCtag() { tagbuf.add(ctag[0..tagPosition-1]); addCur }

  Void addCur() { if (cur!=-1) buf.addChar(cur) }
  Void addTCur() { if (cur!=-1) tagbuf.addChar(cur) }
  Void addBCur() { if (cur!=-1) begin.addChar(cur) }
  Void addECur() { if (cur!=-1) end.addChar(cur) }

  Void consume() {
    this.prev = this.cur
    this.cur = this.in.readChar ?: -1
  }

  private Void dump() {
    str := StrBuf()
    str.add("s: ")
    str.add(state)
    str.add("(")
    str.add(standalone)
    str.add(") c:")
    dumpChar(str,cur)
    str.add(" b:<|")
    dumpStr(str, buf)
    str.add("|> <|")
    dumpStr(str, begin)
    str.add("|> >|")
    dumpStr(str, end)
    str.add("|< T:{")
    dumpStr(str, tagbuf)
    str.add("}")
    echo(str.toStr)
  }

  private Void dumpStr(StrBuf str, StrBuf buf) {
    for (i := 0; i<buf.size; i++) {
      dumpChar(str, buf[i])
    }
  }

  private Void dumpChar(StrBuf str, Int char) {
    if (char >= 32) {
      str.add(char.toChar)
    } else {
      str.add("[")
      str.add(char)
      str.add("]")
    }
  }
}


