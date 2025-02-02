---@meta

local M = {};

---@class helpview.vimdoc
---
---@field arguments? vimdoc.arguments


---@class vimdoc.generic
---
---@field corner_left? string
---@field padding_left? string
---
---@field icon? string
---
---@field padding_right? string
---@field corner_right? string
---
---@field hl? string
---
---@field corner_left_hl? string
---@field padding_left_hl? string
---
---@field icon_hl? string
---
---@field padding_right_hl? string
---@field corner_right_hl? string


---@class vimdoc.arguments
---
---@field enable? boolean
---
---@field default vimdoc.generic
---@field [string] vimdoc.generic


---@class vimdoc.code_blocks

return M;
