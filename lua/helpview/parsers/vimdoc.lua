local vimdoc = {};
local utils = require("helpview.utils");

--- Queried contents
---@type table[]
vimdoc.content = {};

--- Queried contents, but sorted
vimdoc.sorted = {}

--- Inserts an item.
---@param data table
vimdoc.insert = function (data)
	---+

	table.insert(vimdoc.content, data);

	if not vimdoc.sorted[data.class] then
		vimdoc.sorted[data.class] = {};
	end

	table.insert(vimdoc.sorted[data.class], data);

	---_
end

--- Function arguments.
---@param buffer integer
---@param text string[]
---@param range node.range
vimdoc.argument = function (buffer, _, text, range)
	---+

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__argument
	vimdoc.insert({
		class = "vimdoc_argument",
		label = text[1]:gsub("[%{%}]", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Vimdoc code blocks.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range node.range
vimdoc.code_block = function (buffer, TSNode, text, range)
	---+

	local first_child = TSNode:named_child(0);
	local language;

	if first_child:type() == "language" then
		language = vim.treesitter.get_node_text(first_child, buffer):gsub("^%>", "");
	end

	local function top_stat ()
		local before = vim.api.nvim_buf_get_text(buffer, range.row_start, 0, range.row_start, range.col_start, {})[1];
		local use_virt = before:match("^%s*$") == nil;

		if range.row_start - 1 < 0 then
			vim.print(before)
			return use_virt, use_virt;
		elseif range.col_start == 0 then
			local top = vim.api.nvim_buf_get_lines(buffer, range.row_start - 1, range.row_start, false)[1];
			return use_virt, top:match("^%s*$") == nil;
		else
			return use_virt, before:match("^%s*$") == nil;
		end

	end

	local function bottom_stat ()
		local after = vim.api.nvim_buf_get_text(buffer, range.row_end, 0, range.row_end, -1, {})[1]:gsub("^%<", "");
		local use_virt = after:match(".+") ~= nil;

		if range.row_end + 1 > vim.api.nvim_buf_line_count(buffer) - 1 then
			return use_virt, false;
		elseif range.col_start == 0 then
			local bottom = vim.api.nvim_buf_get_lines(buffer, range.row_end, range.row_end + 1, false)[1];

			return use_virt, bottom:match("^%s*$") == nil;
		else
			return use_virt, after:match("^%s*$") == nil;
		end
	end

	---@type vimdoc.__code_block
	vimdoc.insert({
		class = "vimdoc_code_block",
		language = language,

		top_border = { top_stat() },
		bottom_border = { bottom_stat() },

		text = text,
		range = range
	});

	---_
end

--- Level 1/2 headings.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range heading.range
vimdoc.heading = function (buffer, TSNode, text, range)
	---+${lua}

	if not text[2] or text[2] == "" then
		vimdoc.hr(buffer, TSNode:named_child(0), { text[1] }, {
			row_start = range.row_start,
			col_start = 0,

			row_end = range.row_start + 1,
			col_end = #text[1]
		});
		return;
	elseif text[2]:match("^%s*vim%:.+") then
		vimdoc.hr(buffer, TSNode:named_child(0), { text[1] }, {
			row_start = range.row_start,
			col_start = 0,

			row_end = range.row_start + 1,
			col_end = #text[1]
		});
		vimdoc.modeline(buffer, TSNode:named_child(1), { text[2] }, {
			row_start = range.row_start + 1,
			col_start = 0,

			row_end = range.row_start + 1,
			col_end = #text[2]
		});
		return;
	end

	local desc, tags = "", {};

	if text[2]:match("%*.+%*") then
		local tmp = text[2];

		for tag in text[2]:gmatch("%*%S+%*") do
			local _, ts, te = tmp:find(tag, 1, true);

			table.insert(tags, {
				tag = tag,

				col_start = ts,
				col_end = te
			});
			tmp = tmp:gsub(utils.escape_string(tag), function (s)
				return string.rep(" ", s:len());
			end,1)
		end

		local wB, _ = tmp:match("^%s*"):len(), tmp:match("%s*$"):len();

		desc = tmp:gsub("^%s*", ""):gsub("%s*$", "");

		range.desc_start = wB;
		range.desc_end = wB + #desc;
	else
		desc = text[2];

		range.desc_start = 0;
		range.desc_end = #text[2];
	end

	---@type vimdoc.__heading
	vimdoc.insert({
		class = "vimdoc_heading",
		level = text[1]:match("%-") and 2 or 1,

		description = desc,
		tags = tags,
		delimiter = text[1],

		text = text,
		range = range
	});
	---_
end

--- Level 3/4 headings.
---@param text string[]
---@param range heading.range
vimdoc.heading_no_delim = function (_, _, text, range)
	---+

	if text[1]:match("%*%S-%*") then
		return;
	elseif text[1]:match("[%-\t]") then
		return;
	elseif range.col_start ~= 0 then
		return;
	end

	---@type vimdoc.__heading
	vimdoc.insert({
		class = "vimdoc_heading_no_delim",
		level = text[1]:match("%~$") and 4 or 3,

		text = text,
		range = range
	});

	---_
end

--- Horizontal rules.
---@param text string[]
---@param range node.range
vimdoc.hr = function (_, _, text, range)
	---+

	---@type vimdoc.__hr
	vimdoc.insert({
		class = "vimdoc_hr",

		text = text,
		range = range
	});

	---_
end

--- Inline codes.
---@param buffer integer
---@param text string[]
---@param range node.range
vimdoc.inline_code = function (buffer, _, text, range)
	---+

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__inline_code
	vimdoc.insert({
		class = "vimdoc_inline_code",
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Keycodes.
---@param buffer integer
---@param text string[]
---@param range node.range
vimdoc.keycode = function (buffer, _, text, range)
	---+

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__keycode
	vimdoc.insert({
		class = "vimdoc_keycode",
		label = text[1]:gsub("[%<%>]", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Vim modeline.
---@param text string[]
---@param range node.range
vimdoc.modeline = function (_, _, text, range)
	---+

	local options = {};
	local modeline = text[1]:gsub("^vim%:", ""):gsub("^vi%:", ""):gsub("^ex%:", "");
	modeline = modeline:gsub("%s", ":");

	if modeline:match("%:$") == nil then
		modeline = modeline .. ":";
	end

	for part in modeline:gmatch("([^%:]+)%:") do
		local opt, val;


		if part:match("%=") then
			opt, val = part:match("^([^%=]+)%=(.-)$")
		elseif part:match("^no") then
			opt = part:gsub("^no", "");
			val = false;
		else
			opt = part;
			val = true;
		end

		local opts = vim.fn.getcompletion(opt, "option");

		if #opts > 0 then
			opt = opts[1];
		end

		if type(val) == "string" then
			if val == "yes" then
				val = true;
			elseif val == "no" then
				val = false;
			elseif tonumber(val) then
				val = tonumber(val);
			end
		end

		table.insert(options, {
			option = opt,
			value = val
		});
	end

	---@type vimdoc.__modeline
	vimdoc.insert({
		class = "vimdoc_modeline",
		options = options,

		text = text,
		range = range
	});

	---_
end

--- Notes.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range node.range
vimdoc.note = function (buffer, TSNode, text, range)
	---+

	local parent = TSNode:parent();
	local types = { "tag", "taglink", "optionlink", "argument", "codespan" };

	while parent do
		if vim.list_contains(types, parent:type()) then
			return;
		end

		parent = parent:parent();
	end

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__note
	vimdoc.insert({
		class = "vimdoc_note",
		label = text[1]:gsub("%:$", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Option link.
---@param buffer integer
---@param text string[]
---@param range node.range
vimdoc.optionlink = function (buffer, _, text, range)
	---+

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__optionlink
	vimdoc.insert({
		class = "vimdoc_optionlink",
		label = text[1]:gsub("%'", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Help tag.
---@param buffer integer
---@param text string[]
---@param range node.range
vimdoc.tag = function (buffer, _, text, range)
	---+

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__tag
	vimdoc.insert({
		class = "vimdoc_tag",
		tag = text[1]:gsub("%*", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Link to a help tag.
---@param buffer integer
---@param text string[]
---@param range node.range
vimdoc.taglink = function (buffer, _, text, range)
	---+

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__taglink
	vimdoc.insert({
		class = "vimdoc_taglink",
		label = text[1]:gsub("%|", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Word processor.
---@param text string[]
---@param range node.range
vimdoc.hl = function (buffer, _, text, range)
	---+

	if vim.fn.hlexists(text[1]) == 0 then
		return;
	end

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	---@type vimdoc.__hl
	vimdoc.insert({
		class = "vimdoc_hl",
		group_name = text[1],
		after = after:match("^	+"),

		text = text,
		range = range
	});

	---_
end

--- Url links.
---@param text string[]
---@param range node.range
vimdoc.url = function (_, _, text, range)
	vimdoc.insert({
		class = "vimdoc_url",
		label = text[1],

		text = text,
		range = range
	});
end

--- Vimdoc parser.
---@param buffer integer
---@param TSTree table
---@param from integer?
---@param to integer?
---@return table[]
---@return table
vimdoc.parse = function (buffer, TSTree, from, to)
	---+${lua}

	-- Clear the previous contents
	vimdoc.sorted = {};
	vimdoc.content = {};

	local scanned_queries = vim.treesitter.query.parse("vimdoc", [[
		([(h1)
		  (h2)
			] @vimdoc.heading)

		([(h3)
		  (column_heading)
			]@vimdoc.heading_no_delim)

		(line
			.
			(word) @vimdoc.hl
			(#match? @vimdoc.hl "^[a-zA-Z0-9l_\.@\-]*$"))

		((tag) @vimdoc.tag)

		((taglink) @vimdoc.taglink)

		((optionlink) @vimdoc.optionlink)

		((keycode) @vimdoc.keycode)

		((note) @vimdoc.note)

		((argument) @vimdoc.argument)

		((codespan) @vimdoc.inline_code)

		((codeblock) @vimdoc.code_block)

		((modeline) @vimdoc.modeline)

		((url) @vimdoc.url)
	]]);

	for capture_id, capture_node, _, _ in scanned_queries:iter_captures(TSTree:root(), buffer, from, to) do
		local capture_name = scanned_queries.captures[capture_id];

		if not capture_name:match("^vimdoc%.") then
			goto continue
		end

		---@type string?
		local capture_text = vim.treesitter.get_node_text(capture_node, buffer);
		local r_start, c_start, r_end, c_end = capture_node:range();

		if capture_text == nil then
			goto continue;
		end

		if not capture_text:match("\n$") then
			capture_text = capture_text .. "\n";
		end

		local lines = {};

		for line in capture_text:gmatch("(.-)\n") do
			table.insert(lines, line);
		end

		local success, error = pcall(
			vimdoc[capture_name:gsub("^vimdoc%.", "")],

			buffer,
			capture_node,
			lines,
			{
				row_start = r_start,
				col_start = c_start,

				row_end = r_end,
				col_end = c_end
			}
		);

		if success == false then
			require("helpview.health").notify("trace", {
				level = 4,
				message = error
			});
		end

	    ::continue::
	end

	return vimdoc.content, vimdoc.sorted;
	---_
end

return vimdoc;
