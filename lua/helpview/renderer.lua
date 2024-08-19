local renderer = {};
local languages = require("helpview.languages");

local tbl_clamp = function (entry, index)
	if type(entry) ~= "table" then
		return entry;
	end

	if index >= #entry then
		return entry[#entry];
	else
		return entry[index];
	end
end

local get_win = function (buffer)
	local wins = vim.api.nvim_list_wins();

	for _, win in ipairs(wins) do
		if vim.api.nvim_win_get_buf(win) == buffer then
			return win;
		end
	end
end

renderer.set_hl = function (hl)
	if type(hl) ~= "string" then
		return;
	end

	if vim.fn.hlexists("Helpview" .. hl) == 1 then
		return "Helpview" .. hl;
	elseif vim.fn.hlexists("Helpview_" .. hl) == 1 then
		return "Helpview_" .. hl;
	else
		return hl;
	end
end

renderer.namespace = vim.api.nvim_create_namespace("helpview");

renderer.render_headings = function (buffer, data, global_config, buffer_info)
	if not global_config or not global_config.headings or global_config.headings.enable == false then
		return;
	end

	local heading_config = global_config.headings or {};

	local conf = heading_config["heading_" .. data.level];

	if data.delimiter then
		local marker = vim.fn.strcharpart(data.delimiter, 0, 1);

		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
			virt_text_pos = "overlay",
			virt_text = {
				{ string.rep(conf.marker or marker or "", vim.o.columns), renderer.set_hl(conf.sign_hl or conf.hl) }
			},

			priority = 100,

			end_row = data.row_end
		});
	elseif conf.marker then
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
			virt_lines_above = true,
			virt_lines = {
				{
					{ string.rep(conf.marker, vim.o.columns), renderer.set_hl(conf.sign_hl or conf.hl) }
				}
			}
		});
	elseif conf.hl then
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
			hl_group = renderer.set_hl(conf.hl),
			priority = 100,

			end_col = data.col_end
		});
	end

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.__r_end or data.row_end, vim.fn.strchars(data.text), {
		virt_text_pos = "right_align",
		virt_text = {
			{ conf.sign or " ", renderer.set_hl(conf.sign_hl or conf.hl) }
		},

		line_hl_group = renderer.set_hl(conf.hl),
		priority = 1,
		hl_mode = "combine",
	});
end

renderer.render_horizontal_rules = function (buffer, data, config_table, buffer_info)
	if not config_table or config_table.enable == false then
		return;
	end

	local _v = {};

	for _, part in ipairs(config_table.parts or {}) do
		if part.type == "repeating" then
			local repeat_amount = 0;

			if type(part.repeat_amount) == "function" and pcall(part.repeat_amount, buffer_info) then
				repeat_amount = part.repeat_amount(buffer_info);
			else
				repeat_amount = part.repeat_amount;
			end

			if part.direction == nil or part.direction == "left" then
				for r = 1, repeat_amount do
					table.insert(_v, {
						tbl_clamp(part.text or "─", r),
						renderer.set_hl(tbl_clamp(part.hl, r))
					})
				end
			else
				for r = 1, repeat_amount do
					--- NOTE: Can't be 0
					table.insert(_v, {
						tbl_clamp(part.text or "─", (repeat_amount - r) + 1),
						renderer.set_hl(tbl_clamp(part.hl, (repeat_amount - r) + 1))
					})
				end
			end
		elseif part.type == "text" then
			table.insert(_v, { part.text, renderer.set_hl(part.hl) });
		end
	end

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start, {
		virt_text_pos = "overlay",
		virt_text = _v,

		end_col = data.col_end,
		conceal = "",

		hl_mode = "combine"
	});
end

