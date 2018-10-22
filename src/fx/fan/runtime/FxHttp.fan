//
// Copyright (c) 2018, Andy Frank
// Licensed under the MIT License
//
// History:
//   19 Oct 2018  Andy Frank  Creation
//

using dom

**
** HTTP utilites for FX components.
**
@Js const class FxHttp
{
  ** Send a GET request to given URI.
  static Void get(Uri uri, |Str res| onOk, |Str res| onErr)
  {
    req := HttpReq { it.uri = uri }
    req.get |res|
    {
      if (res.status == 200) onOk(res.content)
      else onErr(res.content)
    }
  }

  ** Send a POST request to given URI with given content.
  static Void post(Uri uri, Obj content, |Str res| onOk, |Str res| onErr)
  {
    req := HttpReq { it.uri = uri }
    req.post(content) |res|
    {
      if (res.status == 200) onOk(res.content)
      else onErr(res.content)
    }
  }
}