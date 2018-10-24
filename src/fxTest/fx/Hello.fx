comp HelloWorld
{
  data
  {
    Int count
  }

  template
  {
    // TODO: fix whitespace handling for text nodes :)
    <p>The current value of <b>count </b> is <b>{{count}}</b></p>
    <p>
      <button fx-click="dec">--</button>
      <button fx-click="inc">++</button>
    </p>
  }

  Void onUpdate(FxMsg msg)
  {
    if (msg.name == "inc") count++
    else if (msg.name == "dec") count--
  }
}