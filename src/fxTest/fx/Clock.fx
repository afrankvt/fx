comp Clock
{
  data
  {
    Str time
  }

  init { "tick" }

  update(Obj msg)
  {
    if (msg == "tick")
    {
      time = DateTime.now.toLocale
      update("tick", 1sec)
    }
  }

  template
  {
    <h2>The current time is {{time}}</h2>
  }
}