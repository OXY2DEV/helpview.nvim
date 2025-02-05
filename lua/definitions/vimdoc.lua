---@meta

local M = {};

--- Configuration for vimdoc files.
---@class helpview.vimdoc
---
--- When `false`, doesn't render vimdoc.
---@field enable? boolean
---
--- Configuration for {arguments}.
---@field arguments? vimdoc.arguments
---
--- Configuration for code blocks.
---@field code_blocks? vimdoc.code_blocks
---
--- Configuration for headings.
---@field headings? vimdoc.headings
---
--- Configuration for highlight group names.
---@field highlight_groups? vimdoc.highlights
---
--- Configuration for horizontal rules.
---@field horizontal_rules? vimdoc.hr
---
--- Configuration for 
---@field inline_codes? vimdoc.inline_codes
---
--- Configuration for <Keycodes>.
---@field keycodes? vimdoc.keycodes
---
--- Configuration for vim:modeline:.
---@field modelines? vimdoc.modelines
---
--- Configuration for Note.
---@field notes? vimdoc.notes
---
--- Configuration for 'optionlink'.
---@field optionlinks? vimdoc.optionlinks
---
--- Configuration for *tag*.
---@field tag? vimdoc.tags
---
--- Configuration for |taglink|.
---@field taglinks? vimdoc.taglinks
---
--- Configuration for URLs.
---@field urls? vimdoc.urls


--- Configuration for a generic inline
--- element.
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
--- Primary highlight group.
--- Used by other `*_hl` option(s) when
--- a value isn't given.
---@field hl? string
---
---@field corner_left_hl? string
---@field padding_left_hl? string
---
---@field icon_hl? string
---
---@field padding_right_hl? string
---@field corner_right_hl? string


--- Configuration for `{arguments}`.
---@class vimdoc.arguments
---
--- When `false`, arguments don't get rendered.
---@field enable? boolean
---
--- Default configuration for arguments.
---@field default vimdoc.generic
--- Configuration for `{string}`.
---@field [string] vimdoc.generic


--- Configuration for code blocks.
---@class vimdoc.code_blocks
---
--- When `false`, code blocks don't get rendered.
---@field enable? boolean
---
--- Highlight group for the top & bottom borders.
---@field border_hl? string
--- Highlight group for the language label.
---@field label_hl? string
---
--- Default line configuration(used for stuff like `diff`).
---@field default { block_hl: string }
--- Line configuration when the language is `string`.
---@field [string] { block_hl: string }


--- Configuration for headings.
---@class vimdoc.headings
---
--- When `false`, headings don't get rendered.
---@field enable? boolean
---
--- Configuration for === headings.
---@field heading_1 headings.opts
--- Configuration for --- headings.
---@field heading_2 headings.opts
--- Configuration for ABC headings.
---@field heading_3 headings.opts
--- Configuration for A ~ headings.
---@field heading_4 headings.opts


--- Configuration options for each heading
--- level.
---@class headings.opts
---
--- Primary highlight group.
--- Used by other `*_hl` option(s) when
--- a value isn't given.
---@field hl? string
---
--- Text used to replace `=`/`-` parts.
--- On level 3 & 4 headings it covers the
--- whitespace instead.
---@field marker? string
--- Highlight group for `marker`.
---@field marker_hl? string
---
--- Text to show in the **right** side of
--- the heading.
---@field sign? string
--- Highlight group for `sign`.
---@field sign_hl? string
---
--- Text to add before & after the `sign`.
---@field label? [ string, string ]
--- Highlight group for the parts of the
--- label.
---@field label_hl? [ string, string ]


--- Configuration for highlight group name.
---@see vimdoc.generic
---
---@class vimdoc.highlights
---
--- When `false`, highlight group names aren't rendered.
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


--- Configuration for horizontal rules.
---@class vimdoc.hr
---
--- When `false`, horizontal rules aren't rendered.
---@field enable? boolean
---
--- Parts for the shown highlight group
---@field parts (hr.text | hr.repeating)[]


--- Shows some text.
---@class hr.text
---
--- Part type.
---@field type "text"
---
--- Text to show.
---@field text string
---
--- Highlight group for `text`.
---@field hl? string


--- Repeats the given character(s)/highlight group(s).
---@class hr.repeating
---
--- Part type.
---@field type "repeating"
---
--- Direction to repeat from.
---@field direction "left" | "right"
--- Number of times to repeat.
---@field repeat_amount integer | fun(buffer: integer, item: vimdoc.__hr): integer
---
--- Should the highlight group be repeated?
--- [ Only works when `hl` is a list ]
---@field repeat_hl? boolean
--- Should the text be repeated?
--- [ Only works when `text` is a list ]
---@field repeat_text? boolean
---
---@field text string | string[]
---@field hl? string | string[]


--- Configuration for inline codes.
---@see vimdoc.generic
---
---@class vimdoc.inline_codes
---
--- When `false`, inline codes aren't rendered.
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


--- Configuration for `<keycodes>`
---@class vimdoc.keycodes
---
--- When `false`, keycodes aren't rendered.
---@field enable? boolean
---
--- Default configuration for keycodes.
---@field default vimdoc.generic
---
--- Configuration for `<string>`.
---@field [string] vimdoc.generic


--- Configuration for Vim modeline.
---@class vimdoc.modelines
---
--- When `false`, modeline won't be rendered.
---@field enable? boolean
---
--- Character to use as the borders.
---@field border string
--- Highlight group for the `border`.
---@field border_hl? string
---
--- Configuration for various **data-types**.
---@field data_types { [string]: { option_hl: string?, value_hl: string? } }
--- Configuration for various options.
---@field [string] { option_hl: string?, value_hl: string? }


--- Configuration for notes.
---@class vimdoc.notes
---
--- When `false`, notes won't be rendered.
---@field enable? boolean
---
--- Default configuration for notes.
---@field default vimdoc.generic
--- Configuration for `string` note.
---@field [string] vimdoc.generic


--- Configuration for optionlinks.
---@class vimdoc.optionlinks
---
--- When `false`, optionlinks won't be rendered.
---@field enable? boolean
---
--- Default configuration for optionlinks.
---@field default vimdoc.generic
--- Configuration for `'string'` optionlink.
---@field [string] vimdoc.generic


--- Configuration for tags.
---@class vimdoc.tags
---
--- When `false`, tags won't be rendered.
---@field enable? boolean
---
--- Default configuration for tags.
---@field default vimdoc.generic
--- Configuration for `*string*` tag.
---@field [string] vimdoc.generic


--- Configuration for taglinks.
---@class vimdoc.taglinks
---
--- When `false`, taglinks won't be rendered.
---@field enable? boolean
---
--- Default configuration for taglinks.
---@field default vimdoc.generic
--- Configuration for `|string|` taglink.
---@field [string] vimdoc.generic


--- Configuration for URLs.
---@class vimdoc.urls
---
---@field enable? boolean
---
---@field default url.opts
---@field [string] url.opts

---@class url.opts
---
--- Priority of a pattern.
---@field priority? integer
---
--- Text that will replace the link.
---@field text? fun(buffer: integer, item: vimdoc.__url): string
---
---@field corner_left? string
---@field padding_left? string
---
---@field icon? string
---
---@field padding_right? string
---@field corner_right? string
---
--- Primary highlight group.
--- Used by other `*_hl` option(s) when
--- a value isn't given.
---@field hl? string
---
---@field corner_left_hl? string
---@field padding_left_hl? string
---
---@field icon_hl? string
---
---@field padding_right_hl? string
---@field corner_right_hl? string

return M;
