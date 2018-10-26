//////////////////////////////////////////////////////////////////////////
// Structs
//////////////////////////////////////////////////////////////////////////

struct Widget
{
  Str name
  Float price
  Bool selected

  // computed struct props?
  // Float priceDisplay() { price.toLocale("#.00") }
}

// // "global" style block?
// style
// {
//   // LESS-style nested rules where we can use comp.name === div[fx-comp="xxx"]
//   InventoryToolbar
//   {
//   }
// }

//////////////////////////////////////////////////////////////////////////
// InventoryMgr
//////////////////////////////////////////////////////////////////////////

comp InventoryMgr
{
  data
  {
    Widget[] items
    Str flash
    Bool showAddItem
  }

  style
  {
    & div.flash { background: #27ae60; color: #fff; padding: 10px; }
    & div.flash span { padding: 0 5px; float: right; cursor: default; }
    & div.flash span:hover { background: #2ecc71; }
  }

  template
  {
    <div>
      // flash
      [if flash]
        <div class="flash">
          {{flash}} <span @click="dismiss-flash">X</span>
        </div>
      [/if]

      // main content
      <InventoryToolbar &showAddItem />
      <InventorySidebar />
      <InventoryContent />

      // modals
      [if showAddItem]<AddItemModal &flash &showAddItem />[/if]
    </div>
  }

  init { "init" }

  Void onUpdate(FxMsg msg)
  {
    switch (msg.name)
    {
      case "init":
        items = [
          Widget { it.name="Nuts";    it.price=1.25f },
          Widget { it.name="Bolts";   it.price=0.75f },
          Widget { it.name="Washers"; it.price=0.12f }
        ]
      case "dismiss-flash": flash = ""
    }
  }
}

//////////////////////////////////////////////////////////////////////////
// InventoryToolbar
//////////////////////////////////////////////////////////////////////////

comp InventoryToolbar
{
  data
  {
    extern Bool showAddItem
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
    <button @click="new">New Widget</button>
  }

  Void onUpdate(FxMsg msg)
  {
    if (msg.name == "new") showAddItem = true
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

    & div.list-item {
      padding: 10px 20px;
      border-bottom: 1px solid #f8f8f8;
      cursor: default;
    }

    & div.list-item span.price {
      float: right;
    }

    & div.list-item.selected {
      background: #3498db;
      color: #fff;
      border-color: #2980b9;
    }
  }

  template
  {
    <div>
      [for item,index in items]
        <div class="list-item" fx-if:item.selected:class="selected"
             @click="select [index:{{index}}]">
          {{index}}: {{item.name}}
          <span class="price">${{item.price}}</span>
        </div>
      [/for]
    </div>
  }

  Void onUpdate(FxMsg msg)
  {
    if (msg.name == "select")
      items.each |item,i| { item.selected = i == msg->index }
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

  Void onUpdate(FxMsg msg)
  {
  }
}

//////////////////////////////////////////////////////////////////////////
// AddItemModal
//////////////////////////////////////////////////////////////////////////

comp AddItemModal
{
  data
  {
    extern Widget[] items
    extern Bool showAddItem
    extern Str flash
    Str name
    Float price
  }

  style
  {
    & div.mask {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0,0,0,0.25);
    }

    & div.modal {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      padding: 20px;
      background: #fff;
      border: 1px solid #ccc;
      box-shadow: #777 0px 6px 16px;
    }

    & h2 { margin: 0; }

    & div.modal div:last-child { text-align: right; }

    & label { display: inline-block; min-width: 90px; }
    & input[type=text] {
      border: 1px solid #bbb;
      padding: 6px;
      font-face: inherit;
      font-size: 100%;
    }

    & button {
      font-size: 100%;
      background: #fcfcfc;
      border: 1px solid #bbb;
      border-radius: 3px;
      padding: 4px 10px;
      min-width: 70px;
    }

    & button:active {
      color: #333;
      background: #ddd;
    }
  }

  template
  {
    <div>
      <div class="mask"></div>
      <div class="modal">
        <h2>Add Item</h2>
        <p>
          <label>Item Name:</label>
          <input fx-form="name" type="text" size="40" autofocus />
        </p>
        <p>
          <label>Item Price:</label>
          <input fx-form="price" type="text" size="20" />
        </p>
        <div>
          <button @click="ok">Ok</button>
          <button @click="close">Cancel</button>
        </div>
      </div>
    </div>
  }

  Void onUpdate(FxMsg msg)
  {
    switch (msg.name)
    {
      case "ok":
        items.add(Widget { it.name=this.name; it.price=this.price })
        flash = "Item added ${this.name}"
        showAddItem = false

      case "close":
        showAddItem = false
    }
  }
}
