local vimdoc = {};
local utils = require("helpview.utils");

--- Queried contents
---@type table[]
vimdoc.content = {};

--- Queried contents, but sorted
vimdoc.sorted = {}

vimdoc.insert = function (data)
	table.insert(vimdoc.content, data);

	if not vimdoc.sorted[data.class] then
		vimdoc.sorted[data.class] = {};
	end

	table.insert(vimdoc.sorted[data.class], data);
end

--- YAML property.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range node.range
vimdoc.property = function (buffer, TSNode, text, range)
	---+${lua}

	local key, value = TSNode:field("key")[1], TSNode:field("value")[1];

	local key_text = key and vim.treesitter.get_node_text(key, buffer) or nil;
	local value_text = value and vim.treesitter.get_node_text(value, buffer) or nil;

	--- Checks if {str} matches any of the
	--- date patterns.
	---@param str string?
	---@return boolean
	local function is_date (str)
		---+${lua}
		if type(str) ~= "string" then
			return false;
		end

		local spec = require("markview.spec");
		local formats = spec.get({ "experimental", "date_formats" }, { fallback = {} });

		for _, format in ipairs(formats) do
			if string.match(str, format) then
				return true;
			end
		end

		return false;
		---_
	end

	--- Checks if {str} matches any of the
	--- date & time patterns.
	---@param str string?
	---@return boolean
	local function is_date_time (str)
		---+${lua}
		if type(str) ~= "string" then
			return false;
		end

		local spec = require("markview.spec");
		local formats = spec.get({ "experimental", "date_time_formats" }, { fallback = {} });

		for _, format in ipairs(formats) do
			if string.match(str, format) then
				return true;
			end
		end

		return false;
		---_
	end

	--- Checks if this node contains
	--- a list.
	local function is_list()
		---+${lua}
		if type(value) ~= "table" then
			return false;
		elseif value:child(0) == nil then
			--- `value:` has no node.
			return false;
		elseif value:child(0):child(0) == nil then
			return false;
		elseif value:child(0):child(0):type() ~= "block_sequence" then
			return false;
		end

		return true;
		---_
	end

	local value_type = "unknown";

	if is_date_time(value_text) == true then
		value_type = "date_&_time";
	elseif is_date(value_text) == true then
		value_type = "date";
	elseif is_list() == true then
		value_type = "list";
	elseif tonumber(value_text) ~= nil then
		value_type = "number";
	elseif value_text == "true" or value_text == "false" then
		value_type = "checkbox";
	elseif type(value_text) == "string" then
		value_type = "text";
	elseif value_type == nil then
		value_type = "nil";
	end

	if range.col_end == 0 then
		range.row_end = range.row_start + #text - 1;
	end

	---@type __yaml.properties
	yaml.insert({
		class = "yaml_property",
		type = value_type,

		key = key_text,
		value = value_text,

		text = text,
		range = range
	});
	---_
end

-- return yaml;

