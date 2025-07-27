--- Decorations for Vim help files.
local helpview = {};

local health = require("helpview.health");
local spec = require("helpview.spec");

---@type helpview.state
helpview.state = {
	enable = true,
	attached_buffers = {},

	buffer_states = {},

	splitview_source = nil,
	splitview_buffer = nil,
	splitview_window = nil
}

--- A stricter version of the default
--- renderer.
helpview.strict_render = {
	--- Buffers that have been rendered.
	---@type integer[]
	on = {},

	--- Renders to `buffer`.
	--- Disables rendering when the line count
	--- is >= `max_lines`
	---@param self table
	---@param buffer integer
	---@param max_lines integer
	render = function (self, buffer, max_lines)
		buffer = buffer or vim.api.nvim_get_current_buf();
		max_lines = max_lines or spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });

		if vim.list_contains(self.on, buffer) then
			return;
		elseif vim.api.nvim_buf_line_count(buffer) >= max_lines then
			return;
		end

		local parser = require("helpview.parser");
		local renderer = require("helpview.renderer");

		helpview.clear(buffer);
		local content = parser.parse(buffer, 0, -1);

		helpview.actions.__exec_callback("on_attach", buffer, vim.fn.win_findbuf(buffer));
		helpview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer));

		renderer.render(buffer, content);
		table.insert(self.on, buffer)
	end,

	--- Clears the preview of `buffer`.
	--- Also frees it yp to be rendered again.
	---@param self table
	---@param buffer integer
	clear = function (self, buffer)
		if vim.list_contains(self.on, buffer) == false then
			return;
		end

		helpview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer));
		helpview.actions.__exec_callback("on_detach", buffer, vim.fn.win_findbuf(buffer));

		for b, buf in ipairs(self.on) do
			if buf == buffer then
				table.remove(self.on, b);
				return;
			end
		end
	end
};

--- Cleans up any invalid buffers.
helpview.clean = function ()
	--- Should a buffer be cleaned?
	---@param buffer integer?
	---@return boolean
	local function should_clean (buffer)
		if type(buffer) ~= "number" then
			return true;
		elseif vim.api.nvim_buf_is_valid(buffer) == false then
			return true;
		elseif vim.api.nvim_buf_is_loaded(buffer) == false then
			return true;
		end

		return false;
	end

	for b, buf in ipairs(helpview.state.attached_buffers) do
		if should_clean(buf) == true then
			table.remove(helpview.state.attached_buffers, b);
			helpview.state.buffer_states[buf] = nil;

			if helpview.state.splitview_source == buf then
				vim.print('XClose splitview');
			end
		end
	end
end

--- Checks if `buffer` is safe.
---@param buffer? integer
---@return boolean
helpview.buf_is_safe = function (buffer)
	if type(buffer) ~= "number" then
		return false;
	elseif vim.api.nvim_buf_is_valid(buffer) == false then
		return false;
	elseif vim.v.exiting ~= vim.NIL then
		return false;
	end

	return true;
end

--- Checks if `window` is safe.
---@param window? integer
---@return boolean
helpview.win_is_safe = function (window)
	if type(window) ~= "number" then
		return false;
	elseif vim.api.nvim_win_is_valid(window) == false then
		return false;
	elseif vim.api.nvim_win_get_tabpage(window) ~= vim.api.nvim_get_current_tabpage() then
		return false;
	end

	return true;
end

--- Can we attach to `buffer`?
---@param buffer? integer
---@return boolean
helpview.can_attach = function (buffer)
	helpview.clean();

	if helpview.buf_is_safe(buffer) == false then
		return false;
	elseif vim.list_contains(helpview.state.attached_buffers, buffer) then
		return false;
	end

	return true;
end

--- Can we draw on `buffer`?
---@param buffer integer
---@return boolean
helpview.can_draw = function (buffer)
	helpview.clean();

	if helpview.buf_is_safe(buffer) == false then
		return false;
	elseif helpview.actions.__is_enabled(buffer) == false then
		return false;
	end

	return true;
end

--- Clears all previews from `buffer`.
---@param buffer integer
helpview.clear = function (buffer)
	buffer = buffer or vim.api.nvim_get_current_buf();
	require("helpview.renderer").clear(buffer, 0, -1);
