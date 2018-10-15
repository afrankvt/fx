//////////////////////////////////////////////////////////////////////////
// Structs
//////////////////////////////////////////////////////////////////////////

struct Widget
{
  Str name
  Float price
  Bool selected
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

  update(Str msg)
  {
    if (msg == "dismiss-flash") flash = ""
  }

  style
  {
    & div.flash { background: #27ae60; color: #fff; padding: 10px; }
    & div.flash span.close { padding: 0 5px; float: right; cursor: default; }
    & div.flash span.close:hover { background: #2ecc71; }
  }

  template
  {
    // TODO: close button to remove flash banner
    <div fx-if="flash" class="flash">
      {{flash}}
      <span fx-click="dismiss-flash" class="close">X</span>
    </div>
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
    if (msg.startsWith("select"))
    {
      index := msg.split.last.toInt
      items.each |item,i| { item.selected = i == index }
    }
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

    & div.list-item div {
      padding: 10px 20px;
      border-bottom: 1px solid #f8f8f8;
    }

    & div.list-item div span.price {
      float: right;
    }

    & div.list-item div.selected {
      background: #3498db;
      color: #fff;
      border-color: #2980b9;
    }
  }

  template
  {
    <div class="list-item" fx-for="(item,index) in items">
      <div fx-if:class:selected="item.selected" fx-click="select {{index}}">
        {{index}}: {{item.name}}
        <span class="price">${{item.price}}</span>
      </div>
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