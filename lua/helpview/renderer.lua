local renderer = {};

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

local set_hl = function (hl)
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

	if conf.style == "decorated" then
		if data.delimiter then
			vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
				end_col = vim.fn.strchars(data.delimiter),
				conceal = ""
			});

			vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, vim.fn.strchars(data.delimiter), {
				virt_text_pos = "inline",
				virt_text = {
					{ conf.parts[1] or "", set_hl(conf.hls and conf.hls[1]) },
					{ string.rep(conf.parts[2] or "", buffer_info.width - vim.fn.strchars(conf.parts[3] or "") * 2), set_hl(conf.hls and conf.hls[2]) },
					{ conf.parts[3] or "", set_hl(conf.hls and conf.hls[3]) },
				},
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
				virt_lines_above = true,
				virt_lines = {
					{
						{ conf.parts[1] or "", set_hl(conf.hls and conf.hls[1]) },
						{ string.rep(conf.parts[2] or "", buffer_info.width - vim.fn.strchars(conf.parts[3] or "") * 2), set_hl(conf.hls and conf.hls[2]) },
						{ conf.parts[3] or "", set_hl(conf.hls and conf.hls[3]) },
					}
				},
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.delimiter and data.row_start + 1 or data.row_start, 0, {
			virt_text_pos = "inline",
			virt_text = {
				{ conf.parts[4] or "", set_hl(conf.hls and conf.hls[4]) },
				{ " " },
			}
		});

		-- BUG: Fix the incorrect size of lines containing
		-- a mix of tabs and spaces
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.delimiter and data.row_start + 1 or data.row_start, #data.text, {
			virt_text_pos = "eol",
			virt_text = {
				{ conf.parts[6] or "", set_hl(conf.hls and conf.hls[6]) }
			},

			virt_lines = {
				{
					{ conf.parts[7], set_hl(conf.hls and conf.hls[7]) },
					{ string.rep(conf.parts[8] or "", buffer_info.width - vim.fn.strchars((conf.parts[7] or "") .. (conf.parts[9] or ""))), set_hl(conf.hls and conf.hls[8]) },
					{ conf.parts[9], set_hl(conf.hls and conf.hls[9]) },
				}
			}
		});
	elseif conf.style == "border" then
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.delimiter and data.row_start + 1 or data.row_start, 0, {
			virt_text_pos = "inline",
			virt_text = {
				{ " " },
			}
		});

		-- BUG: Fix the incorrect size of lines containing
		-- a mix of tabs and spaces
		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.delimiter and data.row_start + 1 or data.row_start, #data.text, {
			virt_text_pos = "eol",
			virt_text = {
				{ conf.parts[6] or "", set_hl(conf.hls and conf.hls[6]) }
			},

			virt_lines = {
				{
					{ conf.parts[1], set_hl(conf.hls and conf.hls[1]) },
					{ string.rep(conf.parts[2] or "", buffer_info.width - vim.fn.strchars((conf.parts[1] or "") .. (conf.parts[3] or ""))), set_hl(conf.hls and conf.hls[2]) },
					{ conf.parts[3], set_hl(conf.hls and conf.hls[3]) },
				}
			}
		});
	end
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
						set_hl(tbl_clamp(part.hl, r))
					})
				end
			else
				for r = 1, repeat_amount do
					--- NOTE: Can't be 0
					table.insert(_v, {
						tbl_clamp(part.text or "─", (repeat_amount - r) + 1),
						set_hl(tbl_clamp(part.hl, (repeat_amount - r) + 1))
					})
				end
			end
		elseif part.type == "text" then
			table.insert(_v, { part.text, set_hl(part.hl) });
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

	local top_decorations_len = vim.fn.strchars((config_table.parts[1] or "") .. " " .. (data.description or "") .. " " .. (config_table.parts[3] or ""))
	local title_length = vim.fn.strchars((config_table.parts[4] or "") .. " " .. data.title .. " " .. (config_table.parts[6] or ""))
	local Bottom_decorations_len = vim.fn.strchars((config_table.parts[7] or "").. (config_table.parts[9] or ""))

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
		virt_text_pos = "overlay",
		virt_text = {
			{ config_table.parts[1] or "", set_hl(config_table.hls and config_table.hls[1]) },
			{ string.rep(config_table.parts[2], buffer_info.width - top_decorations_len), set_hl(config_table.hls and config_table.hls[4]) },
			{ " " .. (data.description or "") .. " ", set_hl(config_table.description_hl) },
			{ config_table.parts[3] or "", set_hl(config_table.hls and config_table.hls[3]) },
		},
		virt_lines = {
			{
				{ config_table.parts[4] or "", set_hl(config_table.hls and config_table.hls[4]) },
				{ " " },
				{ data.title, set_hl(config_table.title_hl) },
				{ string.rep(config_table.parts[5], buffer_info.width - title_length) },
				{ " " },
				{ config_table.parts[6] or "", set_hl(config_table.hls and config_table.hls[6]) },
			},
			{
				{ config_table.parts[7] or "", set_hl(config_table.hls and config_table.hls[7]) },
				{ string.rep(config_table.parts[8], buffer_info.width - Bottom_decorations_len), set_hl(config_table.hls and config_table.hls[4]) },
				{ config_table.parts[9] or "", set_hl(config_table.hls and config_table.hls[9]) },
			}
		},

		hl_mode = "combine"
	});
