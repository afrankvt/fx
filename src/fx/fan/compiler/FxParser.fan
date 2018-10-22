//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   20 Sep 2018  Andy Frank  Creation
//

*************************************************************************
** TokenType
*************************************************************************

internal enum class TokenType
{
  keyword,
  typeName,
  identifier,
  braceOpen,
  braceClose,
  parenOpen,
  parenClose,
  assign,
  comment,
  eos
}

*************************************************************************
** Token
*************************************************************************

internal const class Token
{
  ** Ctor.
  new make(TokenType t, Str v) { this.type=t; this.val=v }

  ** Token type.
  const TokenType type

  ** Token literval val.
  const Str val

  Bool isComment()    { type == TokenType.comment    }
  Bool isKeyword()    { type == TokenType.keyword    }
  Bool isTypeName()   { type == TokenType.typeName   }
  Bool isIdentifier() { type == TokenType.identifier }
  Bool isBraceOpen()  { type == TokenType.braceOpen  }
  Bool isBraceClose() { type == TokenType.braceClose }
  Bool isParenOpen()  { type == TokenType.parenOpen  }
  Bool isParenClose() { type == TokenType.parenClose }
  Bool isAssign()     { type == TokenType.assign     }
  Bool isEos()        { type == TokenType.eos        }
}

*************************************************************************
** FxParser
*************************************************************************

internal class FxParser
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Ctor.
  new make(Str podName, Str filename, InStream in)
  {
    this.podName = podName
    this.filename = filename
    this.in = in
  }

  ** Parse input stream.
  FxNode[] parse()
  {
    nodes := FxNode[,]
    Token? token

    while ((token = nextToken).isEos == false)
    {
      if (token.isKeyword)
      {
        if (token.val == "using")  { nodes.add(parseUsing);  continue }
        if (token.val == "struct") { nodes.add(parseStruct); continue }
        if (token.val == "comp")   { nodes.add(parseComp);   continue }
        throw parseErr("Invalid keyword '$token.val'")
      }
      throw unexpectedToken(token)
    }

    return nodes
  }

//////////////////////////////////////////////////////////////////////////
// Using
//////////////////////////////////////////////////////////////////////////

  ** Parse 'using' definition.
  private FxNode parseUsing()
  {
    pod := nextToken(TokenType.identifier).val
    return FxUsingDef { it.pod=pod }
  }

//////////////////////////////////////////////////////////////////////////
// Struct
//////////////////////////////////////////////////////////////////////////

  ** Parse 'struct' definition.
  private FxNode parseStruct()
  {
    name  := nextToken(TokenType.typeName).val
    props := FxPropDef[,]

    nextToken(TokenType.braceOpen)
    token := nextToken
    while (!token.isBraceClose)
    {
      if (token.isTypeName)
      {
        ptype := token.val
        pname := nextToken(TokenType.identifier).val
        // TODO: defVal
        token = nextToken
        props.add(FxPropDef { it.extern=false; it.type=ptype; it.name=pname })
      }
      else throw unexpectedToken(token)
    }

    return FxStructDef
    {
      it.qname = "${podName}::$name"
      it.name  = name
      it.props = props
    }
  }

