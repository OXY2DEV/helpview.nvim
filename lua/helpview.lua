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

		if type(opt) == "table" then
			vim.api.nvim_set_hl(0, hl.raw and hl.group_name or "Helpview" .. hl.group_name, opt);
		end

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
	hybrid_modes = nil,
	-- buf_ignore = { "help" },

	callbacks = {
		on_enable = nil,
		on_disable = nil,

		on_mode_change = nil
	},

	---+ ##code##
	highlight_groups = {
		{
			group_name = "Title",
			value = function ()
				if helpview.colors.get_hl_value(0, "DiagnosticVirtualTextWarn", "bg") and
					helpview.colors.get_hl_value(0, "DiagnosticVirtualTextWarn", "fg")
				then
					local bg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextWarn", "bg");
					local fg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextWarn", "fg");

					return { bg = bg, fg = fg, default = true };
				else
					local bg = helpview.colors.bg() or "#1e1e2e";
					local fg = helpview.colors.get({
						helpview.colors.get_hl_value(0, "DiagnosticWarn", "fg"),
						vim.o.background == "dark" and "#f9e2af" or "#df8e18"
					});

					return {
						bg = vim.o.background == "dark" and
							helpview.colors.mix(bg, fg, 0.5, 0.15) or
							helpview.colors.mix(bg, fg, 0.85, 0.20),
						fg = fg,

						default = true
					}
				end
			end
		},
		{
			group_name = "Heading1",
			value = function ()
				if helpview.colors.get_hl_value(0, "DiagnosticVirtualTextOk", "bg") and
					helpview.colors.get_hl_value(0, "DiagnosticVirtualTextOk", "fg")
				then
					local bg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextOk", "bg");
					local fg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextOk", "fg");

					return { bg = bg, fg = fg, default = true };
				else
					local bg = helpview.colors.bg() or "#1e1e2e";
					local fg = helpview.colors.get({
						helpview.colors.get_hl_value(0, "DiagnosticOk", "fg"),
						vim.o.background == "dark" and "#a6e3a1" or "#40a02b"
					});

					return {
						bg = vim.o.background == "dark" and
							helpview.colors.mix(bg, fg, 0.5, 0.15) or
							helpview.colors.mix(bg, fg, 0.85, 0.20),
						fg = fg,

						default = true
					}
				end
			end
		},
		{
			group_name = "Heading2",
			value = function ()
				if helpview.colors.get_hl_value(0, "DiagnosticVirtualTextHint", "bg") and
					helpview.colors.get_hl_value(0, "DiagnosticVirtualTextHint", "fg")
				then
					local bg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextHint", "bg");
					local fg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextHint", "fg");

					return { bg = bg, fg = fg, default = true };
				else
					local bg = helpview.colors.bg() or "#1e1e2e";
					local fg = helpview.colors.get({
						helpview.colors.get_hl_value(0, "DiagnosticHint", "fg"),
						vim.o.background == "dark" and "#94e2d5" or "#179299"
					});

					return {
						bg = vim.o.background == "dark" and
							helpview.colors.mix(bg, fg, 0.5, 0.15) or
							helpview.colors.mix(bg, fg, 0.85, 0.20),
						fg = fg,

						default = true
					}
				end
			end
		},
		{
			group_name = "Heading3",
			value = function ()
				if helpview.colors.get_hl_value(0, "DiagnosticVirtualTextInfo", "bg") and
					helpview.colors.get_hl_value(0, "DiagnosticVirtualTextInfo", "fg")
				then
					local bg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextInfo", "bg");
					local fg = helpview.colors.get_hl_value(0, "DiagnosticVirtualTextInfo", "fg");

					return { bg = bg, fg = fg, default = true };
				else
					local bg = helpview.colors.bg() or "#1e1e2e";
					local fg = helpview.colors.get({
						helpview.colors.get_hl_value(0, "DiagnosticInfo", "fg"),
						vim.o.background == "dark" and "#89dceb" or "#179299"
					});

					return {
						bg = vim.o.background == "dark" and
							helpview.colors.mix(bg, fg, 0.5, 0.15) or
							helpview.colors.mix(bg, fg, 0.85, 0.20),
						fg = fg,

						default = true
					}
				end
			end
		},
		{
			group_name = "Heading4",
			value = function ()
				if helpview.colors.get_hl_value(0, "Special", "bg") and
					helpview.colors.get_hl_value(0, "Special", "fg")
				then
					local bg = helpview.colors.get_hl_value(0, "Special", "bg");
					local fg = helpview.colors.get_hl_value(0, "Special", "fg");

					return { bg = bg, fg = fg, default = true };
				else
					local bg = helpview.colors.bg() or "#1e1e2e";
					local fg = helpview.colors.get({
						helpview.colors.get_hl_value(0, "Special", "fg"),
						vim.o.background == "dark" and "#f5c2e7" or "#ea76cb"
					});

					return {
						bg = vim.o.background == "dark" and
							helpview.colors.mix(bg, fg, 0.5, 0.15) or
							helpview.colors.mix(bg, fg, 0.85, 0.20),
						fg = fg,

						default = true
					}
				end
			end
		},

		{
			output = function ()
				local bg = helpview.colors.bg();
				local fg = helpview.colors.get_hl_value(0, "Comment", "fg");

				local luminosity = helpview.colors.get_brightness(bg);

				if luminosity < 0.5 then
					return {
						{
							group_name = "Code",
							value = { bg = helpview.colors.mix(bg, bg, 1, math.max(luminosity, 0.25)) }
						},
						{
							group_name = "CodeLanguage",
							value = {
								bg = helpview.colors.mix(bg, bg, 1, math.max(luminosity, 0.25)),
								fg = fg
							}
						}
					};
				else
					return {
						{
							group_name = "Code",
							value = { bg = helpview.colors.mix(bg, bg, 1, math.min(1 - luminosity, 0.05) * -1) }
						},
						{
							group_name = "CodeLanguage",
							value = {
								bg = helpview.colors.mix(bg, bg, 1, math.min(1 - luminosity, 0.05) * -1),
								fg = fg
							}
						}
					};
				end
			end
		},
		{
			group_name = "InlineCode",
			value = function ()
				local bg = helpview.colors.bg();
				local fg = helpview.colors.get_hl_value(0, "@markup.raw.vimdoc", "fg");

				local luminosity = helpview.colors.get_brightness(bg);

				if luminosity < 0.5 then
					return {
						bg = helpview.colors.mix(bg, bg, 1, math.max(luminosity, 0.5)),
						fg = fg
					};
				else
					return {
						bg = helpview.colors.mix(bg, bg, 1, math.min(luminosity, 0.15) * -1),
						fg = fg
					};
				end
			end
		},
		{
			output = function ()
				local bg = helpview.colors.get_hl_value(0, "Normal", "bg");
				local tag_fg = helpview.colors.get_hl_value(0, "Title", "fg");
				local taglink_fg = helpview.colors.get_hl_value(0, "Title", "fg");
				local option_fg = helpview.colors.get_hl_value(0, "Tag", "fg");

				if vim.o.background == "dark" then
					return {
						{
							group_name = "Taglink",
							value = {
								bg = helpview.colors.mix(tag_fg, bg, 0.25, 0.15),
								fg = tag_fg
							}
						},
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
								fg = taglink_fg,
								underline = true
							}
						},
					}
				else
					return {
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
								fg = taglink_fg,
								underline = true
							}
						},
					}
				end
			end
		},
		{
			output = function ()
				local from = helpview.colors.get_hl_value(0, "Normal", "bg") or "#1e1e2e";
				local to = helpview.colors.get_hl_value(0, "@character", "fg") or helpview.colors.get_hl_value(0, "@comment.note", "fg");

				return helpview.colors.create_gradient("Gradient", from, to, 10, "fg")
			end
		}
	},
	---_

	arguments = {
		icon = "󰂓 ",
		hl = "@variable.parameter.vimdoc",

		conceal_before = 1, conceal_after = 1
	},

	code_blocks = {
		hl = "HelpviewCode",
		language_hl = "HelpviewCodeLanguage"
	},

	group_names = {
		enable = true,

		icon = "󰏘 ",
	},

	headings = {
		heading_1 = {
			style = "simple",
			hl = "Heading1",
			marker = "═",

			sign = " "
		},
		heading_2 = {
			style = "simple",
			hl = "Heading2",
			marker = "─",

			sign = " "
		},
		heading_3 = {
			style = "simple",
			hl = "Heading3",

			sign = " "
		},
		heading_4 = {
			style = "simple",
			hl = "Heading4",

			sign = "󰓫 "
		},
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
	},

	inline_codes = {
		padding_left = " ",
		padding_right = " ",

		hl = "HelpviewInlineCode"
	},

	keycodes = {
		icon = "󰌌 ",
		hl = "Special",

		conceal_before = function (data)
			if data.extracted then
				return 1;
			else
				return 0;
			end
		end,
		conceal_after = function (data)
			if data.extracted then
				return 1;
			else
				return 0;
			end
		end,
	},

	mention_links = {
		icon = " ",
		hl = "HelpviewMentionlink"
	},

	modelines = {
		style = "expanded",

		icon_hl = "DiagnosticOk",
		selector_hl = "@property.class.css",
		surround_hl = "@punctuation.bracket",

		option_hl = "@property.css",
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

	option_links = {
		padding_left = " ",
		padding_right = " ",

		icon = " ",
		hl = "HelpviewOptionLink",

		conceal_before = 1, conceal_after = 1
	},

	tag_links = {
		padding_left = " ",
		padding_right = " ",

		hl = "HelpviewTaglink"
	},

	title = {
		style = "simple",
		hl = "HelpviewTitle",
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

-- vim.api.nvim_create_user_command("H", function (data)
-- 	vim.print("h");
-- end, {
-- 	desc = "Why?"
-- })

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
