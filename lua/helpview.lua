local helpview = {};
local spec = require("helpview.spec");

helpview.state = {
	enable = true,
	attached_buffers = {},

	buffer_states = {},

	splitview_source = nil,
	splitview_buffer = nil,
	splitview_window = nil
}

helpview.strict_render = {
	---+${lua}

	on = {},

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

	---_
};

helpview.clean = function ()
	---+${lua}

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

	---_
end

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

helpview.can_attach = function (buffer)
	helpview.clean();

	if helpview.buf_is_safe(buffer) == false then
		return false;
	elseif vim.list_contains(helpview.state.attached_buffers, buffer) then
		return false;
	end

	return true;
end

helpview.can_draw = function (buffer)
	helpview.clean();

	if helpview.buf_is_safe(buffer) == false then
		return false;
	elseif helpview.actions.__is_enabled(buffer) == false then
		return false;
	end

	return true;
end

helpview.clear = function (buffer)
	buffer = buffer or vim.api.nvim_get_current_buf();
	require("helpview.renderer").clear(buffer, 0, -1);
end

helpview.render = function (buffer, state)
	---+${lua}

	local parser = require("helpview.parser");
	local renderer = require("helpview.renderer");

	buffer = buffer or vim.api.nvim_get_current_buf();

	local line_limit = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });
	local draw_range = spec.get({ "preview", "draw_range" }, { fallback = { vim.o.lines, vim.o.lines }, ignore_enable = true });
	local edit_range = spec.get({ "preview", "edit_range" }, { fallback = { 1, 0 }, ignore_enable = true });

	local modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
	local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });
	local linewise = spec.get({ "preview", "linewise_hybrid_mode" }, { fallback = false, ignore_enable = true });

	local line_count = vim.api.nvim_buf_line_count(buffer);
	local mode = vim.api.nvim_get_mode().mode;

	state = state or helpview.state.buffer_states[buffer] or {};

	local function is_hybrid_mode ()
		if type(state) == "table" and state.hybrid_mode == false then
			return false;
		else
			return vim.list_contains(hybrid_modes, mode);
		end
	end

	local content;

	helpview.clear(buffer);

	if line_count >= line_limit then
		if is_hybrid_mode() == true and linewise == false then
			for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
				local cursor = vim.api.nvim_win_get_cursor(win);
				cursor[1] = cursor[1] - 1;

				content, _ = parser.init(
					buffer,
					math.max(0, cursor[1] - draw_range[1]),
					math.min(line_count, cursor[1] + draw_range[1])
				);

				content = renderer.filter(content, nil, {
					math.max(0, cursor[1] - edit_range[1]),
					math.min(line_count, cursor[1] + edit_range[1]),
				});
			end

			renderer.render(buffer, content);
		elseif is_hybrid_mode() == true then
			renderer.render(buffer, content);

			for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
				local cursor = vim.api.nvim_win_get_cursor(win);
				cursor[1] = cursor[1] - 1;

				content, _ = parser.init(
					buffer,
					math.max(0, cursor[1] - draw_range[1]),
					math.min(line_count, cursor[1] + draw_range[1])
				);

				renderer.clear(buffer,
					math.max(0, cursor[1] - edit_range[1]),
					math.min(line_count, cursor[1] + edit_range[1])
				);
			end
		else
			for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
				local cursor = vim.api.nvim_win_get_cursor(win);
				cursor[1] = cursor[1] - 1;

				content, _ = parser.init(
					buffer,
					math.max(0, cursor[1] - draw_range[1]),
					math.min(line_count, cursor[1] + draw_range[1])
				);

				renderer.render(buffer, content);
			end
		end
	else
		for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
			local cursor = vim.api.nvim_win_get_cursor(win);
			cursor[1] = cursor[1] - 1;

			content, _ = parser.init(
				buffer,
				0,
				-1
			);

			if is_hybrid_mode() == true and linewise == false then
				content = renderer.filter(content, nil, {
					math.max(0, cursor[1] - edit_range[1]),
					math.min(line_count, cursor[1] + edit_range[1]),
				});

				renderer.render(buffer, content);
			elseif is_hybrid_mode() == true then
				renderer.render(buffer, content);

				renderer.clear(buffer,
					math.max(0, cursor[1] - edit_range[1]),
					math.min(line_count, cursor[1] + edit_range[1])
				);
			else
				renderer.render(buffer, content);
			end
		end
	end

	---_
end

--- Updates cursor position in splitview.
helpview.update_splitview_cursor = function ()
	---+${lua}

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

	---_
end

