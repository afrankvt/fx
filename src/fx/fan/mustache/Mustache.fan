//
// Copyright (c) 2011, Xored Software Inc.
// Licensed under the MIT License
//

**
** Mustache can be used for HTML, config files, source code - anything.
** It works by expanding tags in a template using values provided in a
** hash or object.
**
** We call it "logic-less" because there are no if statements, else
** clauses, or for loops. Instead there are only tags. Some tags are
** replaced with a value, some nothing, and others a series of values.
**
** A typical Mustache template:
**
** pre>
** Hello {{name}}
** You have just won ${{value}}!
** {{#in_ca}}
** Well, ${{taxed_value}}, after taxes.
** {{/in_ca}}
** <pre
**
** Given the following hash:
**
** pre>
** [ "name": "Chris",
**   "value": 10000,
**   "taxed_value": |->Decimal| { return 10000.0 - (10000.0 * 0.4) },
**   "in_ca": true
** ]
** <pre
**
** Will produce the following:
**
** pre>
** Hello Chris
** You have just won $10000!
** Well, $6000.0, after taxes.
** <pre
**
** This doc is based on original mustache man page:
** http://mustache.github.com/mustache.5.html
**

@Js const class Mustache
{
  private const MustacheToken compiledTemplate

  static const Str specVersion := "1.1.2"

  new make(InStream templateStream,
          Str otag:="{{",
          Str ctag:="}}") {
    this.compiledTemplate = MustacheParser {
      in = templateStream
      it.otag = otag
      it.ctag = ctag
    }.parse
  }

  new forParser(MustacheParser parser) {
    this.compiledTemplate = parser.parse
  }

  Str render(Obj? context:=null, [Str:Mustache] partials:=[:], Obj?[] callStack := [,], Str indentStr := "") {
    StrBuf output:=StrBuf()
    callStack.insert(0, this)
    callStack.insert(0, context)
    compiledTemplate.render(output,context,partials, callStack, indentStr)
    callStack.remove(0)
    callStack.remove(0)
    return output.toStr
  }

  Void _dumpTree() { echo("${compiledTemplate.toStr}") }

}
