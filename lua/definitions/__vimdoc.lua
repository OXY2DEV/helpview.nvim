---@meta

---@class vimdoc.__argument
---
---@field class "vimdoc_argument",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range
M.arg = {
	class = "vimdoc_argument",
	label = "argument",
	range = {
		col_end = 10,
		col_start = 0,
		row_end = 7,
		row_start = 7
	},
	text = { "{argument}" }
};

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
M.code_block = {
	bottom_border = { false, false },
	class = "vimdoc_code_block",
	language = "diff",
	range = {
		col_end = 0,
		col_start = 0,
		row_end = 5,
		row_start = 3
	},
	text = { ">diff", "    + h" },
	top_border = { false, false }
};

---@class vimdoc.__heading
---
---@field class "vimdoc_heading"
---@field level 
---| 1 Headings using === delimiters.
---| 2 Headings using --- delimiters.
---| 3 Headings using CAP-italized text.
---| 4 Headings using A ~.
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
M.heading = {
	class = "vimdoc_heading",
	delimiter = "------------------------------------------------------------------------------",
	description = "Hello Neovim!",
	level = 2,
	range = {
		col_end = 0,
		col_start = 0,
		desc_end = 13,
		desc_start = 0,
		row_end = 9,
		row_start = 7
	},
	tags = {
		{
			col_start = 70,
			tag = "*tag-1*"
		}, {
			col_start = 78,
			tag = "*tag-2*"
		}
	},
	text = { "------------------------------------------------------------------------------", "Hello Neovim!                                                  *tag-1* *tag-2*" }
};

---@class vimdoc.__hl
---
---@field class "vimdoc_hl",
---@field group_name string
---
---@field text string[],
---@field range node.range
M.hl = {
	class = "vimdoc_hl",
	group_name = "Special",
	range = {
		col_end = 7,
		col_start = 0,
		row_end = 9,
		row_start = 9
	},
	text = { "Special" }
};

---@class vimdoc.__hr
---
---@field class "vimdoc_hr"
---
---@field text string[]
---@field range node.range
M.hr = {
	class = "vimdoc_hr",
	range = {
		col_end = 78,
		col_start = 0,
		row_end = 8,
		row_start = 7
	},
	text = { "------------------------------------------------------------------------------" }
};

---@class vimdoc.__inline_code
---
---@field class "vimdoc_inline_code",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range
M.inline_code = {
	class = "vimdoc_inline_code",
	range = {
		col_end = 4,
		col_start = 0,
		row_end = 9,
		row_start = 9
	},
	text = { "`hi`" }
};

---@class vimdoc.__keycode
---
---@field class "vimdoc_keycode",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range
M.keycode = {
	class = "vimdoc_keycode",
	label = "C-S",
	range = {
		col_end = 5,
		col_start = 0,
		row_end = 9,
		row_start = 9
	},
	text = { "<C-S>" }
};

---@class vimdoc.__modeline
---
---@field class "vimdoc_modeline"
---@field options { option: string, value: any }[]
---
---@field text string[],
---@field range node.range
M.modeline = {
	class = "vimdoc_modeline",
	options = {
		{
			option = "textwidth",
			value = 78
		}, {
			option = "iskeyword",
			value = '!-~,^*,^\\|,^\\"'
		}, {
			option = "tabstop",
			value = 8
		}, {
			option = "expandtab",
			value = false
		}, {
			option = "filetype",
			value = "help"
		}, {
			option = "rightleft",
			value = false
		}
	},
	range = {
		col_end = 0,
		col_start = 1,
		row_end = 11,
		row_start = 10
	},
	text = { 'vim:tw=78:isk=!-~,^*,^\\|,^\\":ts=8:noet:ft=help:norl:' }
};

---@class vimdoc.__note
---
---@field class "vimdoc_note",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range
M.note = {
	class = "vimdoc_note",
	label = "Note",
	range = {
		col_end = 5,
		col_start = 0,
		row_end = 9,
		row_start = 9
	},
	text = { "Note:" }
};

---@class vimdoc.__optionlink
---
---@field class "vimdoc_optionlink",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range
M.optionlink = {
	class = "vimdoc_optionlink",
	label = "expandtab",
	range = {
		col_end = 11,
		col_start = 0,
		row_end = 9,
		row_start = 9
	},
	text = { "'expandtab'" }
};

---@class vimdoc.__tag
---
---@field class "vimdoc_tag",
---@field tag string
---@field after? string,
---
---@field text string[],
---@field range node.range
M.tag = {
	class = "vimdoc_tag",
	range = {
		col_end = 5,
		col_start = 0,
		row_end = 9,
		row_start = 9
	},
	tag = "tag",
	text = { "*tag*" }
};

---@class vimdoc.__taglink
---
---@field class "vimdoc_taglink",
---@field label string
---@field after? string,
---
---@field text string[],
---@field range node.range
M.taglink = {
	class = "vimdoc_taglink",
	label = "taglink",
	range = {
		col_end = 9,
		col_start = 0,
		row_end = 9,
		row_start = 9
	},
	text = { "|taglink|" }
};

---@class vimdoc.__url
---
---@field class "vimdoc_url",
---@field label string
---
---@field text string[],
---@field range node.range
M.url = {
	class = "vimdoc_url",
	label = "https://neovim.io/doc/user/api.html#api-definitions",
	range = {
		col_end = 51,
		col_start = 0,
		row_end = 1,
		row_start = 1
	},
	text = { "https://neovim.io/doc/user/api.html#api-definitions" }
};

