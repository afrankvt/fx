//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   10 Oct 2018  Andy Frank  Creation
//

*************************************************************************
** TmTokenType
*************************************************************************

internal enum class TmTokenType
{
  comment,
  identifier,
  attrVal,
  bracketOpen,
  bracketClose,
  sqBracketOpen,
  sqBracketClose,
  slash,
  equal,
  varStart,
  varEnd,
  var,
  text,
  eos
}

*************************************************************************
** TmToken
*************************************************************************

internal const class TmToken
{
  ** Ctor.
  new make(TmTokenType t, Str v) { this.type=t; this.val=v }

  ** Token type.
  const TmTokenType type

  ** Token literval val.
  const Str val

  Bool isComment()        { type == TmTokenType.comment        }
  Bool isIdentifier()     { type == TmTokenType.identifier     }
  Bool isBracketOpen()    { type == TmTokenType.bracketOpen    }
  Bool isBracketClose()   { type == TmTokenType.bracketClose   }
  Bool isSqBracketOpen()  { type == TmTokenType.sqBracketOpen  }
  Bool isSqBracketClose() { type == TmTokenType.sqBracketClose }
  Bool isSlash()          { type == TmTokenType.slash          }
  Bool isText()           { type == TmTokenType.text           }
  Bool isVarStart()       { type == TmTokenType.varStart       }
  Bool isVarEnd()         { type == TmTokenType.varEnd         }
  Bool isEos()            { type == TmTokenType.eos            }
}

*************************************************************************
** FxParser
*************************************************************************

internal class FxTemplateParser
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Ctor.
  new make(Str podName, Str filename, InStream in, Int startLine)
  {
    this.podName  = podName
    this.filename = filename
    this.in       = in
    this.line     = startLine
  }

  ** Parse input stream.
  FxDef[] parse()
  {
    defs := FxDef[,]
    TmToken? token

    while ((token = nextToken).isEos == false)
    {
      // echo("$token.type: $token.val")
      if (token.isBracketOpen) { defs.add(parseNode(token)); continue }
      throw unexpectedToken(token)
    }

    return defs
  }

