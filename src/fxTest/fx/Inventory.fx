//////////////////////////////////////////////////////////////////////////
// Structs
//////////////////////////////////////////////////////////////////////////

struct Widget
{
  Str name
  Float price
}

//////////////////////////////////////////////////////////////////////////
// InventoryMgr
//////////////////////////////////////////////////////////////////////////

comp InventoryMgr
{
  data
  {
    Widget[] items
    Str flash
  }

  style
  {
    & div.flash { background: #f0f; color: #fff; min-height: 10px; }

    & div.sidebar {
      box-sizing: border-box;
      width: 35%;
      height: 200px;
      background: #fff;
      float: left;
      border: 1px solid #d9d9d9;
      overflow-x: hidden;
      overflow-y: auto;
    }

    & div.content {
      box-sizing: border-box;
      margin-left: calc(35% + 10px);
      height: 200px;
      background: #fff;
      border: 1px solid #d9d9d9;
    }
  }

  template
  {
    <div class="flash">{{flash}}</div>
    <InventoryToolbar fx-bind:items="items" fx-bind:flash="flash"/>
    <InventorySidebar />
    <InventoryContent />
  }
}

//////////////////////////////////////////////////////////////////////////
// InventoryToolbar
//////////////////////////////////////////////////////////////////////////

comp InventoryToolbar
{
  data
  {
    extern Widget[] items
    extern Str flash
  }

  update(Str msg)
  {
    if (msg == "new")
    {
      // TODO: pop up dialog...
      items.add(Widget {
        it.name  = "New Item"
        it.price = 12.50f
      })
      echo(items)
    }
    else { flash = "Did this work [$DateTime.now]" }
  }

  style
  {
    & { padding: 5px 0; background: #f00; }

    & button {
      font-size: 100%;
      background: #fcfcfc;
      border: 1px solid #bbb;
      border-radius: 3px;
      padding: 4px 10px;
    }

    & button:active {
      color: #333;
      background: #ddd;
    }
  }

  template
  {
    <button fx-click="new">New Widget</button>
    <button fx-click="test">Test</button>
  }
}

//////////////////////////////////////////////////////////////////////////
// InventorySidebar
//////////////////////////////////////////////////////////////////////////

comp InventorySidebar
{
  data
  {
    extern Widget[] items
  }

  update(Str msg)
  {
  }

  style
  {
    & { height: 100px; background: #080; }
  }

  template
  {
    <div></div>
  }
}

//////////////////////////////////////////////////////////////////////////
// InventoryContent
//////////////////////////////////////////////////////////////////////////

comp InventoryContent
{
  data
  {
  }

  update(Str msg)
  {
  }

  style
  {
    & { height: 100px; background: #ff0; }
  }

  template
  {
    <div></div>
  }
}