---+${lua}
		-- if capture_name == "heading" then
		-- 	local delimiter = capture_node:named_child(0); --- The ==== part
		-- 	local heading = capture_node:named_child(1);
		--
		-- 	local h_start, h_c_start, h_end, h_c_end = heading:range();
		-- 	local h_txt = vim.api.nvim_buf_get_lines(buffer, h_start, h_start + 1, false)[1];
		--
		-- 	local modelines = vim.g.modelines or 5;
		-- 	local buf_lines = vim.api.nvim_buf_line_count(buffer);
		--
		-- 	if h_txt == "" then
		-- 		local d_col_end = vim.fn.strchars(vim.api.nvim_buf_get_lines(buffer, row_start, row_start + 1, false)[1] or "");
		--
		-- 		table.insert(parser.parsed_content, {
		-- 			type = "horizontal_rule",
		-- 			text = vim.treesitter.get_node_text(delimiter, buffer),
		--
		-- 			row_start = row_start,
		-- 			col_start = col_start,
		--
		-- 			row_end = row_end,
		-- 			col_end = d_col_end
		-- 		});
		-- 	elseif h_txt:match("%s*vim:([^:]*):") and (h_start <= modelines or h_start >= (buf_lines - modelines)) then
		-- 		local d_col_end = vim.fn.strchars(vim.api.nvim_buf_get_lines(buffer, row_start, row_start + 1, false)[1] or "");
		--
		-- 		table.insert(parser.parsed_content, {
		-- 			type = "horizontal_rule",
		-- 			text = delimiter,
		--
		-- 			row_start = row_start,
		-- 			col_start = col_start,
		--
		-- 			row_end = row_start,
		-- 			col_end = d_col_end
		-- 		});
		--
		-- 		local options = {};
		--
		-- 		for part in h_txt:gmatch("([^:]*)") do
		-- 			if part:match("(%S*)=(%S*)") then
		-- 				for opt, _ in part:gmatch("(%S*)=(%S*)") do
		-- 					table.insert(options, parser.get_opt(opt))
		-- 				end
		-- 			elseif part and part ~= "" and not part:match("^%s*(vim)") then
		-- 				table.insert(options, parser.get_opt(part))
		-- 			end
		-- 		end
		--
		-- 		table.insert(parser.parsed_content, {
		-- 			type = "modeline",
		-- 			options = options,
		--
		-- 			row_start = h_start,
		-- 			col_start = h_c_start,
		--
		-- 			row_end = h_end,
		-- 			col_end = h_c_end
		-- 		});
		-- 	else
		-- 		table.insert(parser.parsed_content, {
		-- 			type = "heading",
		-- 			level = tonumber(capture_node:type():sub(2)),
		--
		-- 			delimiter = vim.treesitter.get_node_text(delimiter, buffer),
		-- 			text = h_txt,
		--
		-- 			row_start = row_start,
		-- 			col_start = col_start,
		--
		-- 			__r_end = row_end - 1,
		--
		-- 			row_end = row_end,
		-- 			col_end = col_end
		-- 		})
		-- 	end
		-- elseif capture_name == "heading_no_delimiter" then
		-- 	local heading = capture_node:named_child(0);
		--
		-- 	local h_start = heading:range();
		-- 	local h_txt = vim.api.nvim_buf_get_lines(buffer, h_start, h_start + 1, false)[1];
		--
		-- 	local level = 3;
		--
		-- 	if capture_node:type() == "column_heading" then
		-- 		level = 4;
		-- 	end
		--
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "heading",
		-- 		level = level,
		--
		-- 		delimiter = nil,
		-- 		text = h_txt,
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end - 1,
		-- 		col_end = col_end
		-- 	})
		-- elseif capture_name == "may_be_hl" then
		-- 	if not capture_text:match("^%$(.*)%$$") then
		-- 		goto notHl;
		-- 	end
		--
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "highlight_group",
		-- 		name = capture_text:gsub("%$", ""),
		--
		-- 		text = capture_text:gsub("%$", ""),
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end
		-- 	});
		--
		-- 	::notHl::
		-- elseif capture_name == "code_block" then
		-- 	local language_node = capture_node:named_child(0);
		-- 	local codes = vim.api.nvim_buf_get_lines(buffer, row_start + 1, row_end, false);
		--
		-- 	local line_lens = {};
		-- 	local max_line_len = 0;
		--
		-- 	local indent = 0;
		--
		-- 	for _, line in ipairs(codes) do
		-- 		local wh = line:match("(%s*).*");
		-- 		local content = line:match("%s*(.*)");
		--
		-- 		table.insert(line_lens, vim.fn.strchars(content));
		--
		-- 		if vim.fn.strchars(content) > max_line_len then
		-- 			max_line_len = vim.fn.strchars(content);
		-- 		end
		--
		-- 		if vim.fn.strdisplaywidth(wh) > indent then
		-- 			indent = vim.fn.strdisplaywidth(wh);
		-- 		end
		-- 	end
		--
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "code_block",
		--
		-- 		language = language_node ~= nil and language_node:type() == "language" and vim.treesitter.get_node_text(language_node, buffer) or "",
		-- 		lines = codes,
		--
		-- 		indent = indent,
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end
		-- 	});
		-- elseif capture_name == "tag" then
		-- 	if row_start == 0 then
		-- 		local line = capture_node:parent();
		-- 		local complete_line = vim.treesitter.get_node_text(line, buffer)
		-- 		row_start, col_start, row_end, col_end = line:range();
		--
		-- 		table.insert(parser.parsed_content, {
		-- 			type = "title",
		--
		-- 			title = capture_text:gsub("*", ""),
		-- 			description = complete_line:match(capture_text .. "*%s*(.*)"),
		--
		-- 			row_start = row_start,
		-- 			col_start = col_start,
		--
		-- 			row_end = row_end,
		-- 			col_end = col_end
		-- 		})
		-- 	else
		-- 		table.insert(parser.parsed_content, {
		-- 			type = "tag",
		-- 			text = capture_text:gsub("*", ""),
		--
		-- 			row_start = row_start,
		-- 			col_start = col_start,
		--
		-- 			row_end = row_end,
		-- 			col_end = col_end
		-- 		})
		-- 	end
		-- elseif capture_name == "mention_link" then
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "link",
		-- 		text = capture_text:gsub("%|", ""),
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end
		-- 	})
		-- elseif capture_name == "option_link" then
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "option_link",
		-- 		text = capture_text:gsub("[']", ""),
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end
		-- 	})
		-- elseif capture_name == "inline_code" then
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "inline_code",
		-- 		text = capture_text:gsub("`", ""),
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end
		-- 	})
		-- elseif capture_name == "key_code" then
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "key_code",
		-- 		text = capture_text:gsub("[%<%>]", ""),
		-- 		extracted = capture_text:match("%<(.-)%>"),
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end
		-- 	})
		-- elseif capture_name == "arg" then
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "argument",
		-- 		text = capture_text:gsub("[%{%}]", ""),
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end
		-- 	})
		-- elseif capture_name == "note" then
		-- 	local note_text = capture_text:gsub(":", "");
		--
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "note",
		-- 		text = note_text,
		--
		-- 		row_start = row_start,
		-- 		col_start = col_start,
		--
		-- 		row_end = row_end,
		-- 		col_end = col_end == #note_text and col_end + 1 or col_end
		-- 	})
		-- elseif capture_name == "modeline" then
		-- 	local options = {};
		-- 	local full_line = vim.api.nvim_buf_get_lines(buffer, row_start, row_start + 1, false)[1];
		--
		-- 	for part in capture_text:gmatch("([^:]*)") do
		-- 		if part:match("(%S*)=(%S*)") then
		-- 			for opt, _ in part:gmatch("(%S*)=(%S*)") do
		-- 				table.insert(options, parser.get_opt(opt));
		-- 			end
		-- 		elseif part ~= "" and not part:match("^%s*(vim)") then
		-- 			table.insert(options, parser.get_opt(part))
		-- 		end
		-- 	end
		--
		-- 	table.insert(parser.parsed_content, {
		-- 		type = "modeline",
		-- 		options = options,
		--
		-- 		row_start = row_start,
		-- 		col_start = 0,
		--
		-- 		row_end = row_end,
		-- 		col_end = vim.fn.strchars(full_line)
		-- 	});
		-- end
