comp HelloWorld
{
  data
  {
    Int count
  }

  update(Str msg)
  {
    if (msg == "inc") count++
    else if (msg == "dec") count--
  }

  template
  {
    <p>The current value of <b>count</b> is <b>{{count}}</b></p>
    <p>
      <button fx-click="dec">--</button>
      <button fx-click="inc">++</button>
    </p>
  }
}