//////////////////////////////////////////////////////////////////////////
// Elem
//////////////////////////////////////////////////////////////////////////

  ** Parse an element or directive node.
  private FxDef parseNode(TmToken pre)
  {
    nodeType := pre.isBracketOpen ? typeElem : typeDir
    nodeName := nextToken(TmTokenType.identifier).val
    binds    := FxBindDef[,]
    attrs    := FxAttrDef[,]
    events   := FxEventDef[,]
    kids     := FxDef[,]

    TmToken? token
    while ((token = nextToken).isEos == false)
    {
      // attr
      if (token.isIdentifier)
      {
        name := token.val
        Obj val := ""

        if (peek == '=')
        {
          nextToken(TmTokenType.equal)
          val = nextToken(TmTokenType.attrVal).val
        }

        switch (name[0])
        {
          case '&':
            local  := name[1..-1]
            extern := val=="" ? local : val
            binds.add(FxBindDef { it.local=local; it.extern=extern })

          case '@':
            event := name[1..-1]
            msg   := val
            events.add(FxEventDef { it.event=event; it.msg=msg })

          default:
            attrs.add(FxAttrDef { it.name=name; it.val=val })
        }
        continue
      }

      if (token.isBracketClose) continue
      if (token.isSqBracketClose) continue

      if (token.isSlash)
      {
        if (peek == '>')
        {
          // inline-tag
          nextToken(TmTokenType.bracketClose)
          break
        }
      }

      if (token.isBracketOpen)
      {
        if (peek == '/')
        {
          // close tag
          nextToken(TmTokenType.slash)
          close := nextToken(TmTokenType.identifier).val
          if (close != nodeName) throw parseErr("Tag names do not match '$nodeName' != '$close'")
          nextToken(TmTokenType.bracketClose)
          break
        }
        else
        {
          // recurse
          kids.add(parseNode(token))
          continue
        }
      }

      if (token.isSqBracketOpen)
      {
        if (peek == '/')
        {
          // close dir
          nextToken(TmTokenType.slash)
          close := nextToken(TmTokenType.identifier).val
          if (close != nodeName) throw parseErr("Directives do not match '$nodeName' != '$close'")
          nextToken(TmTokenType.sqBracketClose)
          break
        }
        else
        {
          // recurse
          kids.add(parseNode(token))
          continue
        }
      }

      if (token.isText)
      {
        kids.add(FxTextNodeDef { it.text=token.val })
        continue
      }

      if (token.isVarStart)
      {
        name := nextToken(TmTokenType.var).val
        nextToken(TmTokenType.varEnd)
        kids.add(FxVarNodeDef { it.name=name })
        continue
      }

      throw unexpectedToken(token)
    }

    if (nodeType == typeElem)
      return FxNodeDef
      {
        it.tagName = nodeName
        it.binds   = binds
        it.attrs   = attrs
        it.events  = events
        it.kids    = kids
        it.podName = this.podName // just always set
      }
    else
      return FxDirDef
      {
        it.dir  = nodeName
        it.expr = attrs.join(" ") |a| { a.name } // TODO
        it.kids = kids
      }
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizer
//////////////////////////////////////////////////////////////////////////

  ** Read next token from stream or 'null' if EOS.  If 'type' is
  ** non-null and does match read token, throw ParseErr.
  private TmToken nextToken(TmTokenType? type := null)
  {
    // read next non-comment token
    token := parseNextToken
    while (token?.isComment == true) token = parseNextToken

    // wrap in eos if hit end of file
    if (token == null) token = TmToken(TmTokenType.eos, "")

    // check match
    if (type != null && token?.type != type) throw unexpectedToken(token)

    return token
  }

  ** Read next token from stream or 'null' if EOS.
  private TmToken? parseNextToken()
  {
    buf.clear

    // eat leading whitepsace
    ch := read
    while (ch?.isSpace == true) ch = read
    if (ch == null) return null

    // line comments
    if (ch == '/' && peek == '/')
    {
      read
      ch = read
      while (ch != '\n' || ch == null)
      {
        buf.addChar(ch)
        ch = read
      }
      return TmToken(TmTokenType.comment, buf.toStr)
    }

// TODO
    // directive
    if (isScopeDir && ch.isAlpha)
    {
      buf.addChar(ch)
      while (peek != null && (peek.isAlphaNum || peek == ','))
      {
        buf.addChar(read)
      }
      return TmToken(TmTokenType.identifier, buf.toStr)
    }

// TODO: break out var bindings as distinct token?
    // indentifer
    if (isScopeTag && (ch.isAlpha || ch == '&' || ch == '@'))
    {
      buf.addChar(ch)
      while (peek != null && (peek.isAlphaNum || peek == ':' || peek == '-' || peek == '.'))
      {
        buf.addChar(read)
      }
      return TmToken(TmTokenType.identifier, buf.toStr)
    }

    // var
    if (isScopeVar && ch.isAlpha)
    {
      buf.addChar(ch)
      while (peek != null && (peek.isAlphaNum || peek == '.' || peek == '_'))
      {
        buf.addChar(read)
      }
      return TmToken(TmTokenType.var, buf.toStr)
    }

    // attrVal
    if (ch == '\"')
    {
      while (peek != null && peek != '\"')
      {
        if (peek == '\\') read
        buf.addChar(read)
      }
      if (peek == '\"') read
      return TmToken(TmTokenType.attrVal, buf.toStr)
    }

    // brackets
    if (ch == '<') { scope=scopeTag;   return TmToken(TmTokenType.bracketOpen,  ch.toChar) }
    if (ch == '>') { scope=scopeChild; return TmToken(TmTokenType.bracketClose, ch.toChar) }
    if (ch == '[') { scope=scopeDir;   return TmToken(TmTokenType.sqBracketOpen,  ch.toChar) }
    if (ch == ']') { scope=scopeChild; return TmToken(TmTokenType.sqBracketClose, ch.toChar) }
    if (ch == '/') return TmToken(TmTokenType.slash, ch.toChar)

    // vars
    if (ch == '{' && peek == '{') { in.read; scope=scopeVar;   return TmToken(TmTokenType.varStart, "{{") }
    if (ch == '}' && peek == '}') { in.read; scope=scopeChild; return TmToken(TmTokenType.varEnd,   "}}") }

    // operators
    if (ch == '=') return TmToken(TmTokenType.equal, ch.toChar)

    // text node
    if (isScopeChild)
    {
      buf.addChar(ch)
      while (peek != null && peek != '<')
      {
        ch = read

        // check for inline vardefs
        if (ch == '{' && peek == '{')
        {
          in.unread(ch)
          return TmToken(TmTokenType.text, buf.toStr)
        }

        // otherwise add to text node
        buf.addChar(ch)
      }
      return TmToken(TmTokenType.text, buf.toStr)
    }

    throw parseErr("Invalid char 0x${ch.toHex} ($ch.toChar)")
  }

  ** Read next char in stream.
  private Int? read()
  {
    ch := in.read
    if (ch == '\n') line++
    return ch
  }

  ** Peek next char in stream.
  private Int? peek() { in.peek }

  private Bool isScopeDir()   { scope == scopeDir   }
  private Bool isScopeTag()   { scope == scopeTag   }
  private Bool isScopeChild() { scope == scopeChild }
  private Bool isScopeVar()   { scope == scopeVar   }

  ** Throw ParseErr
  private Err parseErr(Str msg)
  {
    ParseErr("${msg} [${filename}:$line]")
  }

  ** Throw ParseErr
  private Err unexpectedToken(TmToken token)
  {
    token.isEos
      ? ParseErr("Unexpected end of stream [${filename}:$line]")
      : ParseErr("Unexpected token: '$token.val' [${filename}:$line]")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str[] directives := ["if"]

  private const Int scopeNone  := 0
  private const Int scopeDir   := 1
  private const Int scopeTag   := 2
  private const Int scopeChild := 3
  private const Int scopeVar   := 4

  private const Int typeElem := 0
  private const Int typeDir  := 1

  private const Str podName        // pod name of file
  private const Str filename       // filename for input stream
  private InStream in              // input
  private Int line := 1            // current line
  private Int scope := scopeNone   // current lex scope
  private StrBuf buf := StrBuf()   // resuse buf in nextToken
}
