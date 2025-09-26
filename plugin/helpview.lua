--- Functionality provider for `helpview.nvim`.
--- Functionalities that are implemented,
---
---   + Buffer registration.
---   + Command.
---   + Dynamic highlight groups.
---
--- **Author**: MD. Mouinul Hossain Shawon (OXY2DEV)

local helpview = require("helpview");
local spec = require("helpview.spec");
local health = require("helpview.health");

health.notify("trace", {
	level = 1,
	message = "Start"
});

health.notify("trace", {
	level = 5,
	message = "Created highlight groups"
});

--- Update highlight groups on colorscheme changes.
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
	group = helpview.au,
	callback = function ()
		---+

		require("helpview.highlights").setup();
		vim.g.__helpview_hl_group_map = vim.api.nvim_get_hl(0, {});

		health.notify("trace", {
			level = 5,
			message = "Updated highlight groups"
		});

		---_
	end
});

--- Register new buffers.
vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
	group = helpview.au,
	callback = function (event)
		---+

		vim.defer_fn(function ()
			local buffer = event.buf;

			if helpview.state.enable == false then
				--- New buffers shouldn't be registered.
				return;
			elseif helpview.actions.__is_attached(buffer) == true then
				--- Already attached to this buffer!
				return;
			elseif helpview.can_attach(buffer) == false then
				--- Already attached to this buffer!
				return;
			end

			---@type string, string
			local bt, ft = vim.bo[buffer].buftype, vim.bo[buffer].filetype;
			local attach_ft = spec.get({ "preview", "filetypes" }, { fallback = {}, ignore_enable = true });
			local ignore_bt = spec.get({ "preview", "ignore_buftypes" }, { fallback = {}, ignore_enable = true });

			local condition = spec.get({ "preview", "condition" }, { eval_args = { buffer } });

			if vim.list_contains(ignore_bt, bt) == true then
				--- Ignored buffer type.
				return;
			elseif vim.list_contains(attach_ft, ft) == false then
				--- Ignored file type.
				return;
			elseif condition == false then
				return;
			end

			helpview.actions.attach(buffer);
		end, 0);

		---_
	end
});

vim.api.nvim_create_autocmd({ "ModeChanged" }, {
	group = helpview.au,
	callback = function (event)
		---+

		local buffer = event.buf;
		local mode = vim.api.nvim_get_mode().mode;

		---@type string[] List of modes where preview is shown.
		local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
		---@type string[] List of modes where preview is shown.
		local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

		local old_mode = vim.v.event.old_mode;

		if helpview.actions.__is_attached(buffer) == false then
			--- Buffer isn't attached!
			return;
		elseif helpview.actions.__is_enabled(buffer) == false then
			--- Helpview disabled on this buffer.
			helpview.clear(buffer);
			return;
		elseif buffer == helpview.state.splitview_source then
			--- Splitview should only update from
			--- cursor movements or content changes.
			return;
		end

		if vim.list_contains(hybrid_modes, mode) then
			health.notify("trace", {
				level = 1,
				message = string.format("Mode(%s): %d", mode, buffer);
			});
			health.__child_indent_in();

			if vim.list_contains(hybrid_modes, old_mode) then
				--- Switching between 2 hybrid modes.
				goto callback;
			else
				vim.defer_fn(function ()
					helpview.render(buffer);
				end, 0);
			end
		elseif vim.list_contains(preview_modes, mode) then
			health.notify("trace", {
				level = 1,
				message = string.format("Mode(%s): %d", mode, buffer);
			});
			health.__child_indent_in();

			--- Preview
			if vim.list_contains(hybrid_modes, old_mode) then
				vim.defer_fn(function ()
					helpview.render(buffer);
				end, 0);
			elseif vim.list_contains(preview_modes, old_mode) then
				--- Previous mode was a preview
				--- mode.
				--- Most likely the text hasn't
				--- changed.
				goto callback;
			else
				helpview.render(buffer);
			end
		else
			health.notify("trace", {
				level = 2,
				message = string.format("Mode(%s): %d", mode, buffer);
			});
			health.__child_indent_in();

			--- Clear
			if vim.list_contains(preview_modes, old_mode) == false then
				--- Previous mode was not a preview
				--- mode.
				--- Most likely a preview shouldn't
				--- have occurred.
				goto callback;
			else
				helpview.clear(buffer);
			end
		end

		::callback::
		helpview.actions.__exec_callback("on_mode_change", buffer, vim.fn.win_findbuf(buffer), mode)
		health.__child_indent_de();

		---_
	end
});


local timer = vim.uv.new_timer();

