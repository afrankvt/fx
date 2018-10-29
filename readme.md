# FX: Fantom JavaScript Framework

Under VOLATILE Construction :)

```fantom
comp HelloWorld
{
  data
  {
    Int count
  }

  template
  {
    <div>
      <p>The current value of <b>count</b> is <b>{{count}}</b></p>
      <p>
        <button @click="dec">--</button>
        <button @click="inc">++</button>
      </p>
    </div>
  }

  Void update(FxMsg msg)
  {
    switch (msg.name)
    {
      case "inc": count++
      case "dec": count--
    }
  }
}
```

## Running Tests

NOTE: fx currently requires running Fantom tip from hg repo.

Clone repo, build, and open `index.html` in browser:

    $ git clone https://github.com/afrankvt/fx.git
    $ cd fx
    $ src/fx/build.fan
    $ src/fxTest/build.fan
    $ open src/fxTest/test/index.html
