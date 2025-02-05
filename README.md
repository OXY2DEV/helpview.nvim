# 🧊 Helpview.nvim

<p align="center">
    A hackable & <i>fancy</i> vimdoc viewer for <code>Neovim</code>.
</p>

<img src="https://github.com/OXY2DEV/helpview.nvim/blob/images/v2/repo/helpview-1.png">
<img src="https://github.com/OXY2DEV/helpview.nvim/blob/images/v2/repo/helpview-2.png">
<img src="https://github.com/OXY2DEV/helpview.nvim/blob/images/v2/repo/helpview-3.png">

<img src="https://github.com/OXY2DEV/helpview.nvim/blob/images/v2/wiki/hybrid_mode-normal.png">

<!-- Images here -->

## 📖 Table of contents

- [✨ Features](#-features)
- [📚 Requirements](#-requirements)
- [📐 Installation](#-installation)
- [🧭 Configuration](#-configuration)

- [🎇 Commands](#-commands)
- [🎨 Highlight groups](#-highlight-groups)

## ✨ Features

- Adds various decorations to make `vimdoc` files *nicer* to look at.
- No external dependencies(other than the `vimdoc` parser)!
- Supports a variety of vimdoc syntaxes such as,

    + Arguments.
    + Code blocks.
    + Headings(& column headings).
    + Highlight group names.
    + Horizontal rules.
    + Inline codes.
    + Keycodes.
    + Vim modeline.
    + Notes.
    + Option links.
    + Tags.
    + Tag links.

- Custom renderer support.
- *Dynamic* highlight groups.
- Hybrid mode for viewing & writing together.
- Splitview for side-by-side viewing of the file being edited.
- Help command wrappers(`:Help`, `:H`) to change *where* help is shown.

## 📚 Requirements

System,

- **Neovim:** 0.10.3

---

Colorscheme,

- Any *tree-sitter* based colorscheme is recommended.

External icon providers,

>[!NOTE]
> You need to change the config to use the desired icon provider.
> 
> ```lua
> {
>     preview = {
>         icon_provider = "internal", -- "mini" or "devicons"
>     }
> }
> ```

- [mini.icons](https://github.com/echasnovski/mini.icons)
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)

Parsers,

>[!TIP]
> You can use `nvim-treesitter` to easily install parsers. You can install all the parsers with the following command,
> 
> ```vim
> :TSInstall vimdoc
> ```

- `vimdoc`

Fonts,

- *Nerd fonts* are recommended.

>[!TIP]
> It is recommended to run `:checkhealth helpview` after installing the plugin to check if any potential issues exist.

## 📐 Installation

### 🧩 Vim-plug

Add this to your plugin list.

```vim
Plug "OXY2DEV/helpview.nvim"
```

### 💤 Lazy.nvim

>[!WARNING]
> Do *not* lazy load this plugin as it is already lazy-loaded.
>
> Lazy-loading will cause **more time** for the previews to load when starting Neovim.

The plugin should be loaded *after* your colorscheme to ensure the correct highlight groups are used.

```lua
-- For `plugins/helpview.lua` users.
return {
    "OXY2DEV/helpview.nvim",
    lazy = false
};
```

```lua
-- For `plugins.lua` users.
{
    "OXY2DEV/helpview.nvim",
    lazy = false
},
```

### 🦠 Mini.deps

```lua
local MiniDeps = require("mini.deps");

MiniDeps.add({
    source = "OXY2DEV/helpview.nvim"
});
```

### 🌒 Rocks.nvim

>[!WARNING]
> `luarocks package` may sometimes be a bit behind `main`.

```vim
:Rocks install helpview.nvim
```

### 📥 GitHub release

Tagged releases can be found in the [release page](https://github.com/OXY2DEV/helpview.nvim/releases).

>[!NOTE]
> `Github releases` may sometimes be slightly behind `main`.

### 🚨 Development version

You can use the [dev](https://github.com/OXY2DEV/helpview.nvim/tree/dev) branch to use test features.

>[!WARNING]
> Development releases can contain *breaking changes* and **experimental changes**.
> Use at your own risk!

```lua
return {
    "OXY2DEV/helpview.nvim",
    branch = "dev",
    lazy = false
};
```

## 🧭 Configuration

Check the [wiki](https://github.com/OXY2DEV/helpview.nvim/wiki) for the entire configuration table. A simplified version is given below.

```lua
--- Configuration for `helpview.nvim`.
---@class helpview.config
---
--- Preview options.
---@field preview? helpview.preview
---
--- Configuration options for vimdoc.
---@field vimdoc? helpview.vimdoc
---
--- Custom highlight groups.
---@field highlight_groups? table[]
---
--- Custom renderers
---@field renderers? { [string]: function }
{
	renderers = {},

	preview = {
		enable = true,
		enable_hybrid_mode = true,

		modes = { "n", "c", "no" },
		hybrid_modes = {},
		linewise_hybrid_mode = false,

		filetypes = { "help" },
		ignore_previews = {},
		ignore_buftypes = {},
		condition = nil,

		max_buf_lines = 500,
		draw_range = { 2 * vim.o.lines, 2 * vim.o.lines },
		edit_range = { 0, 0 },

		debounce = 150,
		callbacks = {},

		icon_provider = "internal",

		splitview_winopts = { split = "right" },
		preview_winopts = { width = math.floor(80) }
	},

    vimdoc = {
        arguments = {},
        code_blocks = {},
        headings = {},
        highlight_groups = {},
        horizontal_rules = {},
        inline_codes = {},
        keycodes = {},
        modelines = {},
        notes = {},
        optionlinks = {},
        tags = {},
        taglinks = {},
        urls = {}
    }
}
```

## 🎇 Commands

This plugin follows the *sub-commands* approach for creating commands. There is only a single `:Helpview` command.

It comes with the following sub-commands,

>[!NOTE]
> When no sub-command name is provided(or an invalid sub-command is used) `:Helpview` will run `:Helpview Toggle`.


| Sub-command  | Arguments           | Description                              |
|--------------|---------------------|------------------------------------------|
| `Start`      | none                | Allows attaching to new buffers.         |
| `Stop`       | none                | Prevents attaching to new buffers.       |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `attach`     | **buffer**, integer | Attaches to **buffer**.                  |
| `detach`     | **buffer**, integer | Detaches from **buffer**.                |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `Enable`     | none                | Enables preview *globally*.              |
| `Disable`    | none                | Disables preview *globally*.             |
| `Toggle`     | none                | Toggles preview *globally*.              |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `enable`     | **buffer**, integer | Enables preview for **buffer**.          |
| `disable`    | **buffer**, integer | Disables preview for **buffer**.         |
| `toggle`     | **buffer**, integer | Toggles preview for **buffer**.          |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `splitOpen`  | **buffer**, integer | Opens *splitview* for **buffer**.        |
| `splitClose` | none                | Closes any open *splitview*.             |
| `splitToggle`| none                | Toggles *splitview*.                     |
| `splitRedraw`| none                | Updates *splitview* contents.            |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `Render`     | none                | Updates preview of all *active* buffers. |
| `Clear`      | none                | Clears preview of all **active** buffer. |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `render`     | **buffer**, integer | Renders preview for **buffer**.          |
| `clear`      | **buffer**, integer | Clears preview for **buffer**.           |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `toggleAll`  | none                | **Deprecated** version of `Toggle`.      |
| `enableAll`  | none                | **Deprecated** version of `Enable`.      |
| `disableAll` | none                | **Deprecated** version of `Disable`.     |
| ———————————— | ——————————————————— | ———————————————————————————————————————— |
| `traceExport`| none                | Exports trace logs to `trace.txt`.       |
| `traceShow`  | none                | Shows trace logs in a window.            |

>[!TIP]
> **buffer** defaults to the current buffer. So, you can run commands on the current buffer without providing the buffer.
> ```vim
> :Helpview toggle "Toggles preview of the current buffer.
> ```

## 🎨 Highlight groups

`helpview.nvim` creates a number of *primary highlight groups* that are used by most of the decorations.

>[!IMPORTANT]
> These groups are all **generated** during runtime and as such their colors may look different.

If you want to create your own *dynamic* highlight groups or modify existing ones, see the [custom highlight groups](placeholder) section.


| Highlight group      | Generated from                           | Default                     |
|----------------------|------------------------------------------|-----------------------------|
| HelpviewPalette0     | Normal(bg) + Comment(fg)                 | fg: `#9399b2` bg: `#35374a` |
| HelpviewPalette0Fg   | Comment(fg)                              | fg: `#9399b2`               |
| HelpviewPalette0Bg   | Normal(bg) + Comment(fg)                 | bg: `#35374a`               |
| HelpviewPalette0Sign | Normal(bg) + Comment(fg), LineNr(bg)     | fg: `#9399b2`               |
| ———————————————————— | ———————————————————————————————————————— | ——————————————————————————— |
| HelpviewPalette1     | Normal(bg) + markdownH1(fg)              | fg: `#f38ba8` bg: `#4d3649` |
| HelpviewPalette1Fg   | markdownH1(fg)                           | fg: `#f38ba8`               |
| HelpviewPalette1Bg   | Normal(bg) + markdownH1(fg)              | bg: `#4d3649`               |
| HelpviewPalette1Sign | Normal(bg) + markdownH1(fg), LineNr(bg)  | fg: `#f38ba8`               |
| ———————————————————— | ———————————————————————————————————————— | ——————————————————————————— |
| HelpviewPalette2     | Normal(bg) + markdownH2(fg)              | fg: `#f9b387` bg: `#4d3d43` |
| HelpviewPalette2Fg   | markdownH2(fg)                           | fg: `#f9b387`               |
| HelpviewPalette2Bg   | Normal(bg) + markdownH2(fg)              | bg: `#4d3d43`               |
| HelpviewPalette2Sign | Normal(bg) + markdownH2(fg), LineNr(bg)  | fg: `#f9b387`               |
| ———————————————————— | ———————————————————————————————————————— | ——————————————————————————— |
| HelpviewPalette3     | Normal(bg) + markdownH3(fg)              | fg: `#f9e2af` bg: `#4c474b` |
| HelpviewPalette3Fg   | markdownH3(fg)                           | fg: `#f9e2af`               |
| HelpviewPalette3Bg   | Normal(bg) + markdownH3(fg)              | bg: `#4c474b`               |
| HelpviewPalette3Sign | Normal(bg) + markdownH3(fg), LineNr(bg)  | fg: `#f9e2af`               |
| ———————————————————— | ———————————————————————————————————————— | ——————————————————————————— |
| HelpviewPalette4     | Normal(bg) + markdownH4(fg)              | fg: `#a6e3a1` bg: `#3c4948` |
| HelpviewPalette4Fg   | markdownH4(fg)                           | fg: `#a6e3a1`               |
| HelpviewPalette4Bg   | Normal(bg) + markdownH4(fg)              | bg: `#3c4948`               |
| HelpviewPalette4Sign | Normal(bg) + markdownH4(fg), LineNr(bg)  | fg: `#a6e3a1`               |
| ———————————————————— | ———————————————————————————————————————— | ——————————————————————————— |
| HelpviewPalette5     | Normal(bg) + markdownH5(fg)              | fg: `#74c7ec` bg: `#314358` |
| HelpviewPalette5Fg   | markdownH5(fg)                           | fg: `#74c7ec`               |
| HelpviewPalette5Bg   | Normal(bg) + markdownH5(fg)              | bg: `#314358`               |
| HelpviewPalette5Sign | Normal(bg) + markdownH5(fg), LineNr(bg)  | fg: `#74c7ec`               |
| ———————————————————— | ———————————————————————————————————————— | ——————————————————————————— |
| HelpviewPalette6     | Normal(bg) + markdownH6(fg)              | fg: `#b4befe` bg: `#3c405b` |
| HelpviewPalette6Fg   | markdownH6(fg)                           | fg: `#b4befe`               |
| HelpviewPalette6Bg   | Normal(bg) + markdownH6(fg)              | bg: `#3c405b`               |
| HelpviewPalette6Sign | Normal(bg) + markdownH6(fg), LineNr(bg)  | fg: `#b4befe`               |
| ———————————————————— | ———————————————————————————————————————— | ——————————————————————————— |
| HelpviewPalette7     | Normal(bg) + @conditional(fg)            | fg: `#cba6f7` bg: `#403b5a` |
| HelpviewPalette7Fg   | @conditional(fg)                         | fg: `#cba6f7`               |
| HelpviewPalette7Bg   | Normal(bg) + @conditional(fg)            | bg: `#403b5a`               |
| HelpviewPalette7Sign | Normal(bg) + @conditional(fg), LineNr(bg)| fg: `#cba6f7`               |


> The source highlight group's values are turned into `Lab` color-space and then mixed to reduce unwanted results.

These groups are then used as links by other groups responsible for various preview elements,

>[!NOTE]
> These groups exist for the sake of *backwards compatibility* and *ease of use*.
>
> You will see something like `fg: Normal`, it means the *fg* of Normal was used as the *fg* of that group.


| Highlight group           | value                                    |
|---------------------------|------------------------------------------|
| HelpviewCode              | bg\*: `normal` ± 5%(L)                   |
| HelpviewCodeInfo          | bg\*: `normal` ± 5%(L), fg: `comment`    |
| HelpviewCodeFg            | fg\*: `normal` ± 5%(L)                   |
| HelpviewInlineCode        | fg\*: `normal` ± 10%(L)                  |
| ————————————————————————— | ———————————————————————————————————————— |
| HelpviewIcon0             | link\*\*: `HelpviewPalette0Fg`           |
| HelpviewIcon1             | link\*\*: `HelpviewPalette1Fg`           |
| HelpviewIcon2             | link\*\*: `HelpviewPalette5Fg`           |
| HelpviewIcon3             | link\*\*: `HelpviewPalette4Fg`           |
| HelpviewIcon4             | link\*\*: `HelpviewPalette3Fg`           |
| HelpviewIcon5             | link\*\*: `HelpviewPalette2Fg`           |
| ————————————————————————— | ———————————————————————————————————————— |
| HelpviewGradient0         | fg: `Normal`                             |
| HelpviewGradient1         | fg\*\*\*: `lerp(Normal, Title, 1/9)`     |
| HelpviewGradient2         | fg\*\*\*: `lerp(Normal, Title, 2/9)`     |
| HelpviewGradient3         | fg\*\*\*: `lerp(Normal, Title, 3/9)`     |
| HelpviewGradient4         | fg\*\*\*: `lerp(Normal, Title, 4/9)`     |
| HelpviewGradient5         | fg\*\*\*: `lerp(Normal, Title, 5/9)`     |
| HelpviewGradient6         | fg\*\*\*: `lerp(Normal, Title, 6/9)`     |
| HelpviewGradient7         | fg\*\*\*: `lerp(Normal, Title, 7/9)`     |
| HelpviewGradient8         | fg\*\*\*: `lerp(Normal, Title, 8/9)`     |
| HelpviewGradient9         | fg: `Title`                              |


> \* = The color is converted to HSL and it's luminosity(L) is increased/decreased by the specified amount.
> 
> \*\* = The background color of `HelpviewCode` is added to the groups.
> 
> \*\*\* = Linearly interpolated value between 2 highlight groups `fg`.

There are also highlight groups that are made using the default highlight groups


| Highlight group           | Inherited from                           |
|---------------------------|------------------------------------------|
| HelpviewTaglink           | @markup.link.vimdoc                      |
| HelpviewTag               | @label.vimdoc                            |
| HelpviewTag               | @label.vimdoc                            |
| HelpviewOptionlink        | @markup.link.vimdoc                      |
| HelpviewKeycode           | @string.special.vimdoc                   |
| HelpviewArgument          | @variable.parameter.vimdoc               |