--- Preview updates.
vim.api.nvim_create_autocmd({
	"CursorMoved",  "TextChanged",
	"CursorMovedI", "TextChangedI"
}, {
	group = helpview.au,
	callback = function (event)
		---+${lua}
		timer:stop();

		local buffer = event.buf;
		local name = event.event;
		local mode = vim.api.nvim_get_mode().mode;

		---@type string[] List of modes where preview is shown.
		local modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
		---@type string[] List of modes where preview is shown.
		local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });
		local delay = spec.get({ "preview", "debounce" }, { fallback = 25, ignore_enable = true });

		--- Checks if we need to immediately render
		--- previews or not.
		---@return boolean
		local function immediate_render ()
			---+${lua}
			if vim.list_contains({ "TextChanged", "TextChangedI" }, name) then
				--- Changes to the buffer content MUST
				--- always be debounced to ensure that
				--- this doesn't hamper typing.
				return false;
			end

			local utils = require("helpview.utils");
			local win = utils.buf_getwin(buffer);

			if type(win) ~= "number" or helpview.win_is_safe(win) == false then
				--- Window isn't safe.
				--- This shouldn't occur normally.
				return false;
			end

			local distance_threshold = math.floor(vim.o.lines * 0.75);
			local pos_y = vim.api.nvim_win_get_cursor(win)[1];

			local old = helpview.state.buffer_states[buffer].y or 0;
			local diff = math.abs(pos_y - old);

			--- Update the cached cursor position.
			if not helpview.state.buffer_states[buffer].y then
				helpview.state.buffer_states[buffer].y = pos_y;
			elseif diff >= distance_threshold then
				helpview.state.buffer_states[buffer].y = pos_y;
			end

			if diff >= distance_threshold then
				--- User has covered a significant
				--- distance since the last redraw.
				---
				--- We probably should redraw.
				return true;
			else
				--- User still hasn't covered a large
				--- distance.
				---
				--- We shouldn't redraw.
				return false;
			end
			---_
		end

		--- Handles the renderer for a buffer.
		local handle_renderer = function ()
			---+${lua}

			---@type integer
			local lines = vim.api.nvim_buf_line_count(buffer);
			---@type integer
			local max_l = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });

			if lines >= max_l then
				if immediate_render() == true then
					--- Use a small delay to prevent input
					--- lags when doing `gg` or `G`.
					-- helpview.render(buffer);
					vim.defer_fn(function ()
						if vim.v.exiting ~= vim.NIL then
							return;
						end

						helpview.render(buffer);
					end, 0);
				else
					timer:start(delay, 0, vim.schedule_wrap(function ()
						if vim.v.exiting ~= vim.NIL then
							return;
						end

						helpview.render(buffer);
					end));
				end
			elseif vim.list_contains(hybrid_modes, mode) then
				if not helpview.state.buffer_states[buffer] then
					return;
				elseif helpview.state.buffer_states[buffer].hybrid_mode == false then
					return;
				end

				--- Hybrid mode movements MUST be
				--- handled through debounce.
				timer:start(delay, 0, vim.schedule_wrap(function ()
					if vim.v.exiting ~= vim.NIL then
						return;
					end

					helpview.render(buffer);
				end));
			elseif vim.list_contains({ "TextChanged", "TextChangedI" }, name) then
				--- Buffer content changes MUST be
				--- handle via debounce.
				timer:start(delay, 0, vim.schedule_wrap(function ()
					if vim.v.exiting ~= vim.NIL then
						return;
					end

					helpview.render(buffer);
				end));
			end

			---_
		end

		--- Handles the splitview renderer.
		local function handle_splitview ()
			---+${lua}

			---@type integer
			local lines = vim.api.nvim_buf_line_count(buffer);
			---@type integer
			local max_l = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });

			if lines >= max_l then
				if immediate_render() == true then
					--- Use a small delay to prevent input
					--- lags when doing `gg` or `G`.
					-- helpview.render(buffer);
					vim.defer_fn(function ()
						if vim.v.exiting ~= vim.NIL then
							return;
						end

						helpview.splitview_render();
					end, 0);
				elseif vim.list_contains({ "CursorMoved", "CursorMovedI" }, name) then
					--- BUG, on Android changing cursor
					--- position outside of `defer_fn`
					--- results in high input lags.
					vim.defer_fn(function ()
						if vim.v.exiting ~= vim.NIL then
							return;
						end

						helpview.update_splitview_cursor();
					end, 0);
				else
					--- Buffer content change(use debounce).
					timer:start(delay, 0, vim.schedule_wrap(function ()
						if vim.v.exiting ~= vim.NIL then
							return;
						end

						helpview.splitview_render();
					end));
				end
			elseif vim.list_contains({ "TextChanged", "TextChangedI" }, name) then
				timer:start(delay, 0, vim.schedule_wrap(function ()
					if vim.v.exiting ~= vim.NIL then
						return;
					end

					helpview.splitview_render();
				end));
			else
				vim.defer_fn(function ()
					if vim.v.exiting ~= vim.NIL then
						return;
					end

					helpview.update_splitview_cursor();
				end, 0);
			end

			---_
		end

		if buffer == helpview.state.splitview_source then
			handle_splitview();
		else
			--- Do these checks only for normal buffers.
			if helpview.actions.__is_attached(buffer) == false then
				return;
			elseif helpview.actions.__is_enabled(buffer) == false then
				return;
			elseif vim.list_contains(modes, mode) == false then
				if buffer == helpview.state.splitview_source then
					handle_splitview();
				end

				return;
			end

			handle_renderer();
		end
		---_
	end
});