helpview.splitview_render = function ()
	---+${lua}

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

	local max_lines = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });
	local line_count = vim.api.nvim_buf_line_count(buffer);

	local main_win = utils.buf_getwin(buffer);
	local cursor = vim.api.nvim_win_get_cursor(main_win);

	local pre_buf = helpview.state.splitview_buffer;
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
	---_
end

helpview.actions = {
	["__exec_callback"] = function (callback, ...)
		if vim.list_contains({ "string", "integer" }, type(callback)) == false then
			return;
		end

		---@type function | nil
		local _f = spec.get({ "preview", "callbacks", callback }, { ignore_enable = true });
		pcall(_f, ...);
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


	["attach"] = function (buffer, state)
		---+${lua}

		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.can_attach(buffer) == false then
			return;
		end

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

		---_
	end,
	--- Detaches previewer from a buffer.
	---@param buffer integer?
	["detach"] = function (buffer)
		---+${lua}

		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if helpview.buf_is_safe(buffer) == false then
			--- Something went wrong.
			return;
		elseif helpview.can_attach(buffer) == true then
			--- This buffer hasn't been attached to.
			return;
		end

		-- health.notify("trace", {
		-- 	level = 9,
		-- 	message = string.format("Detached: %d", buffer)
		-- });
		-- health.__child_indent_in();

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
		-- health.__child_indent_de()
		---_
	end,

	["disable"] = function (buffer)
		---+${lua}
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

		-- health.notify("trace", {
		-- 	level = 7,
		-- 	message = string.format("Disabled: %d", buffer)
		-- });
		-- health.__child_indent_in();

		helpview.state.buffer_states[buffer].enable = false;
		helpview.clear(buffer);

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer))

		local mode = vim.api.nvim_get_mode().mode;
		---@type string[]
		local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

		if vim.list_contains(hybd_modes, mode) == false then
			-- health.__child_indent_de();
			return;
		end

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_hybrid_disable", buffer, vim.fn.win_findbuf(buffer))
		-- health.__child_indent_de();
		---_
	end,
	["enable"] = function (buffer)
		---+${lua}
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

		-- health.notify("trace", {
		-- 	level = 6,
		-- 	message = string.format("Enabled: %d", buffer)
		-- });
		-- health.__child_indent_in();

		helpview.state.buffer_states[buffer].enable = true;

		local mode = vim.api.nvim_get_mode().mode;
		---@type string[]
		local prev_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
		---@type string[]
		local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

		if vim.list_contains(prev_modes, mode) == false then
			-- health.__child_indent_de();
			return;
		end

		helpview.render(buffer);

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer))

		if vim.list_contains(hybd_modes, mode) == false then
			-- health.__child_indent_de();
			return;
		end

		--- Execute the attaching autocmd.
		helpview.actions.__exec_callback("on_hybrid_enable", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		-- health.__child_indent_de();
		---_
	end,

	["hybridEnable"] = function (buffer)
		---+${lua}

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

		---_
	end,

	["hybridDisable"] = function (buffer)
		--+${lua}

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

		---_
	end,

	["splitOpen"] = function (buffer)
		--++${lua}

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
		---_
	end,
	["splitClose"] = function ()
		---+${lua}
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
		---_
	end
};

--- Holds various functions that you can run
--- vim `:Markview ...`.
---@type { [string]: function }
helpview.commands = {
	---+${class}

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
		---+${class}
		helpview.clean();

		for _, buf in ipairs(helpview.state.attached_buffers) do
			helpview.commands.toggle(buf);
		end
		---_
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
			option = ":Markview toggleAll",
			alter = ":Markview Toggle",
			silent = true
		});

		helpview.commands.Toggle();
	end,
	["enableAll"] = function ()
		health.notify("deprecation", {
			option = ":Markview enableAll",
			alter = ":Markview Enable",
			silent = true
		});

		helpview.commands.Enable();
	end,
	["disableAll"] = function ()
		health.notify("deprecation", {
			option = ":Markview disableAll",
			alter = ":Markview Disable",
			silent = true
		});

		helpview.commands.Disable();
	end,

	["toggle"] = function (buffer)
		---+${class}
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
		---_
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
		---+${class}

		if type(helpview.state.splitview_source) ~= "number" then
			helpview.actions.splitOpen();
		elseif helpview.win_is_safe(helpview.state.splitview_window) == false then
			helpview.actions.splitClose();
			helpview.actions.splitOpen();
		else
			helpview.actions.splitClose();
		end
		---_
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

	["open"] = function ()
		require("helpview.links").open();
	end
	---_
};

helpview.setup = function (user_config)
	require("helpview.spec").setup(user_config);
end

return helpview;
