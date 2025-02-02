---@meta

local M = {};

---@class helpview.preview
---
--- Enables *preview* when attaching to new buffers.
---@field enable? boolean
--- Enables `hybrid mode` when attaching to new buffers.
---@field enable_hybrid_mode? boolean
---
--- Icon provider.
---@field icon_provider?
---| "internal" Internal icon provider.
---| "devicons" `nvim-web-devicons` as icon provider.
---| "mini" `mini.icons` as icon provider.
---
--- Callback functions.
---@field callbacks? preview.callbacks
--- VIM-modes where `hybrid mode` is enabled.
---@field hybrid_modes? string[]
--- Options that should/shouldn't be previewed in `hybrid_modes`.
---@field ignore_previews? preview.ignore
--- Clear lines around the cursor in `hybrid mode`, instead of nodes?
---@field linewise_hybrid_mode? boolean
--- VIM-modes where previews will be shown.
---@field modes? string[]
---
--- Debounce delay for updating previews.
---@field debounce? integer
--- Buffer filetypes where the plugin should attach.
---@field filetypes? string[]
--- Buftypes that should be ignored(e.g. nofile).
---@field ignore_buftypes? string[]
--- Condition to check if a buffer should be attached or not.
---@field condition? fun(buffer: integer): boolean
--- Maximum number of lines a buffer can have before switching to partial rendering.
---@field max_buf_lines? integer
---
--- Lines before & after the cursor that is considered being edited.
--- Edited content isn't rendered.
---@field edit_range? [ integer, integer ]
--- Lines before & after the cursor that is considered being previewed.
---@field draw_range? [ integer, integer ]
---
--- Window options for the `splitview` window.
--- See `:h nvim.open_win()`.
---@field splitview_winopts? table

return M;
