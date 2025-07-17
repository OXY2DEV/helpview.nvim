---@meta

---@class helpview.config.vimdoc Configuration for vimdoc files.
---
---@field enable? boolean When `false`, doesn't render vimdoc.
---
---@field arguments? helpview.config.vimdoc.arguments Configuration for {arguments}.
---@field code_blocks? helpview.config.vimdoc.code_blocks Configuration for code blocks.
---@field headings? helpview.config.vimdoc.headings Configuration for headings.
---@field highlight_groups? helpview.config.vimdoc.highlights Configuration for highlight group names.
---@field horizontal_rules? helpview.config.vimdoc.hr Configuration for horizontal rules.
---@field inline_codes? helpview.config.vimdoc.inline_codes Configuration for 
---@field keycodes? helpview.config.vimdoc.keycodes Configuration for <Keycodes>.
---@field modelines? helpview.config.vimdoc.modelines Configuration for vim:modeline:.
---@field notes? helpview.config.vimdoc.notes Configuration for Note.
---@field optionlinks? helpview.config.vimdoc.optionlinks Configuration for 'optionlink'.
---@field tag? helpview.config.vimdoc.tags Configuration for *tag*.
---@field taglinks? helpview.config.vimdoc.taglinks Configuration for |taglink|.
---@field urls? helpview.config.vimdoc.urls Configuration for URLs.

---@class helpview.config.vimdoc.inline Common configuration for a inline element.
---
---@field corner_left? string
---@field padding_left? string
---
---@field icon? string
---
---@field padding_right? string
---@field corner_right? string
---
---@field hl? string Primary highlight group. Used by other `*_hl` option(s) when a value isn't given.
---
---@field corner_left_hl? string
---@field padding_left_hl? string
---
---@field icon_hl? string
---
---@field padding_right_hl? string
---@field corner_right_hl? string


---@class helpview.config.vimdoc.arguments Configuration for `{arguments}`.
---
---@field enable? boolean
---
---@field default helpview.config.vimdoc.inline Default configuration for arguments.
---@field [string] helpview.config.vimdoc.inline Configuration for `{string}`.


---@class helpview.config.vimdoc.code_blocks Configuration for code blocks.
---
---@field enable? boolean
---
---@field border_hl? string Highlight group for the top & bottom borders.
---@field label_hl? string Highlight group for the language label.
---
---@field default helpview.config.vimdoc.code_blocks.line_opts Default line configuration(used for stuff like `diff`).
---@field [string] helpview.config.vimdoc.code_blocks.line_opts Line configuration when the language is `string`.


---@class helpview.config.vimdoc.code_blocks.line_opts Line options for code blocks.
---
--- Highlight group for the background of each line.
---@field block_hl
---| string Highlight group name.
---| fun (buffer: integer, line: string): string? Function returning a highlight group name.


---@class helpview.config.vimdoc.headings Configuration for headings.
---
---@field enable? boolean
---
---@field heading_1 helpview.config.vimdoc.headings.opts Configuration for `===` headings.
---@field heading_2 helpview.config.vimdoc.headings.opts Configuration for `---` headings.
---@field heading_3 helpview.config.vimdoc.headings.opts Configuration for `ABC` headings.
---@field heading_4 helpview.config.vimdoc.headings.opts Configuration for `A ~` headings.


---@class helpview.config.vimdoc.headings.opts Configuration options for each heading level.
---
---@field hl? string Primary highlight group. Used by other `*_hl` option(s) when a value isn't given.
---
---@field marker? string Text used to replace `=`/`-` parts. On level 3 & 4 headings it covers the whitespace instead.
---@field marker_hl? string Highlight group for `marker`.
---
---@field sign? string Text to show in the **right** side of the heading.
---@field sign_hl? string Highlight group for `sign`.
---
---@field label? [ string, string ] Text to add before & after the `sign`.
---@field label_hl? [ string, string ] Highlight group for the parts of the label.


---@alias helpview.config.vimdoc.highlights helpview.config.vimdoc.inline Configuration for highlight group names.