end

--- Renders preview to `buffer`.
---@param buffer integer
---@param state? { enable: boolean, hybrid_mode: boolean }
helpview.render = function (buffer, state)
	---@type integer
	buffer = buffer or vim.api.nvim_get_current_buf();

	local parser = require("helpview.parser");
	local renderer = require("helpview.renderer");

	---@type integer Number of lines a buffer can have to be fully rendered.
	local line_limit = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });
	---@type [ integer, integer ] Number of lines to draw on large buffers.
	local draw_range = spec.get({ "preview", "draw_range" }, { fallback = { vim.o.lines, vim.o.lines }, ignore_enable = true });
	---@type [ integer, integer ] Number of lines to be considered being edited.
	local edit_range = spec.get({ "preview", "edit_range" }, { fallback = { 0, 0 }, ignore_enable = true });

	---@type integer Buffer's line count.
	local line_count = vim.api.nvim_buf_line_count(buffer);

	---@type string[] List of modes where to use hybrid_mode.
	local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });
	---@type boolean Is line-wise hybrid mode enabled?
	local linewise_hybrid_mode = spec.get({ "preview", "linewise_hybrid_mode" }, { fallback = false, ignore_enable = true })

	---@type string Current mode shorthand.
	local mode = vim.api.nvim_get_mode().mode;

	state = state or helpview.state.buffer_states[buffer];

	local function hybrid_mode()
		if type(state) == "table" and state.hybrid_mode == false then
			return false;
		else
			return vim.list_contains(hybrid_modes, mode);
		end
	end

	helpview.clear(buffer);

	if line_count <= line_limit then
		local content, _ = parser.parse(buffer, 0, -1);

		if hybrid_mode() == true and linewise_hybrid_mode == false then
			for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
				---@type [ integer, integer ] Cursor position.
				local cursor = vim.api.nvim_win_get_cursor(win);
				--- 1-index → 0-index
				cursor[1] = cursor[1] - 1;

				content = renderer.filter(content, nil, {
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + edit_range[2], line_count)
				});
			end

			renderer.render(buffer, content);
		elseif hybrid_mode() == true then
			renderer.render(buffer, content);

			for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
				---@type [ integer, integer ] Cursor position.
				local cursor = vim.api.nvim_win_get_cursor(win);
				--- 1-index → 0-index
				cursor[1] = cursor[1] - 1;

				renderer.clear(buffer,
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + 1 + edit_range[2], line_count)
				);
			end
		else
			renderer.render(buffer, content);
		end
	else
		for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
			---@type [ integer, integer ] Cursor position.
			local cursor = vim.api.nvim_win_get_cursor(win);
			--- 1-index → 0-index
			cursor[1] = cursor[1] - 1;

			local content, _ = parser.parse(buffer, math.max(0, cursor[1] - draw_range[1]), math.min(line_count, cursor[1] + draw_range[2]));

			if hybrid_mode() == true and linewise_hybrid_mode == false then
				content = renderer.filter(content, nil, {
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + edit_range[2], line_count)
				});

				renderer.render(buffer, content);
			elseif hybrid_mode() == true then
				renderer.render(buffer, content);

				renderer.clear(buffer,
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + 1 + edit_range[2], line_count)
				);
			else
				renderer.clear(buffer, renderer.get_range(content));
				renderer.render(buffer, content);
			end
		end
	end

	-- TODO: Is this really needed?
	helpview.actions.__exec_callback("__post_render", buffer, vim.fn.win_findbuf(buffer));
end

--- Updates cursor position in splitview.
helpview.update_splitview_cursor = function ()
	local utils = require("helpview.utils");
	local buffer = helpview.state.splitview_source;

	if helpview.buf_is_safe(buffer) == false then
		--- Buffer isn't safe.
		-- helpview.state.splitview_source = nil;
		pcall(helpview.actions.splitClose);
		return;
	elseif helpview.win_is_safe(utils.buf_getwin(buffer)) == false then
		--- Buffer doesn't have any windows attached.
		pcall(helpview.actions.splitClose);
		return;
	end

	--- In case the preview buffer/window got
	--- deleted, we should regenerate them.
	helpview.actions.__splitview_setup();

	local pre_win = helpview.state.splitview_window;

	local cursor = vim.api.nvim_win_get_cursor(utils.buf_getwin(buffer));
	pcall(vim.api.nvim_win_set_cursor, pre_win, cursor);
