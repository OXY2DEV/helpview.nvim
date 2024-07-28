# Helpview.nvim

A fancy viewer for `vimdoc`/`help` files.

>[!WARNING]
> This plugin is in it's alpha phase. Breaking changes may occur.

## Features

- Fully customisable `inline elements`. Currently supported elements,
  + tag
  + taglink
  + optionlink
  + keycodes
  + arguments
  + notes(includes `Warning` & `deprecated` too?
  + cosdespan
- Modeline support.
- Code block support with language string(no icons).
- Various heading levels & title support.
- Horizontal rules support.

## Requirements

- Neovim version 0.10.0 or higher.
- Treesitter parser for `vimdoc`(install it via `:TSInstall vimdoc` if you use `nvim-treesitter`).

## Installation

### 💤 Lazy.nvim

>[!CAUTION]
> Lazy loading isn't necessary for this plugin and is therefore discouraged.

For `lazy.lua` users:

```lua
{
    "OXY2DEV/helpview.nvim",
    lazy = false, -- Recommended

    -- In case you still want to lazy load
    -- ft = "help",

    dependencies = {
        "nvim-treesitter/nvim-treesitter"
    }
}
```

For `lazy/helpview.lua` users:

```lua
return {
    "OXY2DEV/helpview.nvim",
    lazy = false, -- Recommended

    -- In case you still want to lazy load
    -- ft = "help",

    dependencies = {
        "nvim-treesitter/nvim-treesitter"
    }
}
```

### 🦠 Mini.deps

```lua
local MiniDeps = require("mini.deps");

MiniDeps.add({
    source = "OXY2DEV/helpview.nvim",

    depends = {
        "nvim-treesitter/nvim-treesitter"
    }
});
```

### Others

Installation process for other plugin managers are similar.

```vim
Plug "nvim-treesitter/nvim-treesitter";
Plug "OXY2DEV/helpview.nvim";
```

## Commands

The plugin comes with the `Helpview` command. It has the following sub-commands,

- toggleAll

  Toggles the plugin itself.

- enableAll

  Enables the plugin.

- disableAll

  Disables the plugin

- toggle {buffer}

  Toggles the plugin on the specific buffer.

- enable {buffer}

  Enables the plugin on the specific buffer.

- disable {buffer}

  Disables the plugin on the specific buffer.

---

Check out the help files(via `:h helpview.nvim`) to learn more!

