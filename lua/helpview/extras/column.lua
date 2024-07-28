--- Doesn't quite work

local column = {};

column.cached_views = {};

column.configuraton = {
	code_block_hl = "HelpviewCodeBlocks",

	modes = { "n", "c" }
};

column.cache = function (buffer, data)
	column.cached_views[buffer] = {};

	for _, entry in ipairs(data or {}) do
		if entry.type == "code_block" then
			table.insert(column.cached_views[buffer], entry);
		end
	end
end

column.hl_code_blocks = function (buffer)
	if not column.cached_views[buffer] or vim.tbl_isempty(column.cached_views[buffer]) then
		return "";
	end

	for _, code in ipairs(column.cached_views[buffer]) do
		if vim.v.lnum == (code.row_start + 1) and vim.v.virtnum < 0 then
			return "%#" .. column.configuraton.code_block_hl .. "#";
		elseif vim.v.lnum > (code.row_start + 1) and vim.v.lnum < (code.row_end + 1) then
			return "%#" .. column.configuraton.code_block_hl .. "#";
		end
	end

	return "";
end

column.draw = function (window, buffer)
	local w_width = vim.api.nvim_win_get_width(window);
	local t_width = vim.bo[buffer].textwidth;

	local mode = vim.api.nvim_get_mode().mode;

	local _o = "";

	if vim.v.relnum == 0 and vim.v.virtnum == 0 then
		_o = "%#" .. "CursorLine" .. "#";
	end

	_o = _o .. column.hl_code_blocks(buffer);

	if vim.list_contains(column.configuraton.modes or {}, mode) and math.floor((w_width - t_width) / 2) < 15 and t_width < w_width then
		_o = _o .. string.rep(" ", math.floor((w_width - t_width) / 2));
	end

	return _o;
end

column.set = function (window, buffer)
	local w_width = vim.api.nvim_win_get_width(window);
	local t_width = vim.bo[buffer].textwidth;

	local total_spaces = math.floor((w_width - t_width) / 2);

	if total_spaces < 15 and w_width > t_width then
		vim.wo[window].numberwidth = math.floor(total_spaces / 3);
		-- vim.wo[window].foldcolumn = "auto:[1-" .. math.floor(total_spaces / 3) .. "]";
		-- vim.cmd("setlocal signcolumn=yes[1-" .. math.floor(total_spaces / 3) .. "]");
	end

	vim.wo[window].relativenumber = true;
	vim.wo[window].statuscolumn = "%!v:lua.require('helpview.extras.column').draw(" .. window .. "," .. buffer .. ")";
end

return column;
