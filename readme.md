# FX: Fantom JavaScript Framework

Under VOLATILE Construction :)

```fantom
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
```

## Running Tests

NOTE: fx currently requires running Fantom tip from hg repo.

Clone repo, build, and open `index.html` in browser:

    $ git clone https://github.com/afrankvt/fx.git
    $ cd fx
    $ src/fx/build.fan
    $ src/fxTest/build.fan
    $ open src/fxTest/test/index.html
