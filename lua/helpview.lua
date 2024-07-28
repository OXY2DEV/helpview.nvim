local helpview = {};
helpview.parser = require("helpview.parser");
helpview.renderer = require("helpview.renderer");

helpview.colors = require("helpview.colors");
helpview.utils = require("helpview.utils");

-- _, helpview.column = pcall(require, "helpview.extras.column");

helpview.add_hls = function (obj)
	local use_hl = {};

	for _, hl in ipairs(obj) do
		if hl.output and type(hl.output) == "function" and pcall(hl.output) then
			use_hl = vim.list_extend(use_hl, hl.output());
		else
			table.insert(use_hl, hl);
		end
	end

	for _, hl in ipairs(use_hl) do
		if not hl.value then
			goto continue;
		end

		local opt = hl.value;

		if type(hl.value) == "function" and pcall(hl.value) then
			opt = hl.value();
		end

		opt.default = true;
		vim.api.nvim_set_hl(0, hl.raw and hl.group_name or "Helpview" .. hl.group_name, opt);

		::continue::
	end
end

helpview.get_buffer_info = function (buffer)
	local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win());

	return {
		width = vim.bo[buffer].textwidth,
		win_width = vim.api.nvim_win_get_width(0) - wininfo[1].textoff,
		shift_width = vim.bo[buffer].tabstop
	};
end

helpview.attached_buffers = {};

helpview.state = {
	enable = true,
	buf_states = {}
};

