local gO = {};

gO.origin_win = nil;

gO.__au_winleave = nil;

gO.buffer = vim.api.nvim_create_buf(false, true);
gO.window = nil;
gO.prev_cursor = nil;

gO.keymaps_set = false;

gO.ns = vim.api.nvim_create_namespace("gO_ns");
gO.line_ns = vim.api.nvim_create_namespace("gO_line_ns");

gO.configuraton = {
	title = { "   ", "rainbow4" },
	icons = {
		{ "  ", "rainbow3" },
		{ "  ", "rainbow4" },
		{ "  ", "rainbow4" },
	},

	pad_char = " ",
	repeat_per_level = 2,

	width = 60,
	height = 10,

	border = "rounded",
	border_hl = "FloatBorder",
	current_hl = "DiffText"
}

gO.create_win = function ()
	if gO.window and vim.api.nvim_win_is_valid(gO.window) then
		vim.api.nvim_set_current_win(gO.window);
	end

	gO.window = vim.api.nvim_open_win(gO.buffer, true, {
		relative = "editor",

		row = math.floor((vim.o.lines - gO.configuraton.height) / 2),
		col = math.floor((vim.o.columns - gO.configuraton.width) / 2),

		width = gO.configuraton.width,
		height = gO.configuraton.height,

		border = gO.configuraton.border
	});


	gO.set_options();
end

gO.set_options = function ()
	vim.bo[gO.buffer].filetype = "gO";

	vim.wo[gO.window].spell = false;

	vim.wo[gO.window].number = false;
	vim.wo[gO.window].relativenumber = false;

	vim.wo[gO.window].cursorline = false;
	vim.wo[gO.window].cursorcolumn = false;

	vim.wo[gO.window].scrolloff = math.floor(gO.configuraton.height / 2);
	vim.wo[gO.window].sidescrolloff = math.floor(gO.configuraton.width / 3);

	vim.wo[gO.window].statuscolumn = "";
end

gO.filter_list = function (list)
	local _f = {};

	for _, item in ipairs(list or {}) do
		if item.type == "title" or item.type == "heading" then
			table.insert(_f, item);
		end
	end

	return _f;
end

gO.get_heading_text = function (data, line)
	local _o = "";
	local i_start, i_stop = 0, 0;

	_o = _o .. string.rep(gO.configuraton.pad_char, data.level * gO.configuraton.repeat_per_level);

	local filtered_str = data.text;

	-- Matches: Heading *tag*
	if data.text:match("(%*.*%*)$") then
		filtered_str = data.text:gsub("(%*.*%*)$", "");
		filtered_str = filtered_str:gsub("(%s*)$", "");
	-- Matches: *tag* Heading
	elseif data.text:match("^(%*.*%*)") then
		filtered_str = data.text:gsub("^(%*.*%*)", "");
		filtered_str = filtered_str:gsub("^(%s*)", "");
	end

	i_start = #_o;
	i_stop = i_start + #(gO.configuraton.icons[data.level][1] or "");

	_o = _o .. (gO.configuraton.icons[data.level or 1][1] or "");
	_o = _o .. filtered_str;

	vim.api.nvim_buf_set_lines(gO.buffer, line - 1, line, false, { _o });
	vim.api.nvim_buf_add_highlight(gO.buffer, gO.ns, gO.configuraton.icons[data.level][2], line - 1, i_start, i_stop)
end

