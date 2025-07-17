---@meta

---@class helpview.parsed.vimdoc.argument
---
---@field class "vimdoc_argument"
---
---@field label string Text inside `{}`.
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.code_block
---
---@field class "vimdoc_code_block"
---
---@field language? string Code block language.
---
---@field top_border [ boolean, boolean ]
---@field bottom_border [ boolean, boolean ]
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.heading
---
---@field class "vimdoc_heading"
---@field level helpview.parsed.vimdoc.heading.level
---
---@field description? string
---@field tags? helpview.parsed.vimdoc.heading.tag[]
---@field delimiter? string
---
---@field text string
---@field range helpview.parsed.vimdoc.heading.range


---@alias helpview.parsed.vimdoc.heading.level
---| 1
---| 2
---| 3
---| 4


---@class helpview.parsed.vimdoc.heading.tag
---
---@field tag string The tag text.
---
---@field col_start integer
---@field col_end integer


---@class helpview.parsed.vimdoc.heading.range
---
---@field row_start integer
---@field row_end integer
---
---@field col_start integer
---@field col_end integer
---
---@field desc_start integer Column where the heading text start.
---@field desc_end integer Column where the heading text end.


---@class helpview.parsed.vimdoc.hr
---
---@field class "vimdoc_hr"
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.inline_code
---
---@field class "vimdoc_inline_code"
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.keycode
---
---@field class "vimdoc_keycode"
---
---@field label string Text inside `<>`.
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.modeline
---
---@field class "vimdoc_modeline"
---@field options helpview.parsed.vimdoc.modeline.option[]
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.modeline.option
---
---@field option string
---@field value string | number | boolean | nil


---@class helpview.parsed.vimdoc.note
---
---@field class "vimdoc_note"
---
---@field label string Text before `:`.
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.optionlink
---
---@field class "vimdoc_optionlink"
---
---@field label string Text inside `''`.
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.tag
---
---@field class "vimdoc_tag"
---
---@field tag string Text inside `**`.
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.taglink
---
---@field class "vimdoc_taglink"
---
---@field label string Text inside `||`.
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.hl
---
---@field class "vimdoc_hl"
---
---@field group_name string
---@field after? string Tabs after this node.
---
---@field text string
---@field range helpview.parsed.range


---@class helpview.parsed.vimdoc.url
---
---@field class "vimdoc_url"
---
---@field label string
---
---@field text string
---@field range helpview.parsed.range