end

--- Renders splitview.
helpview.splitview_render = function ()
	local utils = require("helpview.utils");
	local buffer = helpview.state.splitview_source;

	if helpview.buf_is_safe(buffer) == false then
		--- Buffer isn't safe.
		-- helpview.state.splitview_source = nil;
		pcall(helpview.actions.splitClose);
		return;
	elseif helpview.win_is_safe(utils.buf_getwin(buffer)) == false then
		--- Buffer doesn't have any windows attached.
		pcall(helpview.actions.splitClose);
		return;
	end

	--- In case the preview buffer/window got
	--- deleted, we should regenerate them.
	helpview.actions.__splitview_setup();

	---@type integer
	local max_lines = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });
	---@type integer
	local line_count = vim.api.nvim_buf_line_count(buffer);

	---@type integer
	local main_win = utils.buf_getwin(buffer);
	---@type [ integer, integer ]
	local cursor = vim.api.nvim_win_get_cursor(main_win);

	---@type integer
	local pre_buf = helpview.state.splitview_buffer;
	---@type integer
	local pre_win = helpview.state.splitview_window;

	local lines = vim.api.nvim_buf_get_lines(
		buffer,
		math.max(0, cursor[1] - (max_lines + 1)),
		math.min(line_count, cursor[1] + (max_lines + 1)),
		false
	);
	vim.api.nvim_buf_set_lines(
		pre_buf,
		math.max(0, cursor[1] - (max_lines + 1)),
		math.min(line_count, cursor[1] + (max_lines + 1)),
		false,
		lines
	);

	pcall(vim.api.nvim_win_set_cursor, pre_win, cursor);

	helpview.render(pre_buf, {
		enable = true,
		hybrid_mode = false
	});
end

