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


---@class helpview.config
---
---@field preview? helpview.preview
---@field highlight_groups? table[]
---@field renderers? { [string]: function }
---
---@field vimdoc? table


return M;