gO.get_title_text = function (data, line)
	vim.api.nvim_buf_set_lines(gO.buffer, line - 1, line, false, {
		gO.configuraton.title[1] .. data.title
	});

	vim.api.nvim_buf_add_highlight(gO.buffer, gO.ns, gO.configuraton.title[2], line - 1, 0, #gO.configuraton.title[1]);
	vim.api.nvim_buf_set_extmark(gO.buffer, gO.ns, line - 1, 0, {
		virt_lines = {
			{ { string.rep("╴", gO.configuraton.width), gO.configuraton.border_hl } }
		}
	});
end

gO.create_entries = function (buffer)
	local entries = _G.__helpview_views[buffer] or {};
	local entry_line = 0;

	vim.bo[gO.buffer].modifiable = true;

	vim.api.nvim_buf_clear_namespace(gO.buffer, gO.ns, 0, -1);
	vim.api.nvim_buf_clear_namespace(gO.buffer, gO.line_ns, 0, -1);
	vim.api.nvim_buf_set_lines(gO.buffer, 0, -1, false, {});

	for e, entry in ipairs(gO.filter_list(entries)) do
		if entry.type == "title" then
			gO.get_title_text(entry, e);
		elseif entry.type == "heading" then
			gO.get_heading_text(entry, e);
		end

		if gO.prev_cursor[1] >= entry.row_start then
			entry_line = e;
		end
	end

	vim.bo[gO.buffer].modifiable = false;

	-- Highlight the current heading
	vim.api.nvim_buf_set_extmark(gO.buffer, gO.line_ns, entry_line - 1, 0, {
		line_hl_group = gO.configuraton.current_hl,
		hl_mode = "combine"
	});
	vim.api.nvim_win_set_cursor(gO.window, { entry_line, 0 });
end

gO.create_keymaps = function (buffer)
	if gO.keymaps_set then
		vim.api.nvim_buf_del_keymap(gO.buffer, "n", "<Space>");
		vim.api.nvim_buf_del_keymap(gO.buffer, "n", "<CR>");
		vim.api.nvim_buf_del_keymap(gO.buffer, "n", "q");

		gO.keymaps_set = false;
	end

	vim.api.nvim_buf_set_keymap(gO.buffer, "n", "<Space>", "", {
		desc = "Go to heading without exiting",
		callback = function ()
			local entries = _G.__helpview_views[buffer] or {};

			local current_cursor = vim.api.nvim_win_get_cursor(0);

			for e, data in ipairs(gO.filter_list(entries)) do
				if current_cursor[1] == e then
					vim.api.nvim_win_set_cursor(gO.origin_win, { data.row_start + 1, data.col_start })

					vim.api.nvim_buf_clear_namespace(gO.buffer, gO.line_ns, 0, -1);
					vim.api.nvim_buf_set_extmark(gO.buffer, gO.line_ns, e - 1, 0, {
						line_hl_group = gO.configuraton.current_hl,
						hl_mode = "combine"
					});

					break;
				end
			end
		end
	});
	vim.api.nvim_buf_set_keymap(gO.buffer, "n", "<CR>", "", {
		desc = "Go to heading",
		callback = function ()
			local entries = _G.__helpview_views[buffer] or {};

			local current_cursor = vim.api.nvim_win_get_cursor(0);

			for e, data in ipairs(gO.filter_list(entries)) do
				if current_cursor[1] == e then
					vim.api.nvim_win_set_cursor(gO.origin_win, { data.row_start + 1, data.col_start })

					vim.api.nvim_buf_clear_namespace(gO.buffer, gO.line_ns, 0, -1);
					vim.api.nvim_buf_set_extmark(gO.buffer, gO.line_ns, e - 1, 0, {
						line_hl_group = gO.configuraton.current_hl,
						hl_mode = "combine"
					});

					gO.window = vim.api.nvim_win_close(gO.window, true);
					break;
				end
			end
		end
	});

	vim.api.nvim_buf_set_keymap(gO.buffer, "n", "q", "", {
		desc = "Exit menu",
		callback = function ()
			gO.window = vim.api.nvim_win_close(gO.window, true);
		end
	});

	gO.keymaps_set = true;
end

gO.add_kill_switch = function ()
	gO.__au_winleave = vim.api.nvim_create_autocmd({ "WinLeave" }, {
		callback = function (event)
			if event.buf ~= gO.buffer then
				return;
			end

			gO.window = vim.api.nvim_win_close(gO.window, true);

			if gO.__au_winleave then
				gO.__au_winleave = vim.api.nvim_del_autocmd(gO.__au_winleave);
			end
		end
	})
end

gO.init = function ()
	vim.api.nvim_create_user_command("GO", function ()
		if vim.bo.buftype ~= "help" or vim.bo.filetype ~= "help" then
			vim.print("[ gO ] : Only available on help files.");
			return;
		end

		gO.origin_win = vim.api.nvim_get_current_win();
		gO.prev_cursor = vim.api.nvim_win_get_cursor(0);
		local buffer = vim.api.nvim_get_current_buf();


		gO.add_kill_switch()
		gO.create_win();
		gO.create_entries(buffer);
		gO.create_keymaps(buffer);
	end, {});
end

gO.keymap = function (window, buffer)
	vim.api.nvim_buf_set_keymap(buffer, "n", "gO", "", {
		desc = "Replaces 'gO' keymap in vimdoc files",
		callback = function ()
			vim.cmd("GO")
		end
	});
end

return gO;
