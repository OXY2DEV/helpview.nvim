local parser = {};

local health = require("helpview.health");
parser.vimdoc = require("helpview.parsers.vimdoc");

--- Custom `tbl_deep_extend()` that also works on lists.
---@param tbl_1 table
---@param tbl_2 table
---@return table
parser.deep_extend = function (tbl_1, tbl_2)
	for k, v in pairs(tbl_2) do
		if tbl_1[k] then
			if vim.islist(v) and vim.islist(tbl_1[k]) then
				tbl_1[k] = vim.list_extend(tbl_1[k], v);
			elseif type(v) == "table" and type(tbl_1[k]) == "table" then
				tbl_1[k] = parser.deep_extend(tbl_1[k], v);
			else
				tbl_1[k] = v;
			end
		else
			tbl_1[k] = v;
		end
	end

	return tbl_1;
end

--- Should a TSTree be ignored.
---@param TSTree TSTree
---@param ignore_ranges [ integer, integer ][]
---@return boolean
parser.should_ignore = function (TSTree, ignore_ranges)
	local t_start, _, t_stop, _ = TSTree:root():range();

	for _, range in ipairs(ignore_ranges) do
		if t_start >= range[1] and t_stop <= range[2] then
			return true;
		end
	end

	return false;
end

--- Initializes the parsers on the specified buffer.
--- Parsed data is stored as a "view" in renderer.lua
---
---@param buffer number
---@param from integer?
---@param to integer?
---
---@return table
---@return table
parser.init = function (buffer, from, to)
	-- Clear the previous contents

	local content = {};
	local sorted = {};
	local ignore_ranges = {};

	if
		not pcall(vim.treesitter.get_parser, buffer) or
		not vim.treesitter.get_parser(buffer)
	then
		return content, sorted;
	end

	--- Creates a range of lines to ignore.
	---@param language string
	---@param items table[]
	---@return [ integer, integer ][]
	local function create_ignore_range (language, items)
		local _r = {};

		if language == "vimdoc" then
			for _, item in ipairs(items["vimdoc_code_block"] or {}) do
				table.insert(_r, { item.range.row_start, item.range.row_end })
			end
		end

		ignore_ranges = vim.list_extend(ignore_ranges, _r);
		return _r;
	end

	---@type integer Start time
	---@diagnostic disable-next-line: undefined-field
	local start = vim.uv.hrtime();

	health.notify("trace", {
		level = 1,
		message = string.format("Parsing(start): %d", buffer)
	});
	health.__child_indent_in();

    vim.treesitter.get_parser(buffer):parse(true);
	local root_parser = vim.treesitter.get_parser(buffer);

	if not root_parser then
		return content, sorted;
	end

	root_parser:for_each_tree(function (TSTree, language_tree)
		language_tree:parse(true);

		local language = language_tree:lang();
		local _content, _sorted = {}, {};

		if parser[language] and not parser.should_ignore(TSTree, ignore_ranges) then
			_content, _sorted = parser[language].parse(buffer, TSTree, from, to);
			create_ignore_range(language, _sorted)
		end

		content[language] = vim.list_extend(content[language] or {}, _content);
		sorted[language] = parser.deep_extend(sorted[language] or {}, _sorted);
	end);

	---@type integer End time
	---@diagnostic disable-next-line: undefined-field
	local now = vim.uv.hrtime();

	health.__child_indent_de();
	health.notify("trace", {
		level = 3,
		message = string.format("Parsing(end, %dms): %d", (now - start) / 1e6, buffer)
	});

	return content, sorted;
end

parser.parse = parser.init;

return parser;