renderer.render_title = function (buffer, data, config_table, buffer_info)
	if not config_table or config_table.enable == false then
		return;
	end

	if config_table.style == "simple" then
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
			virt_text_pos = "right_align",
			virt_text = {
				{ config_table.sign or " ", renderer.set_hl(config_table.sign_hl or config_table.hl) }
			},

			line_hl_group = renderer.set_hl(config_table.hl),
			hl_mode = "combine"
		});
	elseif config_table.style == "custom" then
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
			virt_text_pos = "right_align",
			virt_text = config_table.virt_text,

			line_hl_group = renderer.set_hl(config_table.hl),
			hl_mode = "combine"
		});
	elseif config_table.style == "decorated" then
		local top_decorations_len = vim.fn.strchars((config_table.parts[1] or "") .. " " .. (data.description or "") .. " " .. (config_table.parts[3] or ""))
		local title_length = vim.fn.strchars((config_table.parts[4] or "") .. " " .. data.title .. " " .. (config_table.parts[6] or ""))
		local Bottom_decorations_len = vim.fn.strchars((config_table.parts[7] or "").. (config_table.parts[9] or ""))

		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
			virt_text_pos = "overlay",
			virt_text = {
				{ tbl_clamp(config_table.parts, 1) or "", renderer.set_hl(tbl_clamp(config_table.hl, 1)) },
				{ string.rep(tbl_clamp(config_table.parts, 2) or "", buffer_info.width - top_decorations_len), renderer.set_hl(tbl_clamp(config_table.hl, 4)) },
				{ " " .. (data.description or "") .. " ", renderer.set_hl(config_table.description_hl) },
				{ tbl_clamp(config_table.parts, 3) or "", renderer.set_hl(tbl_clamp(config_table.hl, 1)) },
			},
			virt_lines = {
				{
					{ tbl_clamp(config_table.parts, 4) or "", renderer.set_hl(tbl_clamp(config_table.hl, 4)) },
					{ " " },
					{ data.title, renderer.set_hl(config_table.title_hl) },
					{ string.rep(tbl_clamp(config_table.parts, 5) or "", buffer_info.width - title_length), renderer.set_hl(tbl_clamp(config_table.hl, 5)) },
					{ " " },
					{ tbl_clamp(config_table.parts, 6) or "", renderer.set_hl(tbl_clamp(config_table.hl, 6)) },
				},
				{
					{ tbl_clamp(config_table.parts, 7) or "", renderer.set_hl(tbl_clamp(config_table.hl, 7)) },
					{ string.rep(tbl_clamp(config_table.parts, 8) or "", buffer_info.width - Bottom_decorations_len), renderer.set_hl(tbl_clamp(config_table.hl, 8)) },
					{ tbl_clamp(config_table.parts, 9) or "", renderer.set_hl(tbl_clamp(config_table.hl, 9)) },
				}
			},

			hl_mode = "combine"
		});
	end
end

renderer.component_renderer = function (buffer, data, config_table)
	if not config_table or config_table.enable == false then
		return;
	end

	local conceal_before, conceal_after = config_table.conceal_before, config_table.conceal_after;

	if config_table.conceal_before and pcall(config_table.conceal_before, data) then
		conceal_before = config_table.conceal_before(data);
	end

	if config_table.conceal_after and pcall(config_table.conceal_after, data) then
		conceal_after = config_table.conceal_after(data);
	end

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start, {
		virt_text_pos = "inline",
		virt_text = {
			{ config_table.padding_left or "", renderer.set_hl(config_table.hl) },
			{ config_table.icon or "", renderer.set_hl(config_table.hl) }
		},

		priority = 10,
		end_col = conceal_before and data.col_start + conceal_before or nil,
		conceal = conceal_before and "" or nil
	});

	if config_table.hl then
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, conceal_before and data.col_start + conceal_before or data.col_start, {
			virt_text_pos = "overlay",
			virt_text = {
				{ data.text, renderer.set_hl(config_table.hl) }
			},
			hl_group = renderer.set_hl(config_table.hl),

			hl_mode = "combine",
			virt_text_hide = true,
			priority = 10,
			end_col = data.col_end
		});
	end

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_end - (conceal_after or 0), {
		virt_text_pos = "inline",
		virt_text = {
			{ config_table.padding_right or "", renderer.set_hl(config_table.hl) },
		},

		priority = 10,

		end_col = conceal_after and data.col_end or nil,
		conceal = conceal_after and "" or nil
	});
end

renderer.render_notes = function (buffer, data, config_table)
	if not config_table or config_table.enable == false then
		return;
	end

	local conf = config_table.default;

	for key, value in pairs(config_table) do
		if key ~= "default" and key:upper() == data.text:upper() then
			conf = value;
			break;
		end
	end

	renderer.component_renderer(buffer, data, conf)
end

renderer.render_hl = function (buffer, data, config_table)
	if not config_table or config_table.enable == false then
		return;
	end

	local hl = data.name;

	if config_table.aliases and config_table.aliases[data.name] then
		hl = config_table.aliases[data.name];
	end

	if vim.fn.hlexists(hl) ~= 1 then
		return;
	end

	renderer.component_renderer(buffer, data, vim.tbl_extend("force", config_table, {
		hl = hl,

		conceal_before = 1,
		conceal_after = 1
	}));
end

renderer.render_code_blocks = function (buffer, data, config_table, buffer_info)
	if not config_table or config_table.enable == false then
		return;
	end

	local block_size = buffer_info.win_width;
	local icon = languages.get(data.language);
	local name = languages.name(data.language);

	local start_seg = " " .. icon .. name;

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
		virt_lines = {
			{
				{ start_seg, config_table.language_hl },
				{ string.rep(" ", block_size - vim.fn.strchars(start_seg)), config_table.hl },
			}
		},
		hl_mode = "combine",
		priority = 1
	})

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_end - 1, 0, {
		virt_lines = {
			{
				{ string.rep(" ", block_size), config_table.hl },
			}
		},
		hl_mode = "combine",
		priority = 1
	})

	for i = 1, data.row_end - data.row_start - 1 do
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start + i, 0, {
			line_hl_group = config_table.hl,
			hl_mode = "combine",
			priority = 1
		})
	end
end

