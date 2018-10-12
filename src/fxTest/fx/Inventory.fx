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
    & div.flash { background: #27ae60; color: #fff; padding: 10px; }
  }

  template
  {
    // TODO: close button to remove flash banner
    <div class="flash">{{flash}}</div>
    <InventoryToolbar fx-bind:items fx-bind:flash />
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
      flash = "New widget added!"
    }
  }

  style
  {
    & { padding: 5px 0; }

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
    & {
      box-sizing: border-box;
      width: 35%;
      height: 200px;
      background: #fff;
      float: left;
      border: 1px solid #d9d9d9;
      overflow-x: hidden;
      overflow-y: auto;
    }

    & div.item {
      padding: 10px 20px;
      border-bottom: 1px solid #f8f8f8;
    }

    & div.item span.price {
      float: right;
    }
  }

  template
  {
    <div class="item" fx-for="item in items">
      {{item.name}}
      <span class="price">${{item.price}}</span>
    </div>
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
    & {
      box-sizing: border-box;
      margin-left: calc(35% + 10px);
      height: 200px;
      background: #fff;
      border: 1px solid #d9d9d9;
    }
  }

  template
  {
    <div>TODO</div>
  }
}