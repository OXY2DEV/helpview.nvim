# Helpview.nvim

<p align="center">
    Decorations for <code>vimdoc/help</code> files in Neovim.
</p>

## Features

Helpview provides quite a few features such as,

- Provides decorations for various vimdoc elements such as,
  * Titles
  * Headings
  * Tags
  * Tag links
  * Option links
  * Attributes
  * Highlight group name(names surrounded with `$`).
  * Horizontal rules
  * Code blocks etc.
- Hybrid mode for previewing and editing together.
- Highly performant even on very large files.
- Dynamic highlight groups!

And a lot more to come.

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