//////////////////////////////////////////////////////////////////////////
// Comp
//////////////////////////////////////////////////////////////////////////

  ** Parse 'comp' definition.
  private FxNode parseComp()
  {
    FxDataDef? data
    FxInitDef? init
    FxStyleDef? style
    FxTemplateDef? template
    FxMsgDef? msg

    name := nextToken(TokenType.typeName).val

    nextToken(TokenType.braceOpen)
    token := nextToken
    while (!token.isBraceClose)
    {
      if (token.isKeyword)
      {
        if (token.val == "data")     { data     = parseData;     token=nextToken; continue }
        if (token.val == "init")     { init     = parseInit;     token=nextToken; continue }
        if (token.val == "style")    { style    = parseStyle;    token=nextToken; continue }
        if (token.val == "template") { template = parseTemplate; token=nextToken; continue }
        if (token.val == "onMsg")    { msg      = parseMsg;      token=nextToken; continue }
        throw parseErr("Invalid keyword '$token.val'")
      }
      throw unexpectedToken(token)
    }

    return FxCompDef
    {
      it.qname    = "${podName}::$name"
      it.name     = name
      it.data     = data     ?: FxDataDef {}
      it.init     = init     ?: FxInitDef {}
      it.style    = style    ?: FxStyleDef {}
      it.template = template ?: FxTemplateDef {}
      it.msg      = msg      ?: FxMsgDef {}
    }
  }

  ** Parse a 'data' definition block.
  private FxNode parseData()
  {
    props := FxPropDef[,]

    nextToken(TokenType.braceOpen)
    token := nextToken
    while (!token.isBraceClose)
    {
      // first check for extern keyword
      extern := false
      if (token.isKeyword && token.val == "extern")
      {
        extern = true
        token  = nextToken
      }

      // then parse property def
      if (token.isTypeName)
      {
        ptype := token.val
        pname := nextToken(TokenType.identifier).val
        // TODO: defVal
        token = nextToken
        props.add(FxPropDef { it.extern=extern; it.type=ptype; it.name=pname })
      }
      else throw unexpectedToken(token)
    }

    return FxDataDef { it.props=props }
  }

  ** Parse a 'init' definition block.
  private FxNode parseInit()
  {
    msg := parseRawBlock
    return FxInitDef { it.msg=msg }
  }

  ** Parse a 'style' definition block.
  private FxNode parseStyle()
  {
    css := parseRawBlock
    return FxStyleDef { it.css=css }
  }

  ** Parse a 'template' definition block.
  private FxNode parseTemplate()
  {
    start  := line
    markup := parseRawBlock
    nodes  := FxTemplateParser(podName, filename, Buf().print(markup).flip.in, start).parse
    return FxTemplateDef { it.nodes=nodes }
  }

  ** Parse a 'msg' definition block.
  private FxNode parseMsg()
  {
    // method sig
    nextToken(TokenType.parenOpen)
    argType := nextToken(TokenType.typeName).val
    argName := nextToken(TokenType.identifier).val
    nextToken(TokenType.parenClose)

    // method body
    funcBody := parseRawBlock

    return FxMsgDef
    {
      it.argType  = argType
      it.argName  = argName
      it.funcBody = funcBody
    }
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizer
//////////////////////////////////////////////////////////////////////////

  ** Read next token from stream or 'null' if EOS.  If 'type' is
  ** non-null and does match read token, throw ParseErr.
  private Token nextToken(TokenType? type := null)
  {
    // read next non-comment token
    token := parseNextToken
    while (token?.isComment == true) token = parseNextToken

    // wrap in eos if hit end of file
    if (token == null) token = Token(TokenType.eos, "")

    // check match
    if (type != null && token?.type != type) throw unexpectedToken(token)

    return token
  }

  ** Read next token from stream or 'null' if EOS.
  private Token? parseNextToken()
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
      while (ch != '\n' && ch != null)
      {
        buf.addChar(ch)
        ch = read
      }
      return Token(TokenType.comment, buf.toStr)
    }

    // type
    if (ch.isUpper)
    {
      // just read in any valid type char; delegate to fantom compiler
      // to check if the name is properly formatted
      buf.addChar(ch)
      while (peek != null && (peek.isAlphaNum || typeChars[peek] != null)) buf.addChar(read)
      return Token(TokenType.typeName, buf.toStr)
    }

    // keywword | identifer
    if (ch.isAlpha)
    {
      buf.addChar(ch)
      while (peek != null && (peek.isAlphaNum || peek == '_'))
      {
        buf.addChar(read)
      }
      val  := buf.toStr
      type := keywords[val] != null ? TokenType.keyword : TokenType.identifier
      return Token(type, val)
    }

    // braces
    if (ch == '{') return Token(TokenType.braceOpen,  ch.toChar)
    if (ch == '}') return Token(TokenType.braceClose, ch.toChar)

    // parens
    if (ch == '(') return Token(TokenType.parenOpen,  ch.toChar)
    if (ch == ')') return Token(TokenType.parenClose, ch.toChar)

    // operators
    if (ch == ':' && peek == '=') return Token(TokenType.assign, ":=")

    throw parseErr("Invalid char 0x${ch.toHex} ($ch.toChar)")
  }

  ** Read in a raw block contained between { and } tokens.
  private Str parseRawBlock()
  {
    buf.clear
    Int? ch
    depth := 1

    nextToken(TokenType.braceOpen)

    while (peek != null && depth > 0)
    {
      ch = read
      if (depth == 1 && ch == '}') depth--
      if (depth > 0)
      {
        if (ch == '{') depth++
        if (ch == '}') depth--
        buf.addChar(ch)
      }
    }

    if (ch != '}') throw unexpectedToken(Token(TokenType.braceClose, "}"))
    return buf.toStr
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

  ** Throw ParseErr
  private Err parseErr(Str msg)
  {
    ParseErr("${msg} [${filename}:$line]")
  }

  ** Throw ParseErr
  private Err unexpectedToken(Token token)
  {
    token.isEos
      ? ParseErr("Unexpected end of stream [${filename}:$line]")
      : ParseErr("Unexpected token: '$token.val' [${filename}:$line]")
  }

  private static const Int:Int typeChars := [:].setList([
    '_', '?', ':', '[', ']'
  ])

  private static const Str:Str keywords := [:].setList([
    "using", "struct", "comp", "data", "extern", "init", "onMsg", "style", "template"
  ])

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str podName        // podName
  private const Str filename       // name of file to parse
  private InStream in              // input
  private Int line := 1            // current line
  private StrBuf buf := StrBuf()   // resuse buf in nextToken
}
