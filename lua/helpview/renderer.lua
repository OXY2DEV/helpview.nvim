local renderer = {};
local health = require("helpview.health");

renderer.vimdoc = require("helpview.renderers.vimdoc");

renderer.cache = {};

renderer.__filter_cache = {
	config = nil,
	result = nil
};

renderer.option_maps = {
	---+${lua}
	vimdoc = {
		arguments = { "vimdoc_argument" },
		headings = { "vimdoc_heading" },
		code_blocks = { "vimdoc_code_block" },
		highlight_groups = { "vimdoc_hl" },
		horizontal_rules = { "vimdoc_hr" },
		inline_codes = { "vimdoc_inline_code" },
		keycodes = { "vimdoc_keycode" },
		modelines = { "vimdoc_modeline" },
		notes = { "vimdoc_note" },
		optionlinks = { "vimdoc_optionlink" },
		tags = { "vimdoc_tag" },
		tag_links = { "vimdoc_taglink" },
		urls = { "vimdoc_url" }
	}
	---_
};

--- Creates node class filters for hybrid mode.
---@param filter preview.ignore?
---@return { [string]: string[] }
local create_filter = function (filter)
	---+${lua}
	local spec = require("helpview.spec");

	--- Ignore queries.
	---@type preview.ignore
	local filters = filter or spec.get({ "preview", "ignore_previews" }, { fallback = {}, ignore_enable = true });

	--- To save time, do not recalculate these if the
	--- configuration hasn't changed.
	if vim.deep_equal(renderer.__filter_cache.config, filters) == true then
		--- Configuration has most likely not changed.
		--- Return the cached value.
		return renderer.__filter_cache.result;
	end

	--- Resulting filter.
	local _f = {};

	--- Checks if a value is valid by matching all
	--- the provided queries against it.
	---@param value string
	---@param queries string[]
	---@return boolean
	local is_valid = function (value, queries)
		---+${lua}

		for q, query in ipairs(queries or {}) do
			--- Queries that were already passed.
			local passed = vim.list_slice(queries, 0, q - 1);

			if string.match(query, "^%!") then
				if value == string.sub(query, 2) then
					--- Part of negation query.
					return false;
				elseif vim.list_contains(passed, value) then
					--- Already part of the query.
					return true;
				end
			elseif value == query then
				--- Valid value.
				return true;
			else
				--- Invalid value.
				return false;
			end
		end

		--- All conditions matched!
		return true;
		---_
	end

	--- Creates a list of valid options for {language}.
	---@param language string
	---@param options string[]
	---@return string[]
	local function language_filter (language, options)
		---+${lua}

		---@type string[] Filters for this language.
		local queries = filters[language];

		if vim.islist(queries) == false then
			--- Filter is invalid.
			return options;
		elseif #queries == 0 then
			--- Filter is empty.
			return {};
		end

		---@type string[] Valid options.
		local _m = {};

		for _, item in ipairs(options) do
			if is_valid(item, queries) == true then
				table.insert(_m, item);
			end
		end

		return _m;
		---_
	end

	--- Registers a new entry to {language}.
	---@param language string
	---@param classes string[]
	local function register (language, classes)
		---+${lua}
		if vim.islist(_f[language]) == false then
			_f[language] = {};
		end

		for _, class in ipairs(classes or {}) do
			if type(class) == "string" and vim.list_contains(_f[language], class) == false then
				table.insert(_f[language], class);
			end
		end
		---_
	end

	for language, maps in pairs(renderer.option_maps) do
		--- Copy the values as we don't want to
		--- accidentally modify the mapping table.
		local valid_options = language_filter(language, vim.tbl_keys(maps));

		if vim.islist(_f[language]) == false then
			_f[language] = {};
		end

		for _, option in ipairs(valid_options) do
			local nodes = maps[option];
			register(language, nodes);
		end
	end

	--- Cache values.
	renderer.__filter_cache.config = filters;
	renderer.__filter_cache.result = _f;

	return _f;
	---_
end

--- Range modifiers for various nodes.
---@type { [string]: fun(range: node.range): node.range }
renderer.range_modifiers = {
	["vimdoc_hr"] = function (range)
		return {
			row_start = range.row_start,
			row_end = range.row_start,

			col_start = range.col_start,
			col_end = range.col_end
		};
	end
};

--- Fixes node ranges for `hybrid mode`.
---@param class string
---@param range node.range
---@return node.range
renderer.fix_range = function (class, range)
	if renderer.range_modifiers[class] == nil then
		return range;
	end

	return renderer.range_modifiers[class](range);
end

