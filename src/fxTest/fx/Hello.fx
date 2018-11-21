comp HelloWorld
{
  data
  {
    Int count
  }

  template
  {
    // TODO: fix whitespace handling for text nodes :)
    <div>
      <p>The current value of <b>count</b> is <b>{count}</b></p>
      <p>
        <button @click="dec">--</button>
        <button @click="inc">++</button>
      </p>
    </div>
  }

  Void onUpdate(FxMsg msg)
  {
    if (msg.name == "inc") count++
    else if (msg.name == "dec") count--
  }
}