local utils = {};

utils.get_component_width = function (config_table)
	if not config_table or config_table.enable == false then
		return 0;
	end

	return vim.fn.strchars(table.concat({
		config_table.corner_left or "",
		config_table.padding_left or "",
		config_table.icon or "",
		config_table.padding_right or "",
		config_table.corner_right or ""
	}));
end

utils.get_concealed_len = function (text, config_table)
	local len = string.len(text);

	for _ in text:gmatch("`(%S*)`") do
		len = len - 2;

		if config_table and config_table.inline_codes then
			len = len + utils.get_component_width(config_table.inline_codes);
		end
	end

	for _ in text:gmatch("*(%S*)*") do
		len = len - 2;

		if config_table and config_table.tags then
			len = len + utils.get_component_width(config_table.tags);
		end
	end

	for _ in text:gmatch("|(%S*)|") do
		len = len - 2;

		if config_table and config_table.links then
			len = len + utils.get_component_width(config_table.links);
		end
	end

	return len;
end

utils.get_display_width = function (text, shiftwidth)
	if not shiftwidth then
		shiftwidth = 4;
	end

	local width = 0;

	for char in text:gmatch(".") do
		if char == "	" then
			width = width + (shiftwidth - (width % shiftwidth));
		else
			width = width + 1;
		end
	end

	return width;
end

return utils;
