struct Item
{
  Str name
  Bool selected
}

comp List
{
  data
  {
    Item[] items
    Item? selItem
  }

  style
  {
    & { padding-top: 1em }

    ul {
      border: 1px solid #d9d9d9;
      width: 400px;
      margin: 0;
      padding: 0;
      list-style: none;
      float: left;
    }

    li {
      display: block;
      padding: 10px;
      margin: 0;
      cursor: default;
    }

    li.selected {
      color: #fff;
      background: #2174bb;
    }

    h2 {
      padding-left: 420px;
      margin: 0;
    }
  }

  template
  {
    <div>
      // listbox
      <ul>
      [for item in items]
        <li
          if item.selected class="selected"
          @click="select [name:{item.name}]">
          {item.name}
        </li>
      [/for]
      </ul>
      // details
      [if selItem]
        <h2>Selected: {selItem.name}</h2>
      [/if]
    </div>
  }

  init { "init" }

  Void onUpdate(FxMsg msg)
  {
    switch (msg.name)
    {
      case "init":
        // TODO: move to inline data {} definition
        items.addAll([item("Alpha"), item("Beta"), item("Gamma"), item("Delta"), item("Epsilon")])

      case "select":
        items.each |item| { item.selected = item.name == msg->name }
        selItem = items.find |item| { item.selected }
    }
  }

  Item item(Str name)
  {
    Item { it.name=name }
  }
}