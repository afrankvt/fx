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

  init { "tick" }

  Void onUpdate(FxMsg msg)
  {
    if (msg.name == "tick")
    {
      time = DateTime.now.toLocale
      sendLater("tick", 1sec)
    }
  }
}