local helpview = require("helpview");

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

		if helpview.state.enable == false or helpview.state.buf_states[buffer] == false then
			for _, window in ipairs(windows) do
				if helpview.configuration.options and helpview.configuration.options.on_disable and pcall(helpview.configuration.options.on_disable, window, buffer) then
					helpview.configuration.options.on_disable(window, buffer);
				end
			end

			return;
		else
			for _, window in ipairs(windows) do
				if helpview.configuration.options and helpview.configuration.options.on_enable and pcall(helpview.configuration.options.on_enable, window, buffer) then
					helpview.configuration.options.on_enable(window, buffer);
				end
			end

			helpview.state.buf_states[buffer] = true;
		end

		local parsed_content = helpview.parser.init(buffer);

		-- helpview.column.cache(buffer, parsed_content);
		helpview.renderer.clear(buffer)
		helpview.renderer.render(buffer, parsed_content, helpview.configuration, helpview.get_buffer_info(buffer));
	end
});

vim.api.nvim_create_autocmd({ "ModeChanged", "TextChanged", "WinResized" }, {
	group = help_augroup,
	buffer = vim.api.nvim_get_current_buf(),

	callback = function (event)
		local buffer = event.buf;

		if helpview.state.enable == false or helpview.state.buf_states[buffer] == false then
			return;
		elseif helpview.state.buf_states[buffer] ~= true then
			helpview.state.buf_states[buffer] = true;
		end

		local mode = vim.api.nvim_get_mode().mode;

		local modifiable = vim.bo[buffer].modifiable;
		local lines = vim.api.nvim_buf_line_count(buffer);

		local window_lines = vim.o.lines;

		if event.event ~= "WinResized" and modifiable == false or lines > (helpview.configuration.max_lines or 1000) then
			local cursor = vim.api.nvim_win_get_cursor(0);

			if vim.islist(helpview.configuration.modes) and vim.list_contains(helpview.configuration.modes, mode) then
				helpview.renderer.partial_clear(buffer, cursor[1] - (helpview.configuration.render_lines or window_lines), cursor[1] + (helpview.configuration.render_lines or window_lines));
				helpview.renderer.partial_render(buffer, cursor[1] - (helpview.configuration.render_lines or window_lines), cursor[1] + (helpview.configuration.render_lines or window_lines), helpview.configuration, helpview.get_buffer_info(buffer));
			else
				helpview.renderer.partial_clear(buffer, cursor[1] - (helpview.configuration.render_lines or window_lines), cursor[1] + (helpview.configuration.render_lines or window_lines));
			end
		else
			if vim.islist(helpview.configuration.modes) and vim.list_contains(helpview.configuration.modes, mode) then
				local parsed_content = helpview.parser.init(buffer);

				-- helpview.column.cache(buffer, parsed_content);
				helpview.renderer.clear(buffer)
				helpview.renderer.render(buffer, parsed_content, helpview.configuration, helpview.get_buffer_info(buffer));
			else
				helpview.renderer.clear(buffer)
			end
		end
	end
});