end

renderer.render_inline = function (buffer, data, config_table)
	if not config_table or config_table.enable == false then
		return;
	end

	-- NOTE: The markers are hidden but you should add extmarks after them to remove unnecessary bugs
	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start + (config_table.shift_before or 0), {
		virt_text_pos = "inline",
		virt_text = {
			{ config_table.corner_left or "", set_hl(config_table.corner_left_hl) or set_hl(config_table.hl) },
			{ config_table.padding_left or "", set_hl(config_table.padding_left_hl) or set_hl(config_table.hl) },
			{ config_table.icon or "", set_hl(config_table.icon_hl) or set_hl(config_table.hl) }
		},

		hl_mode = "combine",
		priority = 1,

		right_gravity = false,

		end_col = config_table.conceal_before and data.col_start + config_table.conceal_before or nil,
		conceal = config_table.conceal_before and "" or nil
	});

	if config_table.hl then
		vim.api.nvim_buf_add_highlight(buffer, renderer.namespace, set_hl(config_table.hl), data.row_start, data.col_start, data.col_end);
	end

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, config_table.conceal_after and data.col_end - config_table.conceal_after or data.col_end, {
		virt_text_pos = "inline",
		virt_text = {
			{ config_table.padding_right or "", set_hl(config_table.padding_right_hl) or set_hl(config_table.hl) },
			{ config_table.corner_right or "", set_hl(config_table.corner_right_hl) or set_hl(config_table.hl) },
		},

		hl_mode = "combine",
		priority = 5,

		end_col = config_table.conceal_after and data.col_end or nil,
		conceal = config_table.conceal_after and "" or nil
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

	-- NOTE: The markers are hidden but you should add extmarks after them to remove unnecessary bugs
	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start, {
		virt_text_pos = "inline",
		virt_text = {
			{ conf.corner_left or "", set_hl(conf.corner_left_hl) or set_hl(conf.hl) },
			{ conf.padding_left or "", set_hl(conf.padding_left_hl) or set_hl(conf.hl) },
			{ conf.icon or "", set_hl(conf.icon_hl) or set_hl(conf.hl) }
		},

		hl_mode = "combine",
		priority = 5,

		end_col = conf.conceal_before and data.col_start + conf.conceal_before or nil,
		conceal = conf.conceal_before and "" or nil
	});

	if conf.hl then
		vim.api.nvim_buf_add_highlight(buffer, renderer.namespace, set_hl(conf.hl), data.row_start, data.col_start, data.col_end == #data.text and data.col_end + 1 or data.col_end);
	end

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, conf.conceal_after and data.col_end - conf.conceal_after or data.col_end, {
		virt_text_pos = "inline",
		virt_text = {
			{ conf.padding_right or "", set_hl(conf.padding_right_hl) or set_hl(conf.hl) },
			{ conf.corner_right or "", set_hl(conf.corner_right_hl) or set_hl(conf.hl) },
		},

		hl_mode = "combine",
		priority = 5,

		end_col = conf.conceal_after and data.col_end or nil,
		conceal = conf.conceal_after and "" or nil
	});
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

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start, {
		virt_text_pos = "inline",
		virt_text = {
			{ config_table.corner_left or "", set_hl(config_table.corner_left_hl or hl) },
			{ config_table.padding_left or "", set_hl(config_table.padding_left_hl or hl) },
			{ config_table.icon or "", set_hl(config_table.icon_hl or hl) }
		},

		hl_mode = "combine",
		priority = 5,

		end_col = config_table.conceal_before and data.col_start + config_table.conceal_before or nil,
		conceal = config_table.conceal_before and "" or nil
	});

	vim.api.nvim_buf_add_highlight(buffer, renderer.namespace, set_hl(hl), data.row_start, data.col_start, data.col_end);

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, config_table.conceal_after and data.col_end - config_table.conceal_after or data.col_end, {
		virt_text_pos = "inline",
		virt_text = {
			{ config_table.padding_right or "", set_hl(config_table.padding_right_hl or hl) },
			{ config_table.corner_right or "", set_hl(config_table.corner_right_hl or hl) },
		},

		hl_mode = "combine",
		priority = 5,

		end_col = config_table.conceal_after and data.col_end or nil,
		conceal = config_table.conceal_after and "" or nil
	});
