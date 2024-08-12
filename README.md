# Helpview.nvim

<p align="center">
    Decorations for <code>vimdoc/help</code> files in Neovim.
</p>

![hybrid_mode](https://github.com/OXY2DEV/helpview.nvim/blob/images/Main/helpview_hybrid_mode.gif)
![demo_mobile](https://github.com/OXY2DEV/helpview.nvim/blob/images/Main/helpview_demo_mobile.jpg)
![demo_2](https://github.com/OXY2DEV/helpview.nvim/blob/images/Main/helpview_demo_1.jpg)

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

### 🌒 Rocks.nvim

You can install the plugin using `:Rocks install`.

```vim
:Rocks install helpview.nvim
```

### 👾 GitHub releases

Check the [releases](https://github.com/OXY2DEV/helpview.nvim/releases) tab to download the latest release.

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

## Highlight groups

For ease of configuration `helpview.nvim` comes with the following highlight groups.

### 💻 Code blocks and Inline codes

- `HelpviewCode`, background of code blocks. From `Normal`.
- `HelpviewCodeLanguage`, background for language names. From `Comment`.

### 🔖 Headings

- `HelpviewHeading1`, from `DiagnosticOk`.
- `HelpviewHeading2`, from `DiagnosticHint`.
- `HelpviewHeading3`, from `DiagnosticInfo`.
- `HelpviewHeading4`, from `Special`.

### 📏 Horizontal rules

- `HelpviewGradient1`, from `Normal`.
- `HelpviewGradient2`
- `HelpviewGradient3`
- `HelpviewGradient4`
- `HelpviewGradient5`
- `HelpviewGradient6`
- `HelpviewGradient7`
- `HelpviewGradient8`
- `HelpviewGradient9`
- `HelpviewGradient10`, from `Tag`.

### 🤔 Others

- `HelpviewTaglink`, from `Title`.
- `HelpviewOptionlink`, from `Tag`.
- `HelpviewMentionlink`, from `Title`.

### 📖 Title

- `HelpviewTitle`, from `DiagnosticWarn`.