--- Actions for helpview.
---@type table<string, function>
helpview.actions = {
	["__exec_callback"] = function (callback, ...)
		if vim.list_contains({ "string", "integer" }, type(callback)) == false then
			return;
		end

		---@type function
		local _f = spec.get({ "preview", "callbacks", callback }, { ignore_enable = true });
		pcall(_f, ...);

		health.notify("trace", {
			level = 1,
			message = {
				{ "Callback: ", "Special" },
				{ " " .. callback .. " ", "DiagnosticVirtualTextInfo" }
			}
		});
	end,

	["__is_attached"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();
		return vim.list_contains(helpview.state.attached_buffers, buffer);
	end,
	["__is_enabled"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.actions.__is_attached(buffer) == false then
			return false;
		else
			return helpview.state.buffer_states[buffer].enable;
		end
	end,

	["__splitview_setup"] = function ()
		if helpview.buf_is_safe(helpview.state.splitview_source) == false then
			return;
		end

		local utils = require("helpview.utils");
		local win = utils.buf_getwin(helpview.state.splitview_source);

		if helpview.win_is_safe(win) == false then
			helpview.actions.splitClose();
			return;
		end

		if helpview.buf_is_safe(helpview.state.splitview_buffer) == false then
			pcall(vim.api.nvim_buf_delete, helpview.state.splitview_buffer, { force = true });
			helpview.state.splitview_buffer = vim.api.nvim_create_buf(false, true);
		end

		vim.bo[helpview.state.splitview_buffer].ft = vim.bo[helpview.state.splitview_source].ft;

		if helpview.win_is_safe(helpview.state.splitview_window) == false then
			pcall(vim.api.nvim_win_close, helpview.state.splitview_window, true);
			helpview.state.splitview_window = vim.api.nvim_open_win(
				helpview.state.splitview_buffer,
				false,
				spec.get({ "preview", "splitview_winopts", }, {
					fallback = { split = "right" },
					ignore_enable = true
				})
			);
		end

		vim.wo[helpview.state.splitview_window].wrap = vim.wo[win].wrap;
		vim.wo[helpview.state.splitview_window].linebreak = vim.wo[win].linebreak;
	end,

	["traceExport"] = function ()
		local scrolloff = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff;
		local buf_width = vim.o.columns - scrolloff;

		local version = vim.version();
		local colorscheme = vim.g.colors_name or "";

		local time_col = math.max(20, math.floor((buf_width - 7) * 0.2));
		local desc_col = buf_width - (time_col + 3);

		local function center (text, width)
			if vim.fn.strdisplaywidth(text) > width then
				return vim.fn.strcharpart(text, width);
			else
				local pad_amount = width - vim.fn.strdisplaywidth(text);
				return string.rep(" ", math.ceil(pad_amount / 2)) .. text .. string.rep(" ", math.floor(pad_amount / 2));
			end
		end

		local lines = {
			"Plugin: helpview.nvim",
			"Time: " .. os.date(),
			string.format("Nvim version: %d.%d.%d", version.major, version.minor, version.patch),
			"Colorscheme: " .. colorscheme,
			"",
			"Level description,",
			"  1 = START",
			"  2 = PAUSE",
			"  3 = STOP",
			"  4 = ERROR",
			"  5 = LOG",
			"  6 = ENABLE",
			"  7 = DISABLE",
			"  8 = ATTACH",
			"  9 = DETACH",
			"",
			"Trace,",
			string.rep("-", time_col) .. "•-------•" .. string.rep("-", desc_col),
			center("Time-stamp", time_col) .. "|" .. " Level " .. "|" .. center("Action", desc_col),
			string.rep("-", time_col) .. "•-------•" .. string.rep("-", desc_col)
		};

		for _, entry in ipairs(health.log) do
			if entry.kind ~= "trace" then
				goto continue;
			end

			---@cast entry logs.trace

			table.insert(lines, string.format(
				"%s|%s| %s",
				center(
					string.format("%-12s", string.rep("  ", entry.indent) .. entry.timestamp),
					time_col
				),
				center(tostring(entry.level or 0), 7),
				entry.message
			));

		    ::continue::
		end

		table.insert(lines, string.rep("-", time_col) .. "•-------•" .. string.rep("-", desc_col))
		table.insert(lines, "");
		table.insert(lines, "vim:nomodifiable:nowrap:nospell:");

		local trace_file = io.open("trace.txt", "w");

		if not trace_file then
			return;
		end

		trace_file:write(table.concat(lines, "\n"));
		trace_file:close();
	end,
	["traceShow"] = function (from, to)
		health.trace_open(from, to);
	end,


	--- Attaches previewer to a `buffer`.
	---
	--- Optionally allows setting a `state` for
	--- that buffer.
	---@param buffer integer?
	---@param state? { enable: boolean, hybrid_mode: boolean, y: integer }
	["attach"] = function (buffer, state)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.can_attach(buffer) == false then
			return;
		end

		health.notify("trace", {
			level = 8,
			message = string.format("Attached: %d", buffer)
		});
		health.__child_indent_in();

		local enable = spec.get({ "preview", "enable" }, { fallback = true, ignore_enable = true });
		local hm_enable = spec.get({ "preview", "enable_hybrid_mode" }, { fallback = true, ignore_enable = true });

		table.insert(helpview.state.attached_buffers, buffer);
		helpview.state.buffer_states[buffer] = state or {
			enable = enable,
			hybrid_mode = hm_enable,

			y = 0
		};

		helpview.actions.__exec_callback("on_attach", buffer, vim.fn.win_findbuf(buffer));

		if enable == true then
			helpview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer));

			if hm_enable == true then
				helpview.actions.__exec_callback("on_hybrid_enable", buffer, vim.fn.win_findbuf(buffer));
			else
				helpview.actions.__exec_callback("on_hybrid_disable", buffer, vim.fn.win_findbuf(buffer));
			end

			helpview.render(buffer);
		else
			helpview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer));
			helpview.clear(buffer);
		end

		health.__child_indent_de();
	end,

	--- Detaches previewer from a `buffer`.
	---@param buffer integer?
	["detach"] = function (buffer)
		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.buf_is_safe(buffer) == false then
			--- Something went wrong.
			return;
		elseif helpview.can_attach(buffer) == true then
			--- This buffer hasn't been attached to.
			return;
		end

		health.notify("trace", {
			level = 9,
			message = string.format("Detached: %d", buffer)
		});
		health.__child_indent_in();

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_detach", buffer, vim.fn.win_findbuf(buffer))

		--- Remove the entry.
		--- DON'T REMOVE THE STATES THOUGH!
		--- (We may need them in the future)
		for i, buf in ipairs(helpview.state.attached_buffers) do
			if buf == buffer then
				table.remove(helpview.state.attached_buffers, i);
			end
		end

		--- Clear decorations too!
		helpview.clear(buffer);
		health.__child_indent_de()
	end,

	--- Disables preview of `buffer`.
	---@param buffer integer?
	["disable"] = function (buffer)
		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.actions.__is_attached(buffer) == false then
			return;
		elseif type(helpview.state.buffer_states[buffer]) ~= "table" then
			helpview.state.buffer_states[buffer] = nil;
			return;
		elseif buffer == helpview.state.splitview_source then
			helpview.state.buffer_states[buffer].enable = false;
			helpview.state.buffer_states[buffer].y = -999;

			return;
		end

		health.notify("trace", {
			level = 7,
			message = string.format("Disabled: %d", buffer)
		});
		health.__child_indent_in();

		helpview.state.buffer_states[buffer].enable = false;
		helpview.clear(buffer);

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer))

		local mode = vim.api.nvim_get_mode().mode;
		---@type string[]
		local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

		if vim.list_contains(hybd_modes, mode) == false then
			health.__child_indent_de();
			return;
		end

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_hybrid_disable", buffer, vim.fn.win_findbuf(buffer))
		health.__child_indent_de();
	end,

	--- Enables preview of `buffer`.
	---@param buffer integer?
	["enable"] = function (buffer)
		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.actions.__is_attached(buffer) == false then
			return;
		elseif type(helpview.state.buffer_states[buffer]) ~= "table" then
			helpview.state.buffer_states[buffer] = nil;
			return;
		elseif buffer == helpview.state.splitview_source then
			helpview.state.buffer_states[buffer].enable = true;
			helpview.splitview_render();
			return;
		end

		health.notify("trace", {
			level = 6,
			message = string.format("Enabled: %d", buffer)
		});
		health.__child_indent_in();

		helpview.state.buffer_states[buffer].enable = true;

		local mode = vim.api.nvim_get_mode().mode;
		---@type string[]
		local prev_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
		---@type string[]
		local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

		if vim.list_contains(prev_modes, mode) == false then
			health.__child_indent_de();
			return;
		end

		helpview.render(buffer);

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer))

		if vim.list_contains(hybd_modes, mode) == false then
			health.__child_indent_de();
			return;
		end

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_hybrid_enable", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		health.__child_indent_de();
	end,

	--- Enables hybrid mode of `buffer`.
	---@param buffer integer?
	["hybridEnable"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.actions.__is_attached(buffer) == false then
			return;
		elseif helpview.state.buffer_states[buffer] then
			helpview.state.buffer_states[buffer].hybrid_mode = true;

			if helpview.state.buffer_states[buffer].enable == false then
				return;
			elseif buffer == helpview.state.splitview_source then
				return;
			end

			helpview.render(buffer);

			local mode = vim.api.nvim_get_mode().mode;
			---@type string[]
			local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

			if vim.list_contains(hybd_modes, mode) == false then
				return;
			end

			--- Execute the attaching autocmd.
			helpview.actions.__exec_callback("on_hybrid_enable", buffer, vim.fn.win_findbuf(buffer))
		end
	end,

	--- Disables hybrid mode of `buffer`.
	---@param buffer integer?
	["hybridDisable"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.actions.__is_attached(buffer) == false then
			return;
		elseif helpview.state.buffer_states[buffer] then
			helpview.state.buffer_states[buffer].hybrid_mode = false;

			if helpview.state.buffer_states[buffer].enable == false then
				return;
			elseif buffer == helpview.state.splitview_source then
				return;
			end

			helpview.render(buffer);

			local mode = vim.api.nvim_get_mode().mode;
			---@type string[]
			local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

			if vim.list_contains(hybd_modes, mode) == false then
				return;
			end

			--- Execute the attaching autocmd.
			helpview.actions.__exec_callback("on_hybrid_disable", buffer, vim.fn.win_findbuf(buffer))
		end
	end,

	--- Opens split view for `buffer`.
	---@param buffer integer?
	["splitOpen"] = function (buffer)
		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.buf_is_safe(buffer) == false then
			return;
		end

		helpview.actions.splitClose();

		if helpview.actions.__is_enabled(buffer) == true then
			helpview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer));
		end

		helpview.state.splitview_source = buffer;
		helpview.actions.__splitview_setup();
		helpview.clear(buffer);

		helpview.actions.__exec_callback("on_splitview_open", buffer, helpview.state.splitview_buffer, helpview.state.splitview_window);

		helpview.splitview_render();
	end,

	--- Closes split view.
	["splitClose"] = function ()
		if type(helpview.state.splitview_source) ~= "number" then
			--- Splitview's source buffer isn't a number. Why?
			--- Assuming it's `nil`, we should stop here.
			return;
		end

		--- FEAT, Allow `on_splitview_close` to take arguments
		--- regarding splitview.
		helpview.actions.__exec_callback("on_splitview_close", buffer, helpview.state.splitview_buffer, helpview.state.splitview_window);

		--- Attempt to close the window.
		--- Also remove the reference to that window.
		pcall(vim.api.nvim_win_close, helpview.state.splitview_window, true);

		--- We should also clean up the preview buffer(if possible).
		if helpview.buf_is_safe(helpview.state.splitview_buffer) == true then
			helpview.clear(helpview.state.splitview_buffer);
			vim.api.nvim_buf_set_lines(helpview.state.splitview_buffer, 0, -1, false, {});
		end

		---@type integer
		local buffer = helpview.state.splitview_source;

		helpview.state.splitview_window = nil;
		helpview.state.splitview_source = nil;

		if helpview.buf_is_safe(buffer) == false then
			--- Source buffer isn't safe for `helpview` to work.
			return;
		elseif type(helpview.state.buffer_states[buffer]) ~= "table" then
			--- We never attached to the source buffer.
			return;
		end

		helpview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer));

		--- Don't forget to render the preview if possible.
		if helpview.state.buffer_states[buffer].enable == true then
			helpview.render(buffer);
		end
	end
};

