local helpview = require("helpview");
local cursor_pos = {};

local ts_available, treesitter_parsers = pcall(require, "nvim-treesitter.parsers");

local parser_installed = function (parser_name)
	return (ts_available and treesitter_parsers.has_parser(parser_name)) or vim.treesitter.query.get(parser_name, "highlights");
end

if vim.fn.has("nvim-0.10") == 0 then
	warn(" [ Helpview.nvim ] : This plugin is only available for Neovim 0.10 and above! Aborting.");
	return;
elseif not parser_installed("vimdoc") then
	warn(" [ Helpview.nvim ] : Treesitter parser for vimdoc isn't installed! Aborting.");
	return;
end

if vim.islist(helpview.configuration.highlight_groups) then
	helpview.add_hls(helpview.configuration.highlight_groups)
end

if vim.islist(helpview.configuration.buf_ignore) and vim.list_contains(helpview.configuration.buf_ignore, vim.bo.buftype) then
	return
end

local help_augroup = vim.api.nvim_create_augroup("helpview_buf_" .. vim.api.nvim_get_current_buf(), { clear = true });

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	group = help_augroup,
	buffer = vim.api.nvim_get_current_buf(),

	callback = function (event)
		local buffer = event.buf;
		local windows = helpview.get_attached_wins(buffer);

		if not vim.list_contains(helpview.attached_buffers, buffer) then
			table.insert(helpview.attached_buffers, buffer);
		end

		-- On disable
		if helpview.state.enable == false or helpview.state.buf_states[buffer] == false then
			for _, window in ipairs(windows) do
				if helpview.configuration.callbacks and helpview.configuration.options.on_disable and pcall(helpview.configuration.callbacks.on_disable, window, buffer) then
					helpview.configuration.callbacks.on_disable(window, buffer);
				end
			end

			return;
		-- On enable
		else
			for _, window in ipairs(windows) do
				if helpview.configuration.callbacks and helpview.configuration.callbacks.on_enable and pcall(helpview.configuration.callbacks.on_enable, window, buffer) then
					helpview.configuration.callbacks.on_enable(window, buffer);
				end
			end

			helpview.state.buf_states[buffer] = true;
		end

		local cursor = vim.api.nvim_win_get_cursor(0);
		local lines = vim.api.nvim_buf_line_count(event.buf);

		cursor_pos[vim.api.nvim_get_current_win()] = cursor;
		helpview.renderer.clear(event.buf);

		-- Don't render stuff others can't see
		if lines > 1000 then
			local before = math.max(0, cursor[1] - (helpview.configuration.parse_range or 100));
			local after = math.min(vim.api.nvim_buf_line_count(event.buf), cursor[1] + (helpview.configuration.parse_range or 100));

			local parse = helpview.parser.init(event.buf, before, after);

			helpview.renderer.render(event.buf, parse, helpview.configuration, helpview.get_buffer_info(event.buf));
		else
			local parse = helpview.parser.init(event.buf);

			helpview.renderer.render(event.buf, parse, helpview.configuration, helpview.get_buffer_info(event.buf));
		end
	end
});

local cached_mode = nil;
local mode_timer = vim.uv.new_timer();

