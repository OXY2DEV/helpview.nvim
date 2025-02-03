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
---
---@field enable? boolean
---
---@field border_hl? string
---@field label_hl? string
---
---@field default { block_hl: string }
---@field [string] { block_hl: string }


---@class vimdoc.headings
---
---@field enable? boolean
---
---@field heading_1 headings.opts
---@field heading_2 headings.opts
---@field heading_3 headings.opts
---@field heading_4 headings.opts


---@class headings.opts
---
---@field hl? string
---
---@field marker? string
---@field marker_hl? string
---
---@field sign? string
---@field sign_hl? string
---
---@field label? [ string, string ]
---@field label_hl? [ string, string ]


---@class vimdoc.highlights
---
---@field enable? boolean
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


---@class vimdoc.hr
---
---@field enable? boolean
---@field parts (hr.text | hr.repeating)[]


---@class hr.text
---
---@field type "text"
---
---@field text string
---@field hl? string


---@class hr.repeating
---
---@field type "repeating"
---@field direction "left" | "right"
---@field repeat_amount integer
---
---@field repeat_hl? string
---@field repeat_text? string
---
---@field text string | string[]
---@field hl? string | string[]


---@class vimdoc.inlinw_codes
---
---@field enable? boolean
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


---@class vimdoc.keycodes
---
---@field enable? boolean
---
---@field default vimdoc.generic
---@field [string] vimdoc.generic


---@class vimdoc.modeline
---
---@field enable? boolean
---
---@field border string
---@field border_hl? string
---
---@field data_types { [string]: { option_hl: string?, value_hl: string? } }
---@field [string] { option_hl: string?, value_hl: string? }


---@class vimdoc.notes
---
---@field enable? boolean
---
---@field default vimdoc.generic
---@field [string] vimdoc.generic


---@class vimdoc.optionlinks
---
---@field enable? boolean
---
---@field default vimdoc.generic
---@field [string] vimdoc.generic


---@class vimdoc.tags
---
---@field enable? boolean
---
---@field default vimdoc.generic
---@field [string] vimdoc.generic


---@class vimdoc.taglinks
---
---@field enable? boolean
---
---@field default vimdoc.generic
---@field [string] vimdoc.generic


return M;
