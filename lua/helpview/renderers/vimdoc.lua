local vimdoc = {};

local spec = require("helpview.spec");
local filetypes = require("helpview.filetypes");
local utils = require("helpview.utils");

vimdoc.ns = vim.api.nvim_create_namespace("helpview/vimdoc");
vimdoc.lnum_offsets = {};

local function has_decorations(config)
	if (config.corner_left ~= nil and config.corner_left ~= "") then
		return true;
	elseif (config.padding_left ~= nil and config.padding_left ~= "") then
		return true;
	elseif (config.icon ~= nil and config.icon ~= "") then
		return true;
	elseif (config.padding_right ~= nil and config.padding_right ~= "") then
		return true;
	elseif (config.corner_right ~= nil and config.corner_right ~= "") then
		return true;
	else
		return false;
	end
end

vimdoc.__fix_indent = function (buffer, item, offset)
	offset = offset or 0;

	local range = item.range;

	if not item.after then
		return;
	end

	local txt_width = (vimdoc.lnum_offsets[range.row_start] or 0) + vim.fn.strdisplaywidth(item.text[1]);
	local width = (vimdoc.lnum_offsets[range.row_start] or 0) + vim.fn.strdisplaywidth(item.text[1] .. item.after);

	if not vimdoc.lnum_offsets[range.row_start] then
		vimdoc.lnum_offsets[range.row_start] = txt_width + offset;
	else
		vimdoc.lnum_offsets[range.row_start] = vimdoc.lnum_offsets[range.row_start] + txt_width + offset;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_end, {
		undo_restore = false, invalidate = true,

		end_col = range.col_end + #item.after,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ string.rep(" ", width - (txt_width + offset)) }
		}
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.argument
vimdoc.argument = function (buffer, item)
	---@type helpview.config.vimdoc.arguments?
	local main_config = spec.get({ "vimdoc", "arguments" });

	if not main_config then
		return;
	end

	---@type helpview.config.vimdoc.inline?
	local config = utils.match(main_config, item.label, {
		ignore_keys = { "enable", "default" }
	});
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	if string.match(item.text[1], "?$") then
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end - 2, {
			undo_restore = false, invalidate = true,

			end_col = range.col_end - 1,
			conceal = "",
		});

		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
			},

			hl_mode = "combine"
		});
	else
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end - 1, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
			},

			hl_mode = "combine"
		});
	end

	---@type string Added virtual text.
	local ext = table.concat({
		config.padding_left or "",
		config.corner_left or "",
		config.icon or "",

		config.padding_right or "",
		config.corner_right or ""
	});

	if has_decorations(config) then
		vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext) - 2);
	end

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.code_block
vimdoc.code_block = function (buffer, item)
	---@type helpview.config.vimdoc.code_blocks
	local config = spec.get({ "vimdoc", "code_blocks" });
	local range = item.range;

	if not config then
		return;
	end

	--- Returns the configuration for
	--- a line.
	---@param line string
	---@return { block_hl: string }
	local function get_line_config (line)
		---@type { block_hl: string }
		local line_config;

		if not item.language then
			line_config = config.default;
		else
			line_config = utils.match(config, item.language, {
				def_fallback = {
					block_hl = config.border_hl
				},
				fallback = {
					block_hl = config.border_hl
				}
			});
		end

		if type(line_config) == "function" then
			line_config = line_config(buffer, line);
		end

		return utils.tostatic(line_config, { args = { buffer, line } });
	end

	local decorations = filetypes.get(item.language);
	local label = { string.format(" %s%s ", decorations.icon, decorations.name), utils.set_hl(config.label_hl or decorations.icon_hl) };

	local function show_tooltip ()
		if vim.fn.has("nvim-0.11.0") == 0 then
			-- Only do this on nightly versions
			return false;
		else
			local ft = vim.filetype.match({
				filename = string.format("example.%s", item.language)
			});

			return vim.list_contains({ "vim", "lua" }, ft);
		end
	end

	if item.top_border[1] == true then
		--- Virtual line
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1 + #(item.language or ""),
			conceal = "",

			virt_lines = item.top_border[2] == true and {
				{
					{ "" }
				},
				{
					label,
					show_tooltip() == true and { "• Run with 󰌏 g==", "HelpviewCodeInfo" } or { "" },
					{ string.rep(" ", vim.o.columns), utils.set_hl(config.border_hl) }
				},
			} or {
				{
					label,
					show_tooltip() == true and { "• Run with 󰌏 g==", "HelpviewCodeInfo" } or { "" },
					{ string.rep(" ", vim.o.columns), utils.set_hl(config.border_hl) }
				}
			}
		});
	else
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1 + #(item.language or ""),
			conceal = "",

			virt_lines_above = true,
			virt_lines = item.top_border[2] == true and {
				{
					{ "" }
				}
			} or nil,

			virt_text_pos = "overlay",
			virt_text = {
				label,
				show_tooltip() == true and { "• Run with 󰌏 g==", "HelpviewCodeInfo" } or { "" },
			},
			line_hl_group = utils.set_hl(config.border_hl)
		});
	end

	for l = range.row_start + 1, range.row_end - 1 do
		local _l = (l - range.row_start) + 1;
		local l_conf = get_line_config(item.text[_l]);

		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, l, 0, {
			undo_restore = false, invalidate = true,
			line_hl_group = utils.set_hl(l_conf.block_hl)
		});
	end

	if item.bottom_border[1] == true then
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
			undo_restore = false, invalidate = true,

			virt_lines_above = true,
			virt_lines = item.bottom_border[2] == true and {
				{
					{ string.rep(" ", vim.o.columns), utils.set_hl(config.border_hl) },
				},
				{
					{ "" }
				},
			} or {
				{
					{ string.rep(" ", vim.o.columns), utils.set_hl(config.border_hl) },
				},
			}
		});
	else
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
			undo_restore = false, invalidate = true,

			virt_lines = item.top_border[2] == true and {
				{
					{ "" }
				}
			} or nil,

			line_hl_group = utils.set_hl(config.border_hl)
		});
	end

	-- if item.padding_bottom == true then
	-- else
	-- end
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.heading
vimdoc.heading = function (buffer, item)
	---@type helpview.config.vimdoc.headings?
	local main_config = spec.get({ "vimdoc", "headings" });

	if not main_config then
		return;
	elseif not main_config["heading_" .. item.level] then
		return;
	end

	---@type helpview.config.vimdoc.headings.opts
	local config = main_config["heading_" .. item.level];
	local range = item.range;

	local sign = config.sign or "";
	local label = config.label or { "", "" };
	local label_hl = config.label_hl or {};

	--- Top border.
	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "overlay",
		virt_text = {
			{ string.rep(config.marker or " ", vim.bo[buffer].tw - vim.fn.strdisplaywidth(label[1] .. sign .. label[2])), utils.set_hl(config.marker_hl or config.hl) },
			{ label[1], utils.set_hl(label_hl[1]) },
			{ sign, utils.set_hl(config.sign_hl or config.hl) },
			{ label[2], utils.set_hl(label_hl[2]) },
		},

		--- Bug, Causes highlight groups to
		--- bleed out in certain cases.
		-- hl_mode = "combine"
	});

	if not item.description or not config.hl then
		return;
	end

	--- Description highlight
	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start + 1, range.desc_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_start + 1, end_col = range.desc_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.heading
