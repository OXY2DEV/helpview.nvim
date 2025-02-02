local vimdoc = {};
local spec = require("helpview.spec");
local filetypes = require("helpview.filetypes");
local utils = require("helpview.utils");

vimdoc.ns = vim.api.nvim_create_namespace("helpview/vimdoc");
vimdoc.lnum_offsets = {};

vimdoc.__fix_indent = function (buffer, item, offset)
	---+

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

	---_
end

vimdoc.heading = function (buffer, item)
	---+${lua}

	local main_config = spec.get({ "vimdoc", "headings" });

	if not main_config then
		return;
	elseif not main_config["heading_" .. item.level] then
		return;
	end

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
	---_
end

vimdoc.heading_no_delim = function (buffer, item)
	---+

	local main_config = spec.get({ "vimdoc", "headings" });

	if not main_config then
		return;
	elseif not main_config["heading_" .. item.level] then
		return;
	end

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

	---_
end

vimdoc.hr = function (buffer, item)
	---+${lua}

	local range = item.range;
	local config = spec.get({ "vimdoc", "horizontal_rules" });

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
			table.insert(_v, { part.text, utils.set_hl(part.hl) });
		elseif part.type == "repeating" then
			local rep = part.repeat_amount or 0;

			if type(rep) == "function" then
				rep = rep(buffer, item);
			end

			local hl_rep = part.repeat_hl or false;
			local txt_rep = part.text_repeat or false;

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
	---_
end

vimdoc.tag = function (buffer, item)
	---+${lua}

	local main_config = spec.get({ "vimdoc", "tags" });

	if not main_config then
		return;
	end

	local config = utils.match(main_config, item.tag, {});
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

	vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext) - 2);

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});

	---_
end

vimdoc.taglink = function (buffer, item)
	---+${lua}

	local main_config = spec.get({ "vimdoc", "taglinks" });

	if not main_config then
		return;
	end

	local config = utils.match(main_config, item.label, {});
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

	vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext) - 2);

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});

	---_
end

vimdoc.optionlink = function (buffer, item)
	---+${lua}

	local main_config = spec.get({ "vimdoc", "optionlinks" });

	if not main_config then
		return;
	end

	local config = utils.match(main_config, item.label, {});
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

	vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext));

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});

	---_
end

vimdoc.keycode = function (buffer, item)
	---+${lua}

	local main_config = spec.get({ "vimdoc", "keycodes" });

	if not main_config then
		return;
	end

	local config = utils.match(main_config, item.label, {});
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

	vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext));

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});

	---_
end

vimdoc.note = function (buffer, item)
	---+${lua}

	local main_config = spec.get({ "vimdoc", "notes" });

	if not main_config then
		return;
	end

	local config = utils.match(main_config, item.label, {});
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

	---_
end

vimdoc.argument = function (buffer, item)
	---+${lua}

	local main_config = spec.get({ "vimdoc", "arguments" });

	if not main_config then
		return;
	end

	local config = utils.match(main_config, item.label, {});
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

	vimdoc.__fix_indent(buffer, item, vim.fn.strdisplaywidth(ext) - 2);

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,end_col = range.col_end,

		hl_group = utils.set_hl(config.hl)
	});

	---_
end

vimdoc.inline_code = function (buffer, item)
	---+${lua}

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

	---_
end

vimdoc.code_block = function (buffer, item)
	---+${lua}

	local config = spec.get({ "vimdoc", "code_blocks" });
	local range = item.range;

	if not config then
		return;
	end

	local function get_line_config (line)
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

		return line_config;
	end

	local decorations = filetypes.get(item.language);
	local label = { string.format(" %s%s ", decorations.icon, decorations.name), utils.set_hl(config.label_hl or decorations.icon_hl) };

	if item.use_virt_line == true then
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1 + #(item.language or ""),
			conceal = "",

			virt_lines = {
				{
					{ "" }
				},
				{
					label,
					{ string.rep(" ", vim.o.columns), utils.set_hl(config.border_hl) }
				}
			}
		});
	else
		vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1 + #(item.language or ""),
			conceal = "",

			virt_text_pos = "overlay",
			virt_text = { label },
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

	vim.api.nvim_buf_set_extmark(buffer, vimdoc.ns, range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_lines_above = true,
		virt_lines = {
			{
				{ string.rep(" ", vim.o.columns), utils.set_hl(config.border_hl) },
			}
		}
	});

	---_
end

vimdoc.modeline = function (buffer, item)
	---+${lua}

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

	---_
end

vimdoc.render = function (buffer, content)
	vimdoc.lnum_offsets = {};

	for _, item in ipairs(content or {}) do
		local _, err = pcall(vimdoc[item.class:gsub("^vimdoc%_", "")], buffer, item);
		-- if err then
		-- 	vim.print(err);
		-- end
	end
end

vimdoc.clear = function (buffer, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, vimdoc.ns, from or 0, to or -1);
end

return vimdoc;