--- Holds various functions that you can run
--- via `:Helpview ...`.
---@type { [string]: function }
helpview.commands = {
	["traceExport"] = function ()
		helpview.actions.traceExport();
	end,
	["traceShow"] = function (from, to)
		if pcall(tonumber, from) and pcall(tonumber, to) then
			health.trace_open(tonumber(from), tonumber(to));
		else
			health.trace_open();
		end
	end,

	["attach"] = function (buffer)
		helpview.actions.attach(buffer);
	end,
	["detach"] = function (buffer)
		helpview.actions.detach(buffer);
	end,

	["Toggle"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			helpview.commands.toggle(buf);
		end
	end,
	["Enable"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			helpview.actions.enable(buf);
		end
	end,
	["Disable"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			helpview.actions.disable(buf);
		end
	end,

	["Render"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			if helpview.actions.__is_enabled(buf) then
				helpview.render(buf);
			end
		end
	end,
	["Clear"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			if helpview.actions.__is_enabled(buf) then
				helpview.clear(buf);
			end
		end
	end,

	["render"] = function (buffer)
		helpview.clean();
		buffer = buffer or vim.api.nvim_get_current_buf();

		helpview.render(buffer);
	end,
	["clear"] = function (buffer)
		helpview.clean();
		buffer = buffer or vim.api.nvim_get_current_buf();

		helpview.clear(buffer);
	end,

	["toggleAll"] = function ()
		health.notify("deprecation", {
			option = ":Helpview toggleAll",
			alter = ":Helpview Toggle",
			silent = true
		});

		helpview.commands.Toggle();
	end,
	["enableAll"] = function ()
		health.notify("deprecation", {
			option = ":Helpview enableAll",
			alter = ":Helpview Enable",
			silent = true
		});

		helpview.commands.Enable();
	end,
	["disableAll"] = function ()
		health.notify("deprecation", {
			option = ":Helpview disableAll",
			alter = ":Helpview Disable",
			silent = true
		});

		helpview.commands.Disable();
	end,

	["toggle"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();
		helpview.clean();

		local state = helpview.state.buffer_states[buffer];

		if state == nil then
			return;
		elseif state.enable == true then
			helpview.commands.disable(buffer);
		else
			helpview.commands.enable(buffer);
		end
	end,
	["enable"] = function (buffer)
		helpview.actions.enable(buffer)
	end,
	["disable"] = function (buffer)
		helpview.actions.disable(buffer)
	end,

	["hybridToggle"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.actions.__is_attached(buffer) == false then
			return;
		elseif type(helpview.state.buffer_states[buffer]) ~= "table" then
			return;
		elseif helpview.state.buffer_states[buffer].hybrid_mode == true then
			helpview.actions.hybridDisable(buffer);
		else
			helpview.actions.hybridEnable(buffer);
		end
	end,
	["hybridDisable"] = function (buffer)
		helpview.actions.hybridDisable(buffer);
	end,
	["hybridEnable"] = function (buffer)
		helpview.actions.hybridEnable(buffer);
	end,

	["HybridToggle"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			helpview.commands.hybridToggle(buf);
		end
	end,

	["HybridDisable"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			helpview.commands.hybridDisable(buf);
		end
	end,

	["HybridEnable"] = function ()
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			helpview.commands.hybridEnable(buf);
		end
	end,

	["splitToggle"] = function ()
		if type(helpview.state.splitview_source) ~= "number" then
			helpview.actions.splitOpen();
		elseif helpview.win_is_safe(helpview.state.splitview_window) == false then
			helpview.actions.splitClose();
			helpview.actions.splitOpen();
		else
			helpview.actions.splitClose();
		end
	end,

	["splitRedraw"] = function ()
		helpview.splitview_render();
	end,

	["splitOpen"] = function (buffer)
		helpview.actions.splitOpen(buffer)
	end,

	["splitClose"] = function ()
		helpview.actions.splitClose()
	end,

	["Start"] = function ()
		helpview.state.enable = true;
	end,
	["Stop"] = function ()
		helpview.state.enable = false;
	end,

	-- ["open"] = function ()
	-- 	require("helpview.links").open();
	-- end
};

--- Wrapper for `:help`.
helpview.help = {
	---@type integer Overlay buffer.
	overlay_buffer = nil,
	---@type integer Preview buffer.
	preview_buffer = nil,

	---@type integer Overlay window.
	overlay_window = nil,
	---@type integer Preview window.
	preview_window = nil,

	---@type integer Window leave autocmd.
	leave_autocmd = nil,
	---@type integer Window resize autocmd.
	resize_autocmd = nil,

	--- Sets up the needed buffers/windows/autocmds.
	---@param self table
	---@param overlay_opts table
	---@param preview_opts table
	__setup = function (self, overlay_opts, preview_opts)
		if type(preview_opts.split) == "string" then
			goto no_overlay;
		end

		if helpview.buf_is_safe(self.overlay_buffer) == false then
			pcall(vim.api.nvim_buf_delete, self.overlay_buffer, true);
			self.overlay_buffer = vim.api.nvim_create_buf(false, true);
		end

		if helpview.win_is_safe(self.overlay_window) == false then
			pcall(vim.api.nvim_win_close, self.overlay_window, { force = true });
			self.overlay_window = vim.api.nvim_open_win(self.overlay_buffer, false, overlay_opts);

			vim.wo[self.overlay_window].cursorline = false;
			vim.wo[self.overlay_window].cursorcolumn = false;
		else
			vim.api.nvim_win_set_config(self.overlay_window, overlay_opts);
		end

		::no_overlay::

		if helpview.buf_is_safe(self.preview_buffer) == false then
			pcall(vim.api.nvim_buf_delete, self.preview_buffer, true);
			self.preview_buffer = vim.api.nvim_create_buf(false, true);

			vim.bo[self.preview_buffer].ft = "help";
			vim.bo[self.preview_buffer].bt = "help";

			self.leave_autocmd = vim.api.nvim_create_autocmd({ "WinClosed" }, {
				callback = function (ev)
					local emitted_from = tonumber(ev.match);

					if emitted_from ~= self.preview_window then
						return;
					end

					self:close()
				end
			});
		end

		if helpview.win_is_safe(self.preview_window) == false then
			pcall(vim.api.nvim_win_close, self.preview_window, { force = true });
			self.preview_window = vim.api.nvim_open_win(self.preview_buffer, true, preview_opts);
		else
			vim.api.nvim_win_set_config(self.preview_window, preview_opts);
		end
	end,

	--- Closes help window.
	---@param self table
	close = function (self)
		pcall(vim.api.nvim_del_autocmd, self.leave_autocmd);
		pcall(vim.api.nvim_del_autocmd, self.resize_autocmd);

		pcall(vim.api.nvim_win_close, self.overlay_window, { force = true });
		pcall(vim.api.nvim_win_close, self.preview_window, { force = true });
	end,

	--- Opens help window
	---@param self table
	---@param tag? string
	open = function (self, tag)
		tag = tag or "";

		local overlay_opts = spec.get({ "preview", "overlay_winopts" }, { fallback = {} });
		local preview_opts = spec.get({ "preview", "preview_winopts" }, { fallback = {} });

		---@return integer
		---@return integer
		local function get_size()
			local w = preview_opts.width or 78;
			local h = preview_opts.height or (vim.o.lines - vim.o.cmdheight);

			if w <= 1 then
				w = math.floor(w * vim.o.columns);
			end

			if h <= 1 then
				h = math.floor(h * vim.o.lines);
			end

			return w, h;
		end

		local dimensions = { get_size() };

		if type(preview_opts.split) == "string" then
			self:__setup(
				overlay_opts,
				vim.tbl_extend("force", preview_opts, {
					width = dimensions[1],
					height = dimensions[2]
				})
			);
		else
			self:__setup(
				vim.tbl_extend("force", overlay_opts, {
					relative = "editor",
					zindex = 5,

					row = 0,
					col = 0,

					width = vim.o.columns,
					height = vim.o.lines - vim.o.cmdheight,

					focusable = false,
					style = "minimal"
				}),
				vim.tbl_extend("force", preview_opts, {
					relative = "editor",
					zindex = 6,

					row = math.ceil(((vim.o.lines - vim.o.cmdheight) - dimensions[2]) / 2),
					col = math.ceil((vim.o.columns - dimensions[1]) / 2),

					width = dimensions[1],
					height = dimensions[2]
				})
			);
		end

		self.resize_autocmd = vim.api.nvim_create_autocmd({ "VimResized" }, {
			callback = function ()
				local new_dimensions = { get_size() };

				self:__setup(
					vim.tbl_extend("force", overlay_opts, {
						relative = "editor",
						zindex = 5,

						row = 0,
						col = 0,

						width = vim.o.columns,
						height = vim.o.lines - vim.o.cmdheight,

						focusable = false,
						style = "minimal"
					}),
					vim.tbl_extend("force", preview_opts, {
						relative = "editor",
						zindex = 6,

						row = math.ceil(((vim.o.lines - vim.o.cmdheight) - new_dimensions[2]) / 2),
						col = math.ceil((vim.o.columns - new_dimensions[1]) / 2),

						width = new_dimensions[1],
						height = new_dimensions[2]
					})
				);
			end
		});

		helpview.actions.__exec_callback("on_help_open", self.preview_buffer, self.preview_window, self.overlay_preview, self.overlay_window);
		vim.cmd("help " .. tag);

		helpview.actions.attach(self.preview_buffer);
		helpview.render(self.preview_buffer);
	end
};

--- Setup function.
---@param user_config? helpview.config
helpview.setup = function (user_config)
	if user_config == nil then
		return;
	end

	require("helpview.spec").setup(user_config);
end

return helpview;
-- vim:foldmethod=indent:
