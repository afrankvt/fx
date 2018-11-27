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
  comma,
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
  Bool isComma()      { type == TokenType.comma      }
  Bool isEos()        { type == TokenType.eos        }
}

*************************************************************************
** CParser
*************************************************************************

internal class CParser
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
  CDef[] parse()
  {
    defs := CDef[,]
    Token? token

    while ((token = nextToken).isEos == false)
    {
      if (token.isKeyword)
      {
        if (token.val == "using")  { defs.add(parseUsing);  continue }
        if (token.val == "struct") { defs.add(parseStruct); continue }
        if (token.val == "comp")   { defs.add(parseComp);   continue }
        throw parseErr("Invalid keyword '$token.val'")
      }
      throw unexpectedToken(token)
    }

    return defs
  }

//////////////////////////////////////////////////////////////////////////
// Using
//////////////////////////////////////////////////////////////////////////

  ** Parse 'using' definition.
  private CDef parseUsing()
  {
    pod := nextToken(TokenType.identifier).val
    return CUsingDef { it.pod=pod }
  }

//////////////////////////////////////////////////////////////////////////
// Struct
//////////////////////////////////////////////////////////////////////////

  ** Parse 'struct' definition.
  private CDef parseStruct()
  {
    name  := nextToken(TokenType.typeName).val
    props := CPropDef[,]

    nextToken(TokenType.braceOpen)
    token := nextToken
    while (!token.isBraceClose)
    {
      if (token.isTypeName)
      {
        ptype  := token.val
        pname  := nextToken(TokenType.identifier).val
        defVal := null
        token = nextToken
        if (token.val == ":=")
        {
          defVal = parseToEol
          token  = nextToken
        }
        props.add(CPropDef { it.extern=false; it.type=ptype; it.name=pname; it.defVal=defVal })
      }
      else throw unexpectedToken(token)
    }

    return CStructDef
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
  private CDef parseComp()
  {
    CDataDef? data
    CInitDef? init
    CStyleDef? style
    CTemplateDef? template
    CFuncDef[] funcs := [,]

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
        throw parseErr("Invalid keyword '$token.val'")
      }
      if (token.isTypeName) { funcs.add(parseFunc(token)); token=nextToken; continue }
      throw unexpectedToken(token)
    }

    // template is required
    if (template == null) throw parseErr("Required template definition not found")

    return CCompDef
    {
      it.qname    = "${podName}::$name"
      it.name     = name
      it.data     = data  ?: CDataDef {}
      it.init     = init  ?: CInitDef {}
      it.style    = style ?: CStyleDef {}
      it.template = template
      it.funcs    = funcs
    }
  }

  ** Parse a 'data' definition block.
  private CDef parseData()
  {
    props := CPropDef[,]

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
        ptype  := token.val
        pname  := nextToken(TokenType.identifier).val
        defVal := null
        token = nextToken
        if (token.val == ":=")
        {
          defVal = parseToEol
          token  = nextToken
        }
        props.add(CPropDef { it.extern=extern; it.type=ptype; it.name=pname; it.defVal=defVal })
      }
      else throw unexpectedToken(token)
    }

    return CDataDef { it.props=props }
  }

  ** Parse a 'init' definition block.
  private CDef parseInit()
  {
    msg := parseRawBlock
    return CInitDef { it.msg=msg }
  }

  ** Parse a 'style' definition block.
  private CDef parseStyle()
  {
    css := parseRawBlock
    return CStyleDef { it.css=css }
  }

  ** Parse a 'template' definition block.
  private CDef parseTemplate()
  {
    start  := line
    markup := parseRawBlock
    nodes  := CTemplateParser(podName, filename, Buf().print(markup).flip.in, start).parse
    return CTemplateDef { it.nodes=nodes }
  }

  ** Parse a 'func' definition block.
  private CDef parseFunc(Token token)
  {
    // method sig
    retType  := token.val
    funcName := nextToken(TokenType.identifier).val
    funcArgs := Str[,]
    token = nextToken(TokenType.parenOpen)
    token = nextToken
    while (!token.isParenClose)
    {
      if (token.isComma) token = nextToken
      argType := token.val
      argName := nextToken(TokenType.identifier).val
      funcArgs.add("$argType $argName")
      token = nextToken
    }

    // method body
    funcBody := parseRawBlock

    return CFuncDef
    {
      it.retType  = retType
      it.funcName = funcName
      it.funcArgs = funcArgs
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
    if (ch == ':' && peek == '=') { read; return Token(TokenType.assign, ":=") }
    if (ch == ',') return Token(TokenType.comma, ch.toChar)

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

  ** Parse till end of line.
  private Str parseToEol()
  {
    // TODO: cheap temp hack until we can parse Fantom defVal statements
    buf.clear
    Int? ch
    while (peek != '\n' && peek != null)
    {
      ch = read
      buf.addChar(ch)
    }
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