renderer.render_modeline = function (buffer, data, config_table)
	if not config_table or config_table.enable == false then
		return;
	end

	if config_table.style == "minimal" then
		local _v = {
			{ config_table.icon or "  ", config_table.icon_hl },
			{ config_table.selector or ".vim ", config_table.selector_hl },
			{ "{ ", config_table.surround_hl }
		};

		for _, option in ipairs(data.options or {}) do
			local val = vim.o[option.name];

			if type(val) == "string" then
				if val:match('"') then
					val = "'" .. val .. "'";
				elseif val:match("'") then
					val = '"' .. val .. '"';
				elseif val:match([[ ["'] ]]) then
					val = "[[ " .. val .. " ]]";
				else
					val = '"' .. val .. '"';
				end
			end

			table.insert(_v, { option.name .. ": ", renderer.set_hl(config_table.option_hl) });
			table.insert(_v, { tostring(val) or "nil", renderer.set_hl("@" .. option.type) });
			table.insert(_v, { "; ", "@punctuation.delimiter" });
		end

		table.insert(_v, { "}", config_table.surround_hl })

		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start, {
			virt_text_pos = "overlay",
			virt_text = _v,

			hl_mode = "combine",

			end_col = data.col_end,
			conceal = ""
		})
	elseif config_table.style == "expanded" then
		local _v = {
			{
				{ config_table.icon or "  ", config_table.icon_hl },
				{ config_table.selector or ".nvim ", config_table.selector_hl },
				{ "{ ", config_table.surround_hl }
			}
		};

		for _, option in ipairs(data.options or {}) do
			local _l = { { "	" }};
			local val = vim.o[option.name];

			if type(val) == "string" then
				if val:match('"') then
					val = "'" .. val .. "'";
				elseif val:match("'") then
					val = '"' .. val .. '"';
				elseif val:match([[ ["'] ]]) then
					val = "[[ " .. val .. " ]]";
				else
					val = '"' .. val .. '"';
				end
			end

			table.insert(_l, { option.name .. ": ", renderer.set_hl(config_table.option_hl) });
			table.insert(_l, { tostring(val) or "nil", renderer.set_hl("@" .. option.type) });
			table.insert(_l, { "; ", "@punctuation.delimiter" });

			table.insert(_v, _l)
		end

		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start, {
			virt_lines_above = true;
			virt_lines = _v,

			virt_text_pos = "overlay",
			virt_text = {
				{ "}", config_table.surround_hl }
			},

			hl_mode = "combine",

			end_col = data.col_end,
			conceal = ""
		})
	end
end

renderer.render = function (buffer, parsed_content, config_table, buffer_info)
	if not _G.__helpview_views then
		_G.__helpview_views = {};
	end

	if parsed_content then
		_G.__helpview_views[buffer] = parsed_content
	end

	-- vim.print(#parsed_content)
	for _, data in ipairs(_G.__helpview_views[buffer]) do
		if data.type == "heading" then
			pcall(renderer.render_headings, buffer, data, config_table, buffer_info);
		elseif data.type == "title" then
			pcall(renderer.render_title, buffer, data, config_table.title, buffer_info)
		elseif data.type == "highlight_group" then
			pcall(renderer.render_hl, buffer, data, config_table.group_names)
		elseif data.type == "tag" then
			pcall(renderer.component_renderer, buffer, data, config_table.tag_links)
		elseif data.type == "link" then
			pcall(renderer.component_renderer, buffer, data, config_table.mention_links)
		elseif data.type == "option_link" then
			pcall(renderer.component_renderer, buffer, data, config_table.option_links)
		elseif data.type == "key_code" then
			pcall(renderer.component_renderer, buffer, data, config_table.keycodes)
		elseif data.type == "argument" then
			pcall(renderer.component_renderer, buffer, data, config_table.arguments)
		elseif data.type == "inline_code" then
			pcall(renderer.component_renderer, buffer, data, config_table.inline_codes)
		elseif data.type == "note" then
			pcall(renderer.render_notes, buffer, data, config_table.notes)
		elseif data.type == "code_block" then
			pcall(renderer.render_code_blocks, buffer, data, config_table.code_blocks, buffer_info)
		elseif data.type == "modeline" then
			pcall(renderer.render_modeline, buffer, data, config_table.modelines)
		elseif data.type == "horizontal_rule" then
			pcall(renderer.render_horizontal_rules, buffer, data, config_table.horizontal_rules, buffer_info)
		end
	end
end

renderer.updateView = function (buffer, parsed_content)
	if not _G.__helpview_views then
		_G.__helpview_views = {};
	end

	if parsed_content then
		_G.__helpview_views[buffer] = parsed_content
	end
end

renderer.clear = function (buffer, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, renderer.namespace, from or 0, to or -1);
end

renderer.get_content_range = function (content)
	local min, max;

	for _, data in ipairs(content) do
		if not min or data.row_start < min then
			min = data.row_start;
		end

		if not max or data.row_end > max then
			max = data.row_end;
		end
	end

	if min and max and min == max then
		max = max + 1;
	end

	return min, max;
end

return renderer;