vim.api.nvim_create_autocmd({ "ModeChanged", "TextChanged" }, {
	group = help_augroup,
	buffer = vim.api.nvim_get_current_buf(),

	callback = function (event)
		local mode = vim.api.nvim_get_mode().mode;
		local buffer = event.buf;

		local mode_debounce = 50;

		mode_timer:stop();

		if cached_mode and cached_mode == mode then
			mode_debounce = 0;
		end

		mode_timer:start(mode_debounce, 0, vim.schedule_wrap(function ()
			if helpview.state.enable == false or helpview.state.buf_states[buffer] == false then
				return;
			end

			mode = vim.api.nvim_get_mode().mode;

			if event.event == "ModeChanged" or mode ~= cached_mode then
				if helpview.configuration.callbacks and helpview.configuration.callbacks.on_mode_change then
					for _, win in ipairs(helpview.get_attached_wins(buffer)) do
						pcall(helpview.configuration.callbacks.on_mode_change, buffer, win, mode);
					end
				end
			end

			cached_mode = mode;

			if not vim.list_contains(helpview.configuration.modes, mode) then
				helpview.renderer.clear(buffer);
				vim.cmd("redraw!");
				return;
			end

			local cursor = vim.api.nvim_win_get_cursor(0);
			local lines = vim.api.nvim_buf_line_count(buffer);

			if lines > 1000 then
				local before = math.max(0, cursor[1] - (helpview.configuration.parse_range or 100));
				local after = math.min(lines, cursor[1] + (helpview.configuration.parse_range or 100));

				local parse = helpview.parser.init(buffer, before, after);

				helpview.renderer.clear(buffer);
				helpview.renderer.render(buffer, parse, helpview.configuration, helpview.get_buffer_info(event.buf));
			else
				local parse = helpview.parser.init(buffer);

				helpview.renderer.clear(buffer);
				helpview.renderer.render(buffer, parse, helpview.configuration, helpview.get_buffer_info(event.buf));
			end

			if not helpview.configuration.hybrid_modes or not vim.list_contains(helpview.configuration.hybrid_modes, mode) then
				return;
			end
		end));
	end
});

local events = {};

if vim.list_contains(helpview.configuration.modes, "n") or
	vim.list_contains(helpview.configuration.modes, "v")
then
	table.insert(events, "CursorMoved");
end

if vim.list_contains(helpview.configuration.modes, "i") then
	table.insert(events, "CursorMovedI");
end

local timer = vim.uv.new_timer();

vim.api.nvim_create_autocmd(events, {
	group = help_augroup,
	buffer = vim.api.nvim_get_current_buf(),

	callback = function (event)
		timer:stop();

		local cursor = vim.api.nvim_win_get_cursor(0);
		local mode = vim.api.nvim_get_mode().mode;
		local buffer = event.buf;

		if helpview.state.enable == false or helpview.state.buf_states[buffer] == false then
			return;
		end

		if not vim.list_contains(helpview.configuration.modes, mode) then
			return;
		end

		local debounce_delay = helpview.configuration.dsbounce_delay or 100;

		--- Immediately draw if the distance is too big
		if cursor_pos[vim.api.nvim_get_current_win()] and math.abs(cursor_pos[vim.api.nvim_get_current_win()][1] - cursor[1]) > vim.o.lines then
			debounce_delay = 0;
		end

		cursor_pos[vim.api.nvim_get_current_win()] = cursor;

		timer:start(debounce_delay, 0, vim.schedule_wrap(function ()
			cursor = vim.api.nvim_win_get_cursor(0);
			local lines = vim.api.nvim_buf_line_count(buffer);

			if lines > 1000 then
				local before = math.max(0, cursor[1] - (helpview.configuration.parse_range or 100));
				local after = math.min(vim.api.nvim_buf_line_count(buffer), cursor[1] + (helpview.configuration.parse_range or 100));

				local parse = helpview.parser.init(buffer, before, after);

				helpview.renderer.clear(buffer);
				helpview.renderer.render(buffer, parse, helpview.configuration, helpview.get_buffer_info(buffer));
			else
				local parse = helpview.parser.init(buffer);

				helpview.renderer.clear(buffer);
				helpview.renderer.render(buffer, parse, helpview.configuration, helpview.get_buffer_info(buffer));
			end

			if not helpview.configuration.hybrid_modes or not vim.list_contains(helpview.configuration.hybrid_modes, mode) then
				return;
			end

			local under_cursor = helpview.parser.init(buffer, math.max(cursor[1] - 1, 0), cursor[1]);
			local cl_start, cl_stop = helpview.renderer.get_content_range(under_cursor);

			if not cl_start or not cl_stop then
				return;
			end

			helpview.renderer.clear(buffer, cl_start, cl_stop);
		end));
	end
});

