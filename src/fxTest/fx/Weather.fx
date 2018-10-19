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
    Err? err
  }

  init
  {
    "geoloc"
  }

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

  update(Obj msg)
  {
    if (msg == "geoloc")
    {
      geoStatus = "Locating..."
      Win.cur.geoCurPosition(
        |geo| { update(geo) },
        |err| { update(err) }
      )
    }
    else if (msg is DomCoord)
    {
      geo = msg
      geoStatus = "You are at $geo.lat, $geo.lng"
      wxStatus  = "Loading weather data..."
      update("")

      sreq := HttpReq {}
      sreq.uri = `https://api.weather.gov/points/${geo.lat.toInt},${geo.lng.toInt}`
      sreq.get |sres|
      {
        Map json  := JsonInStream(sres.content.in).readJson
        Map props := json["properties"]
        Str stid  := props["radarStation"]

        creq := HttpReq {}
        creq.uri = `https://w1.weather.gov/xml/current_obs/display.php?stid=${stid}`
        creq.get |cres|
        {
          doc  := XParser(cres.content.in).parseDoc
          stat := doc.root.elem("station_id").text.val
          loc  := doc.root.elem("location").text.val
          temp := doc.root.elem("temp_f").text.val
          cond := doc.root.elem("weather").text.val

          wxStatus = "The current conditions are ${temp}\u00B0F and ${cond}"
          wxStationInfo = "${stat} \u2013 ${loc}"
          update("")
        }
      }
    }
    else if (msg is Err)
    {
      err = msg
      geoStatus = ""
      wxStatus  = ""
    }
  }

  template
  {
    <h2 fx-if="err" style="color:#e74c3c">{{err.msg}}</h2>
    <h2 fx-ifnot:class:loading="geo">{{geoStatus}}</h2>
    <h2 fx-ifnot:class:loading="wxStationInfo">{{wxStatus}}</h2>
    <p>{{wxStationInfo}}</p>
  }
}