using util
using xml

comp Weather
{
  data
  {
    Str geoStatus
    Str wxStatus
    Str wxStationInfo
    DomCoord? geo
    Str? err
  }

  init { "geoloc" }

  style
  {
    @keyframes pulse {
      0%   { transform: scale(1);    }
      50%  { transform: scale(1.02); }
      100% { transform: scale(1);    }
    }

    & .loading {
      opacity: 0.3;
      transform-origin: center left;
      animation: pulse 1s linear infinite;
    }
  }

  template
  {
    <div>
      <h2 if err style="color:#e74c3c">{{err.msg}}</h2>
      <h2 ifnot loading class="geo">{{geoStatus}}</h2>
      <h2 ifnot loading class="wxStationInfo">{{wxStatus}}</h2>
      <p>{{wxStationInfo}}</p>
    </div>
  }

  Void onUpdate(FxMsg msg)
  {
    if (msg.name == "geoloc")
    {
      geoStatus = "Locating..."
      Win.cur.geoCurPosition(
        |geo| { send("load", ["geo":geo]) },
        |Err err| { send("err",  ["err":err.msg]) }
      )
    }
    else if (msg.name == "load")
    {
      geo = msg->geo
      geoStatus = "You are at $geo.lat, $geo.lng"
      wxStatus  = "Loading weather data..."
      send("")

      sreq := HttpReq {}
      sreq.uri = `https://api.weather.gov/points/${geo.lat.toInt},${geo.lng.toInt}`
      sreq.get |sres|
      {
        if (sres.status != 200) return send("err", ["err":"Request faild"])

        Map json  := JsonInStream(sres.content.in).readJson
        Map props := json["properties"]
        Str stid  := props["radarStation"]

        creq := HttpReq {}
        creq.uri = `https://w1.weather.gov/xml/current_obs/display.php?stid=${stid}`
        creq.get |cres|
        {
          if (cres.status != 200) return send("err", ["err":"Request faild"])

          doc  := XParser(cres.content.in).parseDoc
          stat := doc.root.elem("station_id").text.val
          loc  := doc.root.elem("location").text.val
          temp := doc.root.elem("temp_f").text.val
          cond := doc.root.elem("weather").text.val

          wxStatus = "The current conditions are ${temp}\u00B0F and ${cond}"
          wxStationInfo = "${stat} \u2013 ${loc}"
          send("")
        }
      }
    }
    else if (msg.name == "err")
    {
      err = msg->err
      geoStatus = ""
      wxStatus  = ""
    }
  }
}