---@class helpview.config.vimdoc.hr Configuration for horizontal rules.
---
---@field enable? boolean
---
---@field parts helpview.config.vimdoc.hr.part[] Parts for the shown horizontal rule.


---@alias helpview.config.vimdoc.hr.part
---| helpview.config.vimdoc.hr.text
---| helpview.config.vimdoc.hr.repeating


---@class helpview.config.vimdoc.hr.text Shows some text.
---
---@field type "text" Part type.
---
---@field text string Text to show.
---@field hl? string Highlight group for `text`.


---@class helpview.config.vimdoc.hr.repeating Repeats the given character(s)/highlight group(s).
---
---@field type "repeating" Part type.
---
---@field direction "left" | "right" Direction to repeat from.
---@field repeat_amount
---| integer Number of times to repeat.
---| fun(buffer: integer, item: helpview.parsed.vimdoc.hr): integer
---
---@field repeat_hl? boolean Should the highlight group be repeated[ Only works when `hl` is a list ]?
---@field repeat_text? boolean Should the text be repeated[ Only works when `text` is a list ]?
---
---@field text string | string[]
---@field hl? string | string[]


---@alias helpview.config.vimdoc.inline_codes helpview.config.vimdoc.inline Configuration for highlight group names.


---@class helpview.config.vimdoc.keycodes Configuration for `<keycodes>`
---
---@field enable? boolean
---
---@field default helpview.config.vimdoc.inline Default configuration for keycodes.
---@field [string] helpview.config.vimdoc.inline Configuration for `<string>`.


---@class helpview.config.vimdoc.modelines Configuration for Vim modeline.
---
---@field enable? boolean
---
---@field border string Character to use as the borders.
---@field border_hl? string Highlight group for the `border`.
---
---@field data_types helpview.config.vimdoc.modelines.data_types Configuration for various **data-types**.
---@field default helpview.config.vimdoc.modelines.opts Default configuration options.
---@field [string] helpview.config.vimdoc.modelines.opts Configuration for various options.


---@class helpview.config.vimdoc.modelines.data_types Configuration for various primitive data types.
---
---@field boolean helpview.config.vimdoc.modelines.opts
---@field nil helpview.config.vimdoc.modelines.opts
---@field number helpview.config.vimdoc.modelines.opts
---@field string helpview.config.vimdoc.modelines.opts


---@class helpview.config.vimdoc.modelines.opts
---
---@field option_hl? string Highlight group for the option name.
---@field value_hl? string Highlight group for the option value.


---@class helpview.config.vimdoc.notes Configuration for notes.
---
---@field enable? boolean
---
---@field default helpview.config.vimdoc.inline Default configuration for notes.
---@field [string] helpview.config.vimdoc.inline Configuration for `string` note.


---@class helpview.config.vimdoc.optionlinks Configuration for optionlinks.
---
---@field enable? boolean
---
---@field default helpview.config.vimdoc.inline Default configuration for optionlinks.
---@field [string] helpview.config.vimdoc.inline Configuration for `'string'` optionlink.


---@class helpview.config.vimdoc.tags Configuration for tags.
---
---@field enable? boolean
---
---@field default helpview.config.vimdoc.inline Default configuration for tags.
---@field [string] helpview.config.vimdoc.inline Configuration for `*string*` tag.


---@class helpview.config.vimdoc.taglinks Configuration for taglinks.
---
---@field enable? boolean
---
---@field default helpview.config.vimdoc.inline Default configuration for taglinks.
---@field [string] helpview.config.vimdoc.inline Configuration for `|string|` taglink.


---@class helpview.config.vimdoc.urls Configuration for URLs.
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
---@field text? fun(buffer: integer, item: helpview.parsed.vimdoc.url): string
---
---@field corner_left? string
---@field padding_left? string
---
---@field icon? string
---
---@field padding_right? string
---@field corner_right? string
---
--- Primary highlight group. Used by other `*_hl` option(s) when a value isn't given.
---@field hl? string
---
---@field corner_left_hl? string
---@field padding_left_hl? string
---
---@field icon_hl? string
---
---@field padding_right_hl? string
---@field corner_right_hl? string