---_


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
		--- *tags* hijdjdjd 
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

vimdoc.heading_no_delim = function (_, _, text, range)
	--- ^HEADING

	if text[1]:match("%*%S-%*") then
		return;
	elseif text[1]:match("[%-\t]") then
		return;
	elseif range.col_start ~= 0 then
		return;
	end

	vimdoc.insert({
		class = "vimdoc_heading_no_delim",
		level = text[1]:match("%~$") and 4 or 3,

		text = text,
		range = range
	});
end

vimdoc.hr = function (_, _, text, range)
	vimdoc.insert({
		class = "vimdoc_hr",

		text = text,
		range = range
	});
end

vim.word = function (_, _, text, range)
	if vim.fn.hlexists(text[1]) then
		--- Highlight group name.
		vimdoc.insert({
			class = "vimdoc_hl",
			group_name = text[1],

			text = text,
			range = range
		});
	end
end

vimdoc.tag = function (buffer, _, text, range)
	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	vimdoc.insert({
		class = "vimdoc_tag",
		tag = text[1]:gsub("%*", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});
end

vimdoc.taglink = function (buffer, _, text, range)
	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	vimdoc.insert({
		class = "vimdoc_taglink",
		label = text[1]:gsub("%|", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});
end

vimdoc.optionlink = function (buffer, _, text, range)
	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	vimdoc.insert({
		class = "vimdoc_optionlink",
		label = text[1]:gsub("%|", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});
end

vimdoc.keycode = function (buffer, _, text, range)
	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	vimdoc.insert({
		class = "vimdoc_keycode",
		label = text[1]:gsub("%|", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});
end

vimdoc.note = function (buffer, TSNode, text, range)
	local parent = TSNode:parent();
	local types = { "tag", "taglink", "optionlink", "argument", "codespan" };

	while parent do
		if vim.list_contains(types, parent:type()) then
			return;
		end

		parent = parent:parent();
	end

	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	vimdoc.insert({
		class = "vimdoc_note",
		label = text[1]:gsub("%|", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});
end

vimdoc.argument = function (buffer, _, text, range)
	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	vimdoc.insert({
		class = "vimdoc_argument",
		label = text[1]:gsub("[%{%}]", ""),
		after = after:match("^	+"),

		text = text,
		range = range
	});
end

vimdoc.inline_code = function (buffer, _, text, range)
	local after = vim.api.nvim_buf_get_text(buffer, range.row_start, range.col_end, range.row_start, -1, {})[1] or "";

	vimdoc.insert({
		class = "vimdoc_inline_code",
		after = after:match("^	+"),

		text = text,
		range = range
	});
end

vimdoc.code_block = function (buffer, TSNode, text, range)
	local first_child = TSNode:named_child(0);
	local language;

	if first_child:type() == "language" then
		language = vim.treesitter.get_node_text(first_child, buffer):gsub("^%>", "");
	end

	local use_virt_line = false;

	if range.col_start ~= 0 then
		local before = vim.api.nvim_buf_get_text(buffer, range.row_start, 0, range.row_start, range.col_start, {})[1] or "";

		if before:match("%S") then
			use_virt_line = true;
		end
	end

	vimdoc.insert({
		class = "vimdoc_code_block",
		language = language,
		use_virt_line = use_virt_line,

		text = text,
		range = range
	});
end

vimdoc.modeline = function (buffer, TSNode, text, range)
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

	vimdoc.insert({
		class = "vimdoc_modeline",
		options = options,

		text = text,
		range = range
	});
end

--- YAML parser.
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

		((word) @vimdoc.word
			(#match? @vimdoc.word "^\\w\\+$"))

		((tag) @vimdoc.tag)

		((taglink) @vimdoc.taglink)

		((optionlink) @vimdoc.optionlink)

		((keycode) @vimdoc.keycode)

		((note) @vimdoc.note)

		((argument) @vimdoc.argument)

		((codespan) @vimdoc.inline_code)

		((codeblock) @vimdoc.code_block)

		((modeline) @vimdoc.modeline)
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
		-- if error then
		-- 	vim.print(error)
		-- end

		if success == false then
			-- require("markview.health").notify("trace", {
			-- 	level = 4,
			-- 	message = error
			-- });
		end

	    ::continue::
	end

	return vimdoc.content, vimdoc.sorted;
	---_
end

return vimdoc;
