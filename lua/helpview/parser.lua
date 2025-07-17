local parser = {};
local health = require("helpview.health");

parser.vimdoc = require("helpview.parsers.vimdoc");

parser.ignore_ranges = {};

parser.create_ignore_range = function (language, items)
	local _r = {};

	if language == "vimdoc" then
		for _, item in ipairs(items["vimdoc_code_block"] or {}) do
			table.insert(_r, { item.range.row_start, item.range.row_end })
		end
	end

	parser.ignore_ranges = vim.list_extend(parser.ignore_ranges, _r);
	return _r;
end

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

parser.should_ignore = function (TSTree)
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

parser.content = {};
parser.sorted = {};
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
	parser.content = {};
	parser.sorted = {};
	parser.ignore_ranges = {};

	if
		not pcall(vim.treesitter.get_parser, buffer) or
		not vim.treesitter.get_parser(buffer)
	then
		return parser.content, parser.sorted;
	end

	---+${lua, Announce start of parsing}
	---@type integer Start time
	---@diagnostic disable-next-line: undefined-field
	local start = vim.uv.hrtime();

	health.notify("trace", {
		level = 1,
		message = string.format("Parsing(start): %d", buffer)
	});
	health.__child_indent_in();
	---_

    vim.treesitter.get_parser(buffer):parse(true);
	local root_parser = vim.treesitter.get_parser(buffer);

	root_parser:for_each_tree(function (TSTree, language_tree)
		language_tree:parse(true);

		local language = language_tree:lang();
		local content, sorted = {}, {};

		if parser[language] and not parser.should_ignore(TSTree) then
			content, sorted = parser[language].parse(buffer, TSTree, from, to);
			parser.create_ignore_range(language, sorted)
		end

		parser.content[language] = vim.list_extend(parser.content[language] or {}, content);
		parser.sorted[language] = parser.deep_extend(parser.sorted[language] or {}, sorted);
	end)

	---+${lua, Announce end of parsing}
	---@type integer End time
	---@diagnostic disable-next-line: undefined-field
	local now = vim.uv.hrtime();

	health.__child_indent_de();
	health.notify("trace", {
		level = 3,
		message = string.format("Parsing(end, %dms): %d", (now - start) / 1e6, buffer)
	});
	---_

	return parser.content, parser.sorted;
end

parser.parse = parser.init;

return parser;
