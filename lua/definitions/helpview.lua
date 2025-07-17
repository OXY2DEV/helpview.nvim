---@meta

---@class helpview.state Collection of internal state values.
---
---@field enable boolean Is `helpview.nvim` enabled?
---@field attached_buffers integer[] List of buffers the plugin is attached to.
---
---@field buffer_states table<integer, helpview.state.buffer> Mapping between a buffer number & it's state.
---
---@field splitview_source? integer Buffer whose preview is being shown in splitview window.
---@field splitview_buffer? integer Buffer used to for the preview.
---@field splitview_window? integer Window where splitview is being show.


---@class helpview.state.buffer Buffer states.
---
---@field enable boolean Is `helpview.nvim` enabled on this buffer?
---@field hybrid_mode boolean Is hybrid mode enabled for this buffer?


---@class helpview.config Configuration for `helpview.nvim`
---
---@field preview helpview.config.preview Options for changing when preview is shown.
---@field vimdoc helpview.config.vimdoc Options for changing how vimdoc looks.


---@class helpview.parsed.range Parsed TSNode range.
---
---@field row_start integer
---@field row_end integer
---
---@field col_start integer
---@field col_end integer


--- A parsed item.
---@alias helpview.parsed.item
---| helpview.parsed.vimdoc.argument
---| helpview.parsed.vimdoc.code_block
---| helpview.parsed.vimdoc.heading
---| helpview.parsed.vimdoc.hr
---| helpview.parsed.vimdoc.keycode
---| helpview.parsed.vimdoc.modeline
---| helpview.parsed.vimdoc.note
---| helpview.parsed.vimdoc.optionlink
---| helpview.parsed.vimdoc.tag
---| helpview.parsed.vimdoc.taglink
---| helpview.parsed.vimdoc.url


---@class helpview.parsed.sorted Sorted parsed item for each language.
---
---@field vimdoc? helpview.parsed.sorted.vimdoc


---@class helpview.parsed.sorted.vimdoc Sorted vimdoc items by class name.
---
---@field argument? helpview.parsed.vimdoc.argument
---@field code_block? helpview.parsed.vimdoc.code_block
---@field heading? helpview.parsed.vimdoc.heading
---@field hr? helpview.parsed.vimdoc.hr
---@field keycode? helpview.parsed.vimdoc.keycode
---@field modeline? helpview.parsed.vimdoc.modeline
---@field note? helpview.parsed.vimdoc.note
---@field optionlink? helpview.parsed.vimdoc.optionlink
---@field tag? helpview.parsed.vimdoc.tag
---@field taglink? helpview.parsed.vimdoc.taglink
---@field url? helpview.parsed.vimdoc.url