vimdoc.heading_no_delim = function (buffer, item)
	---@type helpview.config.vimdoc.headings?
	local main_config = spec.get({ "vimdoc", "headings" });

	if not main_config then
		return;
	elseif not main_config["heading_" .. item.level] then
		return;
	end

	---@type helpview.config.vimdoc.headings.opts
	local config = main_config["heading_" .. item.level];
	local range = item.range;

	if not config then
		return;
	end

	---@type string
	local sign = config.sign or "";

	local label = config.label or { "", "" };
	local label_hl = config.label_hl or {};

	local used_width = vim.fn.strdisplaywidth(item.text[1] .. label[1] .. sign .. label[2]);

	if item.level == 4 then
		used_width = used_width - 2;
	end

	--- Background
	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		end_col = range.col_start + #item.text[1] - (item.level == 4 and 2 or 0),
		undo_restore = false, invalidate = true,

		hl_group = utils.set_hl(config.hl)
	});

	--- Top border.
	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start + #item.text[1] - (item.level == 4 and 2 or 0), {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ string.rep(config.marker or " ", vim.bo[buffer].tw - used_width), utils.set_hl(config.marker_hl or config.hl) },
			{ label[1], utils.set_hl(label_hl[1] or config.hl) },
			{ sign, utils.set_hl(config.sign_hl or config.hl) },
			{ label[2], utils.set_hl(label_hl[2] or config.hl) },
		},
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.hl
vimdoc.hl = function (buffer, item)
	---@type helpview.config.vimdoc.highlights?
	local config = spec.get({ "vimdoc", "highlight_groups" });
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl or item.group_name) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl or item.group_name) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl or item.group_name) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl or item.group_name) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl or item.group_name) }
		},

		hl_mode = "combine"
	});

	if has_decorations(config) then
		vimdoc.__fix_indent(buffer, item, 0);
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = item.group_name
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.hr
vimdoc.hr = function (buffer, item)
	local config = spec.get({ "vimdoc", "horizontal_rules" });
	local range = item.range;

	if not config then
		return;
	end

	local _v = {};

	local function index (src, val, wrap)
		if vim.islist(src) == false then
			return src;
		elseif val <= #src then
			return src[val];
		elseif wrap == true then
			return src[val % #src];
		else
			return src[#src];
		end
	end

	for _, part in ipairs(config.parts or {}) do
		if part.type == "text" then
			---@cast part helpview.config.vimdoc.hr.text

			table.insert(_v, { part.text, utils.set_hl(part.hl) });
		elseif part.type == "repeating" then
			---@cast part helpview.config.vimdoc.hr.repeating

			local rep = part.repeat_amount or 0;

			if type(rep) == "function" then
				rep = rep(buffer, item);
			end

			local hl_rep = part.repeat_hl or false;
			local txt_rep = part.repeat_text or false;

			for r = 1, rep, 1 do
				if part.direction == "right" then
					table.insert(_v, {
						index(part.text, (rep - r) + 1, txt_rep),
						utils.set_hl(index(part.hl, (rep - r) + 1, hl_rep))
					})
				else
					table.insert(_v, {
						index(part.text, r, txt_rep),
						utils.set_hl(index(part.hl, r, hl_rep))
					})
				end
			end
		end
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "overlay",
		virt_text = _v,

		hl_mode = "combine"
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.inline_code
vimdoc.inline_code = function (buffer, item)
	---@type helpview.config.vimdoc.inline_codes?
	local config = spec.get({ "vimdoc", "inline_codes" });
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.keycode
vimdoc.keycode = function (buffer, item)
	---@type helpview.config.vimdoc.keycodes?
	local main_config = spec.get({ "vimdoc", "keycodes" });

	if not main_config then
		return;
	end

	---@type helpview.config.vimdoc.inline?
	local config = utils.match(main_config, item.label, {
		ignore_keys = { "enable", "default" }
	});
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	---@type string Added virtual text.
	local ext = table.concat({
		config.padding_left or "",
		config.corner_left or "",
		config.icon or "",

		config.padding_right or "",
		config.corner_right or ""
	});

	if has_decorations(config) then
		vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext));
	end

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.modeline
vimdoc.modeline = function (buffer, item)
	---@type helpview.config.vimdoc.modelines?
	local config = spec.get({ "vimdoc", "modelines" });
	local range = item.range;

	if not config then
		return;
	end

	local _v = {};
	local type_config = config.data_types or {};
	local l, r = math.ceil((vim.bo[buffer].tw - 1) / 2), math.floor((vim.bo[buffer].tw - 1) / 2);

	table.insert(_v, {
		{
			string.format("% " .. l .. "s", "Option"),
			utils.set_hl(config.default and config.default.option_hl)
		},
		{ " " },
		{
			string.format("%-" .. r .. "s", "Value"),
			utils.set_hl(config.default and config.default.value_hl)
		},
	});

	table.insert(_v, {
		{
			string.rep(config.border or "-", l),
			utils.set_hl(config.border_hl)
		},
		{ " " },
		{
			string.rep(config.border or "-", r),
			utils.set_hl(config.border_hl)
		},
	});

	for _, opt in ipairs(item.options) do
		local option_config = type_config[type(opt.value)] or {};

		option_config = vim.tbl_extend("keep",
			option_config,
			utils.match(config, opt.option, { ignore_keys = { "data_types" }
		}));

		table.insert(_v, {
			{
				string.format("% " .. l .. "s", opt.option),
				utils.set_hl(option_config.option_hl)
			},
			{ " " },
			{
				string.format("%-" .. r .. "s", vim.inspect(opt.value)),
				utils.set_hl(option_config.value_hl)
			},
		});
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end, end_col = range.col_end,
		conceal = "",

		virt_lines_above = true,
		virt_lines = _v,

		virt_text_pos = "overlay",
		virt_text = _v[2],

		hl_mode = "combine"
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.note
vimdoc.note = function (buffer, item)
	---@type helpview.config.vimdoc.notes?
	local main_config = spec.get({ "vimdoc", "notes" });

	if not main_config then
		return;
	end

	---@type helpview.config.vimdoc.inline?
	local config = utils.match(main_config, item.label, {
		ignore_keys = { "enable", "default" }
	});
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.optionlink
vimdoc.optionlink = function (buffer, item)
	---@type helpview.config.vimdoc.optionlinks?
	local main_config = spec.get({ "vimdoc", "optionlinks" });

	if not main_config then
		return;
	end

	---@type helpview.config.vimdoc.inline?
	local config = utils.match(main_config, item.label, {
		ignore_keys = { "enable", "default" }
	});
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	---@type string Added virtual text.
	local ext = table.concat({
		config.padding_left or "",
		config.corner_left or "",
		config.icon or "",

		config.padding_right or "",
		config.corner_right or ""
	});

	if has_decorations(config) then
		vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext));
	end

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.tag
vimdoc.tag = function (buffer, item)
	---@type helpview.config.vimdoc.tags?
	local main_config = spec.get({ "vimdoc", "tags" });

	if not main_config then
		return;
	end

	---@type helpview.config.vimdoc.inline?
	local config = utils.match(main_config, item.tag, {
		ignore_keys = { "enable", "default" }
	});
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	---@type string Added virtual text.
	local ext = table.concat({
		config.padding_left or "",
		config.corner_left or "",
		config.icon or "",

		config.padding_right or "",
		config.corner_right or ""
	});

	if has_decorations(config) then
		vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext) - 2);
	end

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.taglink
vimdoc.taglink = function (buffer, item)
	---@type helpview.config.vimdoc.taglinks?
	local main_config = spec.get({ "vimdoc", "taglinks" });

	if not main_config then
		return;
	end

	---@type helpview.config.vimdoc.inline?
	local config = utils.match(main_config, item.label, {
		ignore_keys = { "enable", "default" }
	});
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	---@type string Added virtual text.
	local ext = table.concat({
		config.padding_left or "",
		config.corner_left or "",
		config.icon or "",

		config.padding_right or "",
		config.corner_right or ""
	});

	if has_decorations(config) then
		vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext) - 2);
	end

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});
end

