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
  slash,
  equal,
  varStart,
  varEnd,
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

  Bool isComment()      { type == TmTokenType.comment      }
  Bool isIdentifier()   { type == TmTokenType.identifier   }
  Bool isBracketOpen()  { type == TmTokenType.bracketOpen  }
  Bool isBracketClose() { type == TmTokenType.bracketClose }
  Bool isSlash()        { type == TmTokenType.slash        }
  Bool isText()         { type == TmTokenType.text         }
  Bool isVarStart()     { type == TmTokenType.varStart     }
  Bool isVarEnd()       { type == TmTokenType.varEnd       }
  Bool isEos()          { type == TmTokenType.eos          }
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
  FxNode[] parse()
  {
    nodes := FxNode[,]
    TmToken? token

    while ((token = nextToken).isEos == false)
    {
      // echo("$token.type: $token.val")
      if (token.isBracketOpen) { nodes.add(parseElem); continue }
      // throw unexpectedToken(token)
    }

    return nodes
  }

//////////////////////////////////////////////////////////////////////////
// Elem
//////////////////////////////////////////////////////////////////////////

  ** Parse an element.
  private FxNode parseElem()
  {
    tagName := nextToken(TmTokenType.identifier).val
    attrs   := Str:Str[:]
    kids    := FxNode[,]

    TmToken? token
    while ((token = nextToken).isEos == false)
    {
      // attr
      if (token.isIdentifier)
      {
        if (peek == '=')
        {
          name := token.val
          nextToken(TmTokenType.equal)
          val := nextToken(TmTokenType.attrVal).val
          attrs[name] = val
        }
        else
        {
          name := token.val
          attrs[name] = ""
        }
        continue
      }

      if (token.isBracketClose) continue

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
          if (close != tagName) throw parseErr("Tag names do not match '$tagName' != '$close'")
          nextToken(TmTokenType.bracketClose)
          break
        }
        else
        {
          // recurse
          kids.add(parseElem)
          continue
        }
      }

      if (token.isText)
      {
        kids.add(FxTmTextNode { it.text=token.val })
        continue
      }

      if (token.isVarStart)
      {
        name := nextToken(TmTokenType.identifier).val
        nextToken(TmTokenType.varEnd)
        kids.add(FxTmVarNode { it.name=name })
        continue
      }

      throw unexpectedToken(token)
    }

    return FxTmElemNode
    {
      it.tagName = tagName
      it.attrs   = attrs
      it.kids    = kids
      it.podName = this.podName // just always set
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

    // indentifer
    if ((isScopeTag || isScopeVar) && ch.isAlpha)
    {
      buf.addChar(ch)
      while (peek != null && (peek.isAlphaNum || peek == '-'))
      {
        buf.addChar(read)
      }
      return TmToken(TmTokenType.identifier, buf.toStr)
    }

    // attrVal
    if (ch == '\"')
    {
      while (peek != null && peek != '\"')
      {
        buf.addChar(read)
      }
      if (peek == '\"') read
      return TmToken(TmTokenType.attrVal, buf.toStr)
    }

    // brackets
    if (ch == '<') { scope=scopeTag;   return TmToken(TmTokenType.bracketOpen,  ch.toChar) }
    if (ch == '>') { scope=scopeChild; return TmToken(TmTokenType.bracketClose, ch.toChar) }
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

  private const Int scopeNone  := 0
  private const Int scopeTag   := 1
  private const Int scopeChild := 2
  private const Int scopeVar   := 3

  private const Str podName        // pod name of file
  private const Str filename       // filename for input stream
  private InStream in              // input
  private Int line := 1            // current line
  private Int scope := scopeNone   // current lex scope
  private StrBuf buf := StrBuf()   // resuse buf in nextToken
}