helpview.configuration = {
	modes = { "n", "c" },
	-- buf_ignore = { "help" },

	highlight_groups = {
		{
			output = function ()
				local bg = helpview.colors.get_hl_value(0, "Normal", "bg");
				local inline_fg = helpview.colors.get_hl_value(0, "TablineSel", "fg");
				local tag_fg = helpview.colors.get_hl_value(0, "Title", "fg");
				local option_fg = helpview.colors.get_hl_value(0, "Tag", "fg");
				local taglink_fg = helpview.colors.get_hl_value(0, "Title", "fg");

				local h1_fg = helpview.colors.get_hl_value(0, "rainbow2", "fg") or helpview.colors.get_hl_value(0, "Title", "fg");
				local h2_fg = helpview.colors.get_hl_value(0, "rainbow3", "fg") or helpview.colors.get_hl_value(0, "WarningMsg", "fg");
				local h3_fg = helpview.colors.get_hl_value(0, "rainbow4", "fg") or helpview.colors.get_hl_value(0, "TablineSel", "fg");

				if vim.o.background == "dark" then
					return {
						{
							group_name = "h1",
							value = {
								fg = h1_fg
							}
						},
						{
							group_name = "h2",
							value = {
								fg = h2_fg
							}
						},
						{
							group_name = "h3",
							value = {
								fg = h3_fg
							}
						},
						{
							group_name = "InlineCodes",
							value = {
								bg = helpview.colors.mix(inline_fg, bg, 0.25, 0.15),
								fg = inline_fg
							}
						},
						{
							group_name = "Taglink",
							value = {
								bg = helpview.colors.mix(tag_fg, bg, 0.25, 0.15),
								fg = tag_fg
							}
						},
						-- {
						-- 	raw = true,
						-- 	group_name = "@label.vimdoc",
						-- 	value = {
						-- 		bg = helpview.colors.mix(tag_fg, bg, 0.25, 0.15),
						-- 		fg = tag_fg
						-- 	}
						-- },
						{
							group_name = "Optionlink",
							value = {
								bg = helpview.colors.mix(option_fg, bg, 0.25, 0.15),
								fg = option_fg
							}
						},
						{
							group_name = "Mentionlink",
							value = {
								-- bg = helpview.colors.mix(taglink_fg, bg, 0.25, 0.15),
								fg = taglink_fg,
								underline = true
							}
						},

						{
							group_name = "CodeBlocks",
							value = {
								bg = helpview.colors.mix(bg, bg, 0.5, 0.75),
							}
						},
						{
							group_name = "CodeBlocksLanguage",
							value = {
								bg = helpview.colors.mix(bg, bg, 0.5, 0.75),
								fg = inline_fg
							}
						},
					}
				else
					return {
						{
							group_name = "InlineCodes",
							value = {
								bg = helpview.colors.mix(inline_fg, bg, 0.5, 0.65),
								fg = inline_fg
							}
						},
						{
							group_name = "Taglink",
							value = {
								bg = helpview.colors.mix(tag_fg, bg, 0.5, 0.65),
								fg = tag_fg
							}
						},
						{
							group_name = "Optionlink",
							value = {
								bg = helpview.colors.mix(option_fg, bg, 0.5, 0.65),
								fg = option_fg
							}
						},
						{
							group_name = "Mentionlink",
							value = {
								-- bg = helpview.colors.mix(taglink_fg, bg, 0.5, 0.65),
								fg = taglink_fg,
								underline = true
							}
						},

						{
							group_name = "CodeBlocks",
							value = {
								bg = helpview.colors.mix(bg, bg, 0.5, 0.75),
							}
						},
						{
							group_name = "CodeBlocksLanguage",
							value = {
								bg = helpview.colors.mix(bg, bg, 0.5, 0.75),
								fg = inline_fg
							}
						},
					}
				end
			end
		},
		{
			output = function ()
				local from = helpview.colors.get_hl_value(0, "Normal", "bg") or "#1e1e2e";
				local to = helpview.colors.get_hl_value(0, "rainbow4", "fg");

				return helpview.colors.create_gradient("Gradient", from, to, 10, "fg")
			end
		}
	},

	headings = {
		heading_1 = {
			style = "decorated",

			parts = {
				"╭", "─", "╮",
				"│", " ", "",
				"╰", "─", "╯"
			},

			hls = {
				"h1", "h1", "h1",
				"h1", "h1", "h1",
				"h1", "h1", "h1",
			}
		},
		heading_2 = {
			style = "decorated",

			parts = {
				"╭", "─", "╼",
				"│", " ", "",
				"╰", "─", "╼"
			},

			hls = {
				"h2", "h2", "h2",
				"h2", "h2", "h2",
				"h2", "h2", "h2",
			}
		},
		heading_3 = {
			style = "border",

			parts = {
				"╾", "─", "╼"
			},

			hls = {
				"h3", "h3", "h3",
			}
		},
	},
	title = {
		parts = {
			"╭", "─", "╮",
			"│", " ", "│",
			"╰", "─", "╯"
		},
		hls = {
			"Special", "Special", "Special",
			"Special", "Special", "Special",
			"Special", "Special", "Special",
		},
		title_hl = "Title",
		description_hl = "Comment"
	},

	hls = {
		enable = true,

		conceal_before = 1, conceal_after = 1
	},
	tags = {
		padding_left = " ",
		padding_right = " ",

		shift_before = 1,

		hl = "HelpviewTaglink"
	},
	links = {
		icon = " ",
		hl = "HelpviewMentionlink"
	},
	option_links = {
		padding_left = " ",
		padding_right = " ",

		icon = " ",
		hl = "HelpviewOptionLink",

		conceal_before = 1, conceal_after = 1
	},

	arguments = {
		icon = "󰂓 ",
		hl = "@variable.parameter.vimdoc",

		conceal_before = 1, conceal_after = 1
	},

	inline_codes = {
		padding_left = " ",
		padding_right = " ",

		hl = "HelpviewInlineCodes"
	},
	key_codes = {
		icon = "󰌌 ",
		hl = "Special"
	},

	code_blocks = {
		hl = "HelpviewCodeBlocks",
		language_hl = "HelpviewCodeBlocksLanguage"
	},

	notes = {
		default = {
			padding_right = " ",
			icon = "   ", hl = "@comment.note"
		},

		warning = {
			padding_right = " ",
			icon = "   ", hl = "@comment.warning"
		},

		deprecated = {
			padding_right = " ",
			icon = "  ", hl = "@comment.error"
		}
	},

	modelines = {
		style = "expanded",

		options = {
			nospell = {
				type = "boolean",

				key = "spell",
				value = "false"
			},
			ft = {
				type = "string",

				key = "filetype",
				value = nil
			},
			bt = {
				type = "string",

				key = "buftype",
				value = nil
			},

			tw = {
				type = "number",

				key = "textwidth",
				value = nil
			},
			ts = {
				type = "number",

				key = "tabsize",
				value = nil
			},
			isk = {
				type = "string",

				key = "iskeyword",
				value = nil
			},
			norl = {
				type = "boolean",

				key = "rightleft",
				value = "false"
			},
			noet = {
				type = "boolean",

				key = "expandtab",
				value = "false"
			}
		},
		type_hl = {
			string = "@string",
			number = "@number",
			boolean = "@boolean"
		},

		icon_hl = "rainbow4",
		selector_hl = "@property.class.css",
		surround_hl = "@punctuation.bracket",

		option_hl = "@property.css",
		seperator_hl = "@punctuation.delimiter"
	},

	horizontal_rules = {
		parts = {
			{
				type = "repeating",
				repeat_amount = function (buf_info)
					return math.floor((buf_info.width - 3) / 2);
				end,

				direction = "left",
				hl = { "HelpviewGradient1", "HelpviewGradient2", "HelpviewGradient3", "HelpviewGradient4", "HelpviewGradient5", "HelpviewGradient6" }
			},
			{
				type = "text",
				text = "  ",

				hl = "HelpviewGradient10"
			},
			{ -- Nerd font characters have 1.5x the width of
			  -- normal text. So we add this half character
				type = "text",
				text = "╶",

				hl = "HelpviewGradient6"
			},
			{
				type = "repeating",
				repeat_amount = function (buf_info)
					return math.floor((buf_info.width - 3) / 2) - 1;
				end,

				direction = "right",
				hl = { "HelpviewGradient1", "HelpviewGradient2", "HelpviewGradient3", "HelpviewGradient4", "HelpviewGradient5", "HelpviewGradient6" }
			},
		}
	}
};

