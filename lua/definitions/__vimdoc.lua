---@meta

---@class vimdoc.__argument
---
---@field class "vimdoc_argument",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range


---@class vimdoc.__code_block
---
---@field class "vimdoc_code_block"
---@field language string?
---
---@field top_border [ boolean, boolean ]
---@field bottom_border [ boolean, boolean ]
---
---@field text string[],
---@field range node.range


---@class vimdoc.__heading
---
---@field class "vimdoc_heading"
---@field level 
---| 1 Headings using === delimiters.
---| 2 Headings using --- delimiters.
---| 3 Headings using CAP-italized text.
---| 4 Headings using  ~  .
---
---@field description? string
---@field tags? { tag: string, col_start: integer, col_end: integer }[]
---
---@field delimiter string
---
---@field text string[]
---@field range heading.range

---@class heading.range
---
---@field row_start integer
---@field row_end integer
---
---@field col_start integer
---@field col_end integer
---
---@field desc_start? integer
---@field desc_end? integer


---@class vimdoc.__hr
---
---@field class "vimdoc_hr"
---
---@field text string[]
---@field range node.range


---@class vimdoc.__inline_code
---
---@field class "vimdoc_inline_code",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range


---@class vimdoc.__keycode
---
---@field class "vimdoc_keycode",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range


---@class vimdoc.__modeline
---
---@field class "vimdoc_modeline"
---@field options { option: string, value: any }[]
---
---@field text string[],
---@field range node.range


---@class vimdoc.__note
---
---@field class "vimdoc_note",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range


---@class vimdoc.__optionlink
---
---@field class "vimdoc_optionlink",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range


---@class vimdoc.__tag
---
---@field class "vimdoc_tag",
---@field tag string
---@field after? string,
---
---@field text string[],
---@field range node.range


---@class vimdoc.__taglink
---
---@field class "vimdoc_taglink",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range


---@class vimdoc.__hl
---
---@field class "vimdoc_hl",
---@field group_name string
---
---@field text string[],
---@field range node.range


