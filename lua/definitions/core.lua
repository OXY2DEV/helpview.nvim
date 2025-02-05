---@meta
local M = {};


--- State variables for `helpview.nvim`.
---@class helpview.state
---
---@field enable boolean
---@field attached_buffers integer[]
---
---@field buffer_states helpview.buf_state[]
---
---@field splitview_source? integer
---@field splitview_buffer? integer
---@field splitview_window? integer


---@class helpview.buf_state
---
---@field enable boolean
---@field hybrid_mode boolean
---
---@field y? integer


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


return M;