helpview.commands = {
	toggleAll = function ()
		if helpview.state.enable == true then
			helpview.commands.disableAll();
		else
			helpview.commands.enableAll();
		end
	end,
	enableAll = function ()
		helpview.state.enable = true;

		for _, buf in ipairs(helpview.attached_buffers) do
			local parsed_content = helpview.parser.init(buf);
			local windows = helpview.get_attached_wins(buf);
			local buf_info = helpview.get_buffer_info(buf);

			if helpview.configuration.options and helpview.configuration.options.on_enable then
				for _, window in ipairs(windows) do
					if helpview.configuration and helpview.configuration.on_enable and pcall(helpview.configuration.options.on_enable, window, buf) then
						helpview.configuration.on_enable(window, buf);
					end
				end
			end


			helpview.renderer.clear(buf);
			helpview.renderer.render(buf, parsed_content, helpview.configuration, buf_info)
		end
	end,
	disableAll = function ()
		helpview.state.enable = false;

		for _, buf in ipairs(helpview.attached_buffers) do
			local windows = helpview.get_attached_wins(buf);

			if helpview.configuration.options and helpview.configuration.options.on_disable then
				for _, window in ipairs(windows) do
					if helpview.configuration and helpview.configuration.on_disable and pcall(helpview.configuration.options.on_disable, window, buf) then
						helpview.configuration.on_disable(window, buf);
					end
				end
			end

			helpview.renderer.clear(buf);
		end
	end,

	toggle = function (buffer)
		if not tonumber(buffer) or not vim.api.nvim_buf_is_valid(tonumber(buffer)) then
			return;
		end

		local state = helpview.state.buf_states[tonumber(buffer)];

		if state == false then
			helpview.commands.enable(buffer);
		else
			helpview.commands.disable(buffer);
		end
	end,
	enable = function (buffer)
		local buf = tonumber(buffer) or vim.api.nvim_get_current_buf();

		if not vim.list_contains(helpview.attached_buffers, buf) or not vim.api.nvim_buf_is_valid(buf) then
			return;
		end

		if helpview.configuration.options and helpview.configuration.options.on_enable then
			local windows = helpview.get_attached_wins(buf);

			-- Set some options
			for _, window in ipairs(windows) do
				if helpview.configuration and helpview.configuration.on_enable and pcall(helpview.configuration.options.on_enable, window, buffer) then
					helpview.configuration.options.on_enable(window, buffer);
				end
			end
		end

		helpview.state.buf_states[buf] = true;

		local parsed_content = helpview.parser.init(buf);
		local buf_info = helpview.get_buffer_info(buf);

		helpview.renderer.clear(buf);
		helpview.renderer.render(buf, parsed_content, helpview.configuration, buf_info);
	end,
	disable = function (buffer)
		local buf = tonumber(buffer) or vim.api.nvim_get_current_buf();

		if not vim.list_contains(helpview.attached_buffers, buf) or not vim.api.nvim_buf_is_valid(buf) then
			return;
		end

		if helpview.configuration.options and helpview.configuration.options.on_disable then
			local windows = helpview.get_attached_wins(buf);

			-- Set some options
			for _, window in ipairs(windows) do
				if helpview.configuration and helpview.configuration.on_disable and pcall(helpview.configuration.options.on_disable, window, buffer) then
					helpview.configuration.on_disable(window, buffer);
				end
			end
		end

		helpview.state.buf_states[buf] = false;

		helpview.renderer.clear(buf);
	end
};