---@type mkv.cmd_completion
local get_complete_items = {
	default = function (str)
		---+${lua}
		if str == nil then
			local _o = vim.tbl_keys(helpview.commands);
			table.sort(_o);

			return _o;
		end

		local _o = {};

		for _, key in ipairs(vim.tbl_keys(helpview.commands)) do
			if string.match(key, "^" .. str) then
				table.insert(_o, key);
			end
		end

		table.sort(_o);
		return _o;
		---_
	end,

	attach = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if helpview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	detach = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(helpview.state.attached_buffers) do
			if helpview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,

	enable = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(helpview.state.attached_buffers) do
			if helpview.buf_is_safe(buffer) == false or helpview.actions.__is_enabled(buffer) == true then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	disable = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(helpview.state.attached_buffers) do
			if helpview.buf_is_safe(buffer) == false or helpview.actions.__is_enabled(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,

	hybridToggle = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(helpview.state.attached_buffers) do
			if helpview.buf_is_safe(buffer) == false or helpview.actions.__is_enabled(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	hybridDisable = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(helpview.state.attached_buffers) do
			if helpview.buf_is_safe(buffer) == false or helpview.actions.__is_enabled(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	hybridEnable = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(helpview.state.attached_buffers) do
			if helpview.buf_is_safe(buffer) == false or helpview.actions.__is_enabled(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,

	splitOpen = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(helpview.state.attached_buffers) do
			if helpview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,

	render = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if helpview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	clear = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if helpview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end
};

vim.api.nvim_create_user_command("Help", function (cmd)
	helpview.help:open(cmd.fargs[1])
end, {
	---+

	desc = "Fancy :help",
	nargs = "?",

	complete = function (_, cmd, cursorpos)
		local before = string.sub(cmd, 0, cursorpos):gsub("^Help%s*", "");

		local parts = {};

		for part in string.gmatch(before, "%S+") do
			table.insert(parts, part);
		end

		if #parts > 1 then
			return {};
		elseif before:match("%s$") then
			return {};
		else
			return vim.fn.getcompletion(parts[1] or "", "help", vim.o.wildignore);
		end
	end

	---_
});

vim.api.nvim_create_user_command("H", function (cmd)
	helpview.help:open(cmd.fargs[1])
end, {
	---+

	desc = "Fancy :help",
	nargs = "?",

	complete = function (_, cmd, cursorpos)
		local before = string.sub(cmd, 0, cursorpos):gsub("^H%s*", "");

		local parts = {};

		for part in string.gmatch(before, "%S+") do
			table.insert(parts, part);
		end

		if #parts > 1 then
			return {};
		elseif before:match("%s$") then
			return {};
		else
			return vim.fn.getcompletion(parts[1] or "", "help", vim.o.wildignore);
		end
	end

	---_
});

--- User command.
vim.api.nvim_create_user_command("Helpview", function (cmd)
	---+${lua}

	local function exec(fun, args)
		args = args or {};
		local fargs = {};

		for _, arg in ipairs(args) do
			if tonumber(arg) then
				table.insert(fargs, tonumber(arg));
			elseif arg == "true" or arg == "false" then
				table.insert(fargs, arg == "true");
			else
				--- BUG, is this used by any functions?
				-- table.insert(fargs, arg);
			end
		end

		---@diagnostic disable-next-line
		pcall(fun, unpack(fargs));
	end

	---@type string[] Command arguments.
	local args = cmd.fargs;

	if #args == 0 then
		helpview.commands.Toggle();
	elseif type(helpview.commands[args[1]]) == "function" then
		--- FIXME, Change this if `vim.list_slice` becomes deprecated.
		exec(helpview.commands[args[1]], vim.list_slice(args, 2))
	end
	---_
end, {
	---+${lua}
	nargs = "*",
	desc = "User command for `helpview.nvim`",
	complete = function (_, cmd, cursorpos)
		local function is_subcommand(str)
			return helpview.commands[str] ~= nil;
		end

		local before = string.sub(cmd, 0, cursorpos);
		local parts = {};

		for part in string.gmatch(before, "%S+") do
			table.insert(parts, part);
		end

		if #parts == 1 then
			return get_complete_items.default(parts[2]);
		elseif #parts == 2 and is_subcommand(parts[2]) == false then
			return get_complete_items.default(parts[2]);
		elseif is_subcommand(parts[2]) == true and get_complete_items[parts[2]] ~= nil then
			return get_complete_items[parts[2]](parts, before);
		end
	end
	---_
});