end

renderer.render_code_blocks = function (buffer, data, config_table, buffer_info)
	if not config_table or config_table.enable == false then
		return;
	end

	local block_size = buffer_info.win_width;

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, 0, {
		virt_lines = {
			{
				{ string.rep(" ", block_size - vim.fn.strchars(data.language ~= "" and " " .. data.language .. " " or "")), config_table.hl },
				{ data.language ~= "" and " " .. data.language .. " " or "", config_table.language_hl }
			}
		},
		hl_mode = "combine",
		priority = 1
	})

	vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_end, 0, {
		virt_lines_above = true,
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

	if config_table.style == "oneliner" then
		local _v = {
			{ config_table.icon or "  ", config_table.icon_hl },
			{ config_table.selector or ".vim ", config_table.selector_hl },
			{ "{ ", config_table.surround_hl }
		};

		for _, option in ipairs(data.options or {}) do
			if option.key and option.value then
				local _o;

				if config_table.options[option.key] then
					_o = config_table.options[option.key];
				else
					_o = option;
				end

				table.insert(_v, { _o.key .. ": ", config_table.option_hl});

				if _o.type == "string" and not option.key:match([[ (['"])[^'"]+(['"]) ]]) then
					table.insert(_v, { '"' ..  _o.value .. '"', config_table.type_hl.string });
				elseif _o.type == "string" then
					table.insert(_v, { _o.value, config_table.type_hl.string });
				elseif _o.type == "number" then
					table.insert(_v, { _o.value, config_table.type_hl.number });
				elseif _o.type == "boolean" then
					table.insert(_v, { _o.value, config_table.type_hl.boolean });
				else
					table.insert(_v, { _o.value });
				end

				table.insert(_v, { "; ", config_table.seperator_hl });
			elseif option.text then
				if config_table.options[option.text] then
					local _o = config_table.options[option.text];

					table.insert(_v, { _o.key .. ": ", config_table.option_hl});

					if _o.type == "string" and not option.key:match([[ (['"])[^'"]+(['"]) ]]) then
						table.insert(_v, { '"' ..  _o.value .. '"', config_table.type_hl.string });
					elseif _o.type == "string" then
						table.insert(_v, { _o.value, config_table.type_hl.string });
					elseif _o.type == "number" then
						table.insert(_v, { _o.value, config_table.type_hl.number });
					elseif _o.type == "boolean" then
						table.insert(_v, { _o.value, config_table.type_hl.boolean });
					else
						table.insert(_v, { _o.value });
					end

					table.insert(_v, { "; ", config_table.seperator_hl });
				end
			end
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
				{ config_table.icon or "  ", config_table.icon_hl },
				{ config_table.selector or ".vim ", config_table.selector_hl },
				{ "{ ", config_table.surround_hl }
			}
		};

		for _, option in ipairs(data.options or {}) do
			local _l = { { "	" }};

			if option.key and option.value then
				local _o;

				if config_table.options[option.key] then
					_o = vim.tbl_extend("keep", config_table.options[option.key], option);
				else
					_o = option;
				end

				table.insert(_l, { _o.key .. ": ", config_table.option_hl});

				if _o.type == "string" and not option.key:match([[ (['"])[^'"]+(['"]) ]]) then
					table.insert(_l, { '"' ..  _o.value .. '"', config_table.type_hl.string });
				elseif _o.type == "string" then
					table.insert(_l, { _o.value, config_table.type_hl.string });
				elseif _o.type == "number" then
					table.insert(_l, { _o.value, config_table.type_hl.number });
				elseif _o.type == "boolean" then
					table.insert(_l, { _o.value, config_table.type_hl.boolean });
				else
					table.insert(_l, { _o.value });
				end

				table.insert(_l, { "; ", config_table.seperator_hl });
			elseif option.text then
				if config_table.options[option.text] then
					local _o = config_table.options[option.text];

					table.insert(_l, { _o.key .. ": ", config_table.option_hl});

					if _o.type == "string" and not option.key:match([[ (['"])[^'"]+(['"]) ]]) then
						table.insert(_l, { '"' ..  _o.value .. '"', config_table.type_hl.string });
					elseif _o.type == "string" then
						table.insert(_l, { _o.value, config_table.type_hl.string });
					elseif _o.type == "number" then
						table.insert(_l, { _o.value, config_table.type_hl.number });
					elseif _o.type == "boolean" then
						table.insert(_l, { _o.value, config_table.type_hl.boolean });
					else
						table.insert(_l, { _o.value });
					end

					table.insert(_l, { "; ", config_table.seperator_hl });
				end
			end

			table.insert(_v, _l)
		end

		table.insert(_v, {
			{ "}", config_table.surround_hl }
		});

		vim.api.nvim_buf_set_extmark(buffer, renderer.namespace, data.row_start, data.col_start, {
			virt_lines_above = true;
			virt_lines = _v,

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

	for _, data in ipairs(_G.__helpview_views[buffer]) do
		if data.type == "heading" then
			renderer.render_headings(buffer, data, config_table, buffer_info);
		elseif data.type == "title" then
			renderer.render_title(buffer, data, config_table.title, buffer_info)
		elseif data.type == "highlight_group" then
			renderer.render_hl(buffer, data, config_table.hls)
		elseif data.type == "tag" then
			renderer.render_inline(buffer, data, config_table.tags)
		elseif data.type == "link" then
			renderer.render_inline(buffer, data, config_table.links)
		elseif data.type == "option_link" then
			renderer.render_inline(buffer, data, config_table.option_links)
		elseif data.type == "key_code" then
			renderer.render_inline(buffer, data, config_table.key_codes)
		elseif data.type == "argument" then
			renderer.render_inline(buffer, data, config_table.arguments)
		elseif data.type == "inline_code" then
			renderer.render_inline(buffer, data, config_table.inline_codes)
		elseif data.type == "note" then
			renderer.render_notes(buffer, data, config_table.notes)
		elseif data.type == "code_block" then
			renderer.render_code_blocks(buffer, data, config_table.code_blocks, buffer_info)
		elseif data.type == "modeline" then
			renderer.render_modeline(buffer, data, config_table.modelines)
		elseif data.type == "horizontal_rule" then
			renderer.render_horizontal_rules(buffer, data, config_table.horizontal_rules, buffer_info)
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

renderer.clear = function (buffer)
	vim.api.nvim_buf_clear_namespace(buffer, renderer.namespace, 0, -1);
end

renderer.partial_render = function (buffer, from, to, config_table, buffer_info)
	for _, data in ipairs(_G.__helpview_views[buffer]) do
		if data.row_start < from or data.row_start > to then
			goto outOfRange;
		end

		if data.type == "heading" then
			renderer.render_headings(buffer, data, config_table, buffer_info);
		elseif data.type == "title" then
			renderer.render_title(buffer, data, config_table.title, buffer_info)
		elseif data.type == "highlight_group" then
			renderer.render_hl(buffer, data, config_table.hls)
		elseif data.type == "tag" then
			renderer.render_inline(buffer, data, config_table.tags)
		elseif data.type == "link" then
			renderer.render_inline(buffer, data, config_table.links)
		elseif data.type == "option_link" then
			renderer.render_inline(buffer, data, config_table.option_links)
		elseif data.type == "key_code" then
			renderer.render_inline(buffer, data, config_table.key_codes)
		elseif data.type == "argument" then
			renderer.render_inline(buffer, data, config_table.arguments)
		elseif data.type == "inline_code" then
			renderer.render_inline(buffer, data, config_table.inline_codes)
		elseif data.type == "note" then
			renderer.render_notes(buffer, data, config_table.notes)
		elseif data.type == "code_block" then
			renderer.render_code_blocks(buffer, data, config_table.code_blocks, buffer_info)
		elseif data.type == "modeline" then
			renderer.render_modeline(buffer, data, config_table.modelines)
		elseif data.type == "horizontal_rule" then
			renderer.render_horizontal_rules(buffer, data, config_table.horizontal_rules, buffer_info)
		end

		::outOfRange::
	end
end

renderer.partial_clear = function (buffer, from, to)
	local buf_size = vim.api.nvim_buf_line_count(buffer);

	vim.api.nvim_buf_clear_namespace(buffer, renderer.namespace, from < 0 and 0 or from, to > buf_size and buf_size or to);
end

return renderer;