vim.api.nvim_create_user_command("Helpview", function (opts)
	local fargs = opts.fargs;

	if #fargs < 1 then
		helpview.commands.toggleAll();
	elseif #fargs == 1 and helpview.commands[fargs[1]] then
		helpview.commands[fargs[1]]();
	elseif #fargs == 2 and helpview.commands[fargs[1]] then
		helpview.commands[fargs[1]](fargs[2]);
	end
end, {
	nargs = "*",
	desc = "Controls for Helpview.nvim",

	complete = function (arg_lead, cmdline, _)
		if arg_lead == "" then
			if not cmdline:find("^Helpview%s+%S+") then
				return vim.tbl_keys(helpview.commands);
			elseif cmdline:find("^Helpview%s+(%S+)%s*$") then
				for cmd, _ in cmdline:gmatch("Helpview%s*(%S+)%s*(%S*)") do
					if vim.list_contains({ "toggle", "enable", "disable" }, cmd) then
						local bufs = {};

						for _, buf in ipairs(helpview.attached_buffers) do
							table.insert(bufs, tostring(buf));
						end

						return bufs;
					end
				end
			end
		end

		for cmd, arg in cmdline:gmatch("Helpview%s+(%S+)%s*(%S*)") do
			if arg_lead == cmd then
				local cmds = vim.tbl_keys(helpview.commands);
				local comp = {};

				for _, key in ipairs(cmds) do
					if arg_lead == string.sub(key, 1, #arg_lead) then
						table.insert(comp, key);
					end
				end

				return comp;
			elseif arg_lead == arg then
				local buf_comp = {};

				for _, buffer in ipairs(helpview.attached_buffers) do
					if tostring(buffer):match(arg) then
						table.insert(buf_comp, tostring(buf));
					end
				end

				return buf_comp;
			end
		end
	end
})

vim.api.nvim_create_autocmd({ "colorscheme" }, {
	callback = function ()
		if vim.islist(helpview.configuration.highlight_groups) then
			helpview.add_hls(helpview.configuration.highlight_groups)
		end
	end
});

helpview.get_attached_wins = function (buffer)
	local attached_wins = {};

	for _, window in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(window) == buffer then
			table.insert(attached_wins, window);
		end
	end

	return attached_wins;
end

helpview.setup = function (user_config)
	helpview.configuration = vim.tbl_extend("keep", user_config or {}, helpview.configuration);

	if vim.islist(helpview.configuration.highlight_groups) then
		helpview.add_hls(helpview.configuration.highlight_groups);
	end
end

return helpview;
