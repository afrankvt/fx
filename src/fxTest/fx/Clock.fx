comp Clock
{
  data
  {
    Str time
  }

  template
  {
    <h2>The current time is {{time}}</h2>
  }

  onMsg(Obj msg) //, init := "tick")
  {
    if (msg == "tick")
    {
      time = DateTime.now.toLocale
      sendLater("tick", 1sec)
    }
  }
}