--- Filters provided content.
--- [Used for hybrid mode]
---@param content table
---@param filter table?
---@param clear [ integer, integer ]
---@return table
renderer.filter = function (content, filter, clear)
	---+${lua}

	--- Checks if {pos} is inside of {range}.
	---@param range node.range
	---@param pos [ integer, integer ]
	---@return boolean
	local within = function (range, pos)
		---+${lua}
		if type(range) ~= "table" then
			return false;
		elseif type(range.row_start) ~= "number" or type(range.row_end) ~= "number" then
			return false;
		elseif vim.islist(pos) == false then
			return false;
		elseif type(pos[1]) ~= "number" or type(pos[2]) ~= "number" then
			return false;
		elseif pos[1] >= range.row_start and pos[2] <= range.row_end then
			return true;
		end

		return false;
		---_
	end

	---@type [ integer, integer ] Range to clear.
	local clear_range = vim.deepcopy(clear);

	--- Updates the range to clear.
	---@param new [ integer, integer ]
	local range_update = function (new)
		---+${lua}
		if new[1] <= clear_range[1] and new[2] >= clear_range[2] then
			clear_range[1] = new[1];
			clear_range[2] = new[2];
		end
		---_
	end

	--- Node filters.
	---@type preview.ignore
	local result_filters = create_filter(filter);

	---@type { [string]: table }
	local indexes = {};

	--- Create a range to clear.
	for lang, items in pairs(content) do
		---+${lua}

		--- Filter for this language.
		---@type string[]?
		local lang_filter = result_filters[lang];

		if lang_filter == nil then
			goto continue;
		end

		indexes[lang] = {};

		for n, node in ipairs(items) do
			if vim.list_contains(lang_filter, node.class) then
				local range = renderer.fix_range(node.class, node.range);
				table.insert(indexes[lang], { n, range, node.class });

				if within(node.range, clear_range) == true then
					range_update({ range.row_start, range.row_end });
				end
			end
		end

		::continue::
		---_
	end

	--- Remove the nodes inside the `clear_range`.
	for lang, references in pairs(indexes) do
		---+${lua}

		--- Amount of nodes removed in this language.
		--- Used for offsetting the index for later nodes.
		local removed = 0;

		for _, ref in ipairs(references) do
			local range = ref[2];

			if range.row_start >= clear_range[1] and range.row_end <= clear_range[2] then
				table.remove(content[lang], ref[1] - removed);
				removed = removed + 1;
			end
		end
		---_
	end

	return content;
	---_
end

--- Renders things
---@param buffer integer
renderer.render = function (buffer, parsed_content)
	---+${lua}

	renderer.cache = {};

	---+${lua, Announce start of rendering}
	---@type integer
	local start = vim.uv.hrtime();

	health.notify("trace", {
		level = 1,
		message = string.format("Rendering(main): %d", buffer)
	});
	health.__child_indent_in();
	---_

	for lang, content in pairs(parsed_content or {}) do
		if renderer[lang] then
			local c = renderer[lang].render(buffer, content);
			renderer.cache = vim.tbl_extend("force", renderer.cache, c or {});
		end
	end

	---+${lua, Announce end of main render}
	local post = vim.uv.hrtime();

	health.notify("trace", {
		level = 3,
		message = string.format("Render(main): %dms", (post - start) / 1e6)
	});
	---_

	for lang, content in pairs(renderer.cache) do
		if renderer[lang] then
			renderer[lang].post_render(buffer, content);
		end
	end

	---+${lua, Announce end of rendering}
	local now = vim.uv.hrtime();

	--- Announce end of post rendering.
	health.notify("trace", {
		level = 3,
		message = string.format("Render(post): %dms", (now - post) / 1e6)
	});

	health.__child_indent_de();
	health.notify("trace", {
		level = 3,
		message = string.format("Rendering(end, %dms): %d", (now - start) / 1e6, buffer)
	});
	---_

	---_
end

renderer.clear = function (buffer, from, to)
	local langs = { "vimdoc" };
	local start = vim.uv.hrtime();

	---+${lua, Announce start of clearing}
	health.notify("trace", {
		level = 1,
		message = string.format("Clearing: %d", buffer)
	});
	health.__child_indent_in();
	---_

	for _, lang in ipairs(langs) do
		if renderer[lang] then
			renderer[lang].clear(buffer, from, to);
		end
	end

	---+${lua, Announce end of clearing}
	local now = vim.uv.hrtime();

	health.__child_indent_de();
	health.notify("trace", {
		level = 3,
		message = string.format("Clearing(end, %dms): %d", (now - start) / 1e6, buffer)
	});
	---_
end

--- Gets the range of the given content.
---@param content table[]
---@return integer
---@return integer
renderer.get_range = function (content)
	---+

	local from, to = nil, nil;

	for _, lang_items in pairs(content) do
		for _, item in ipairs(lang_items) do
			local range = item.range;

			if not from then
				from = range.row_start;
			elseif range.row_start < from then
				from = range.row_start;
			end

			if not to then
				to = range.row_end;
			elseif range.row_end > from then
				to = range.row_end;
			end
		end
	end

	return from, to;

	---_
end

return renderer;
