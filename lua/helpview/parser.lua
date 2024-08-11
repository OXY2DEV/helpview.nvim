local parser = {};

parser.parsed_content = {};

parser.ignore_opts = { "all" };

parser.get_opt = function (text)
	text = text:gsub("^no", "");
	local out = vim.fn.getcompletion(text or "", "option");

	for _, item in ipairs(out) do
		if not vim.list_contains(parser.ignore_opts, item) then
			return vim.api.nvim_get_option_info2(item, {});
		end
	end
end

parser.get_str_type = function (str)
	if str:match("^true$") or str:match("^false$") then
		return "boolean";
	elseif str:match("^%d+$") then
		return "number";
	else
		return "string";
	end
end

parser.vimdoc = function (buffer, TStree, from, to)
	local scanned_queies = vim.treesitter.query.parse("vimdoc", [[
		([(h1)
		  (h2)
			] @heading)

		([(h3)
		  (column_heading)
			]@heading_no_delimiter)

		((word) @may_be_hl)

		((tag) @tag)

		((taglink) @mention_link)

		((optionlink) @option_link)

		((keycode) @key_code)

		((note) @note)

		((argument) @arg)

		((codespan) @inline_code)

		((codeblock) @code_block)

		((modeline) @modeline)
	]]);

	for capture_id, capture_node, _, _ in scanned_queies:iter_captures(TStree:root(), buffer, from, to) do
		local capture_name = scanned_queies.captures[capture_id];
		local capture_text = vim.treesitter.get_node_text(capture_node, buffer);
		local row_start, col_start, row_end, col_end = capture_node:range();

		if capture_name == "heading" then
			local delimiter = capture_node:named_child(0); --- The ==== part
			local heading = capture_node:named_child(1);

			local h_start, h_c_start, h_end, h_c_end = heading:range();
			local h_txt = vim.api.nvim_buf_get_lines(buffer, h_start, h_start + 1, false)[1];

			local modelines = vim.g.modelines or 5;
			local buf_lines = vim.api.nvim_buf_line_count(buffer);

			if h_txt == "" then
				local d_col_end = vim.fn.strchars(vim.api.nvim_buf_get_lines(buffer, row_start, row_start + 1, false)[1] or "");

				table.insert(parser.parsed_content, {
					type = "horizontal_rule",
					text = vim.treesitter.get_node_text(delimiter, buffer),

					row_start = row_start,
					col_start = col_start,

					row_end = row_end,
					col_end = d_col_end
				});
			elseif h_txt:match("%s*vim:([^:]*):") and (h_start <= modelines or h_start >= (buf_lines - modelines)) then
				local d_col_end = vim.fn.strchars(vim.api.nvim_buf_get_lines(buffer, row_start, row_start + 1, false)[1] or "");

				table.insert(parser.parsed_content, {
					type = "horizontal_rule",
					text = delimiter,

					row_start = row_start,
					col_start = col_start,

					row_end = row_start,
					col_end = d_col_end
				});

				local options = {};

				for part in h_txt:gmatch("([^:]*)") do
					if part:match("(%S*)=(%S*)") then
						for opt, _ in part:gmatch("(%S*)=(%S*)") do
							table.insert(options, parser.get_opt(opt))
						end
					elseif part and part ~= "" and not part:match("^%s*(vim)") then
						table.insert(options, parser.get_opt(part))
					end
				end

				table.insert(parser.parsed_content, {
					type = "modeline",
					options = options,

					row_start = h_start,
					col_start = h_c_start,

					row_end = h_end,
					col_end = h_c_end
				});
			else
				table.insert(parser.parsed_content, {
					type = "heading",
					level = tonumber(capture_node:type():sub(2)),

					delimiter = vim.treesitter.get_node_text(delimiter, buffer),
					text = h_txt,

					row_start = row_start,
					col_start = col_start,

					__r_end = row_end - 1,

					row_end = row_end,
					col_end = col_end
				})
			end
		elseif capture_name == "heading_no_delimiter" then
			local heading = capture_node:named_child(0);

			local h_start = heading:range();
			local h_txt = vim.api.nvim_buf_get_lines(buffer, h_start, h_start + 1, false)[1];

			local level = 3;

			if capture_node:type() == "column_heading" then
				level = 4;
			end

			table.insert(parser.parsed_content, {
				type = "heading",
				level = level,

				delimiter = nil,
				text = h_txt,

				row_start = row_start,
				col_start = col_start,

				row_end = row_end - 1,
				col_end = col_end
			})
		elseif capture_name == "may_be_hl" then
			if not capture_text:match("^%$(.*)%$$") then
				goto notHl;
			end

			table.insert(parser.parsed_content, {
				type = "highlight_group",
				name = capture_text:gsub("%$", ""),

				text = capture_text:gsub("%$", ""),

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end
			});

			::notHl::
		elseif capture_name == "code_block" then
			local language_node = capture_node:named_child(0);
			local codes = vim.api.nvim_buf_get_lines(buffer, row_start + 1, row_end, false);

			local line_lens = {};
			local max_line_len = 0;

			local indent = 0;

			for _, line in ipairs(codes) do
				local wh = line:match("(%s*).*");
				local content = line:match("%s*(.*)");

				table.insert(line_lens, vim.fn.strchars(content));

				if vim.fn.strchars(content) > max_line_len then
					max_line_len = vim.fn.strchars(content);
				end

				if vim.fn.strdisplaywidth(wh) > indent then
					indent = vim.fn.strdisplaywidth(wh);
				end
			end

			table.insert(parser.parsed_content, {
				type = "code_block",

				language = language_node ~= nil and language_node:type() == "language" and vim.treesitter.get_node_text(language_node, buffer) or "",
				lines = codes,

				indent = indent,

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end
			});
		elseif capture_name == "tag" then
			if row_start == 0 then
				local line = capture_node:parent();
				local complete_line = vim.treesitter.get_node_text(line, buffer)
				row_start, col_start, row_end, col_end = line:range();

				table.insert(parser.parsed_content, {
					type = "title",

					title = capture_text:gsub("*", ""),
					description = complete_line:match(capture_text .. "*%s*(.*)"),

					row_start = row_start,
					col_start = col_start,

					row_end = row_end,
					col_end = col_end
				})
			else
				table.insert(parser.parsed_content, {
					type = "tag",
					text = capture_text:gsub("*", ""),

					row_start = row_start,
					col_start = col_start,

					row_end = row_end,
					col_end = col_end
				})
			end
		elseif capture_name == "mention_link" then
			table.insert(parser.parsed_content, {
				type = "link",
				text = capture_text:gsub("%|", ""),

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end
			})
		elseif capture_name == "option_link" then
			table.insert(parser.parsed_content, {
				type = "option_link",
				text = capture_text:gsub("[']", ""),

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end
			})
		elseif capture_name == "inline_code" then
			table.insert(parser.parsed_content, {
				type = "inline_code",
				text = capture_text:gsub("`", ""),

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end
			})
		elseif capture_name == "key_code" then
			table.insert(parser.parsed_content, {
				type = "key_code",
				text = capture_text:gsub("[%<%>]", ""),
				extracted = capture_text:match("%<(.-)%>"),

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end
			})
		elseif capture_name == "arg" then
			table.insert(parser.parsed_content, {
				type = "argument",
				text = capture_text:gsub("[%{%}]", ""),

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end
			})
		elseif capture_name == "note" then
			local note_text = capture_text:gsub(":", "");

			table.insert(parser.parsed_content, {
				type = "note",
				text = note_text,

				row_start = row_start,
				col_start = col_start,

				row_end = row_end,
				col_end = col_end == #note_text and col_end + 1 or col_end
			})
		elseif capture_name == "modeline" then
			local options = {};
			local full_line = vim.api.nvim_buf_get_lines(buffer, row_start, row_start + 1, false)[1];

			for part in capture_text:gmatch("([^:]*)") do
				if part:match("(%S*)=(%S*)") then
					for opt, _ in part:gmatch("(%S*)=(%S*)") do
						table.insert(options, parser.get_opt(opt));
					end
				elseif part ~= "" and not part:match("^%s*(vim)") then
					table.insert(options, parser.get_opt(part))
				end
			end

			table.insert(parser.parsed_content, {
				type = "modeline",
				options = options,

				row_start = row_start,
				col_start = 0,

				row_end = row_end,
				col_end = vim.fn.strchars(full_line)
			});
		end
	end
end

parser.init = function (buffer, from, to)
	local root_parser = vim.treesitter.get_parser(buffer);
	root_parser:parse();

	parser.parsed_content = {};

	root_parser:for_each_tree(function (TStree, language_tree)
		local tree_language = language_tree:lang();

		if tree_language == "vimdoc" then
			parser.vimdoc(buffer, TStree, from, to);
		end
	end);

	return parser.parsed_content;
end

return parser;