---@param buffer integer
---@param item helpview.parsed.vimdoc.taglink
vimdoc.url = function (buffer, item)
	---@type helpview.config.vimdoc.taglinks?
	local main_config = spec.get({ "vimdoc", "urls" });

	if not main_config then
		return;
	end

	---@type helpview.config.vimdoc.inline?
	local config = utils.match(main_config, item.label, {
		ignore_keys = { "enable", "default" }
	});
	local range = item.range;

	if not config then
		return;
	end

	config = utils.tostatic(config, { args = { buffer, item } });

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	if config.text then
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = {
				{ config.text or "", utils.set_hl(config.hl) },
			},

			hl_mode = "combine"
		});
	elseif config.hl then
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,end_col = range.col_end,

			hl_group = utils.set_hl(config.hl)
		});
	end
end

--- Renders content.
---@param buffer integer
---@param content table
vimdoc.render = function (buffer, content)
	--- Clear the message namespace.
	vimdoc.__message_clear(buffer, content)

	--- Custom renderers.
	---@type { [string]: fun(buffer: integer, item: table): nil }
	local custom_renderers = spec.get({ "renderers" }, { fallback = {} });
	vimdoc.lnum_offsets = {};

	for _, item in ipairs(content or {}) do
		local success, error;

		if custom_renderers[item.class] then
			success, error = pcall(custom_renderers[item.class], buffer, item);
		else
			success, error = pcall(vimdoc[item.class:gsub("^vimdoc%_", "")], buffer, item);
		end

		if success == false then
			vimdoc[item.class:gsub("^vimdoc%_", "")](buffer, item)
			require("helpview.health").notify("trace", {
				level = 4,
				message = error
			});
		end
	end
end

--- Clears help message namespace.
---@param buffer integer
---@param content table[]
vimdoc.__message_clear = function (buffer, content)
	--- Map of namespace IDs.
	---@type { [string]: integer }
	local namespaces = vim.api.nvim_get_namespaces();

	if not namespaces["nvim.vimdoc.run_message"] then
		--- Message namespace doesn't exist.
		--- Abort.
		return;
	elseif not package.loaded["helpview.renderer"] or not package.loaded["helpview.renderer"].get_range then
		--- In case the renderer module isn't available
		--- just clear everything.
		vim.api.nvim_buf_clear_namespace(buffer, namespaces["nvim.vimdoc.run_message"], 0, -1);
	else
		--- Line range to clear.
		---@type integer, integer
		local from, to = package.loaded["helpview.renderer"].get_range({
			vimdoc = content
		});

		vim.api.nvim_buf_clear_namespace(buffer, namespaces["nvim.vimdoc.run_message"], from, to);
	end
end

--- Clears preview decorations.
---@param buffer integer
---@param from integer | nil
---@param to integer | nil
vimdoc.clear = function (buffer, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, vimdoc.ns, from or 0, to or -1);
end

return vimdoc;
