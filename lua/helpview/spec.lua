local spec = {};
local health = require("helpview.health");

--- Default configuration table.
---@type helpview.config
spec.default = {
	---+${lua}

	preview = {
		-- enable = false,
		modes = { "n", "c", "no" },
		max_buf_lines = 500,

		filetypes = { "help" },
		-- hybrid_modes = { "n" },
		-- linewise_hybrid_mode = true
	},

	vimdoc = {
		headings = {
			heading_1 = {
				sign = " ⣾⣿⠛⣿⣷ ",
				sign_hl = "Palette1Inv",

				marker_hl = "Palette1Bg",

				hl = "Palette1Fg"
			},
			heading_2 = {
				sign = " ⣠⠞⠛⠳⣄ ",
				sign_hl = "Palette2Inv",

				marker_hl = "Palette2",
				hl = "Palette2Fg"
			},
			heading_3 = {
				sign = " ⣯⣤⠛⣤⣽ ",
				sign_hl = "Palette3Inv",

				marker_hl = "Palette3",
				hl = "Palette3"
			},
			heading_4 = {
				sign = " ⠓⣠⣿⣄⠚ ",
				sign_hl = "Palette4Inv",

				marker_hl = "Palette4",
				hl = "Palette4"
			},
		},

		horizontal_rules = {
			parts = {
				{
					type = "repeating",
					repeat_amount = function (buffer)
						return math.ceil((vim.bo[buffer].tw - 3) / 2);
					end,

					text = "─",
					hl = {
						"HelpviewGradient1", "HelpviewGradient1",
						"HelpviewGradient2", "HelpviewGradient2",
						"HelpviewGradient3", "HelpviewGradient3",
						"HelpviewGradient4", "HelpviewGradient4",
						"HelpviewGradient5", "HelpviewGradient5",
						"HelpviewGradient6", "HelpviewGradient6",
						"HelpviewGradient7", "HelpviewGradient7",
						"HelpviewGradient8", "HelpviewGradient8",
						"HelpviewGradient8", "HelpviewGradient8",
					}
				},
				{
					type = "text",
					text = " • "
				},
				{
					type = "repeating",
					repeat_amount = function (buffer)
						return math.floor((vim.bo[buffer].tw - 3) / 2);
					end,
					direction = "right",

					text = "─",
					hl = {
						"HelpviewGradient1", "HelpviewGradient1",
						"HelpviewGradient2", "HelpviewGradient2",
						"HelpviewGradient3", "HelpviewGradient3",
						"HelpviewGradient4", "HelpviewGradient4",
						"HelpviewGradient5", "HelpviewGradient5",
						"HelpviewGradient6", "HelpviewGradient6",
						"HelpviewGradient7", "HelpviewGradient7",
						"HelpviewGradient8", "HelpviewGradient8",
						"HelpviewGradient8", "HelpviewGradient8",
					}
				},
			}
		},

		highlight_groups = {
			enable = true
		},

		tags = {
			default = {
				hl = "Tag",
				padding_left = " ",
				padding_right = " ",
			},

			["%.txt$"] = {
				hl = "Palette1",
				-- padding_left = " ",
				-- padding_right = " ",
			}
		},

		taglinks = {
			default = {
				hl = "Taglink",
				padding_left = " ",
				padding_right = " ",
			},

			["%.txt$"] = {
				hl = "Palette1",
				-- padding_left = " ",
				-- padding_right = " ",
			}
		},

		optionlinks = {
			default = {
				hl = "Optionlink",
				padding_left = " ",
				padding_right = " ",
			},

			["%.txt$"] = {
				hl = "Palette1",
				-- padding_left = " ",
				-- padding_right = " ",
			}
		},

		keycodes = {
			default = {
				hl = "Keycode",
				padding_left = " ",
				padding_right = " ",
			},

			["%.txt$"] = {
				hl = "Palette1",
				-- padding_left = " ",
				-- padding_right = " ",
			}
		},

		notes = {
			default = {
				hl = "Palette5Inv",
				padding_left = " ",
				padding_right = " ",
			},

			["[dD]eprecated"] = {
				hl = "Palette1Inv",
			},

			["[wW]arning"] = {
				hl = "Palette3Inv",
			},
		},

		arguments = {
			default = {
				hl = "Argument",
				padding_left = " ",
				padding_right = " ",
			},
		},

		inline_codes = {
			hl = "Palette5",
			padding_left = " ",
			padding_right = " ",
		},

		code_blocks = {
			border_hl = "Code",

			default = { block_hl = "Code" }
		},

		modelines = {
			border = "─",
			border_hl = "@text.todo.unchecked",

			data_types = {
				["nil"] = { value_hl = "@constant.builtin" },
				["string"] = { value_hl = "String" },
				["number"] = { value_hl = "Number" },
				["boolean"] = { value_hl = "Boolean" }
			},

			default = {
				option_hl = "@property",
				value_hl = "Comment"
			}
		}
	},

	---_
};

--- User configuration table.
---@type helpview.config
spec.config = vim.deepcopy(spec.default);

--- Table containing functions for
--- backwards compatibility
---@type { [string]: fun(config: any): table}
spec.fixup = {
	---+

	["modes"] = function (value)
		---+

		health.notify("deprecation", {
			option = "modes",
			alter = "preview → modes"
		});

		return {
			preview = {
				modes = value
			}
		};

		---_
	end,

	["hybrid_modes"] = function (value)
		---+

		health.notify("deprecation", {
			option = "hybrid_modes",
			alter = "preview → hybrid_modes"
		});

		return {
			preview = {
				hybrid_modes = value
			}
		};

		---_
	end,

	["buf_ignore"] = function (value)
		---+

		health.notify("deprecation", {
			option = "buf_ignore",
			alter = "preview → ignore_buftypes"
		});

		return {
			preview = {
				ignore_buftypes = value
			}
		};

		---_
	end,

	["callbacks"] = function (value)
		---+

		health.notify("deprecation", {
			option = "callbacks",
			alter = "preview → callbacks"
		});

		return {
			preview = {
				callbacks = value
			}
		};

		---_
	end,

	["arguments"] = function (config)
		---+

		local _o = {
			default = {}
		};

		for k, v in pairs(config) do
			if k == "conceal_before" then
				health.notify("deprecation", {
					option = "arguments → conceal_before"
				});
			elseif k == "conceal_after" then
				health.notify("deprecation", {
					option = "arguments → conceal_after"
				});
			else
				health.notify("deprecation", {
					option = "arguments → " .. k,
					alter = "vimdoc → arguments → default → " .. k
				});

				_o.default[k] = v;
			end
		end

		return {
			vimdoc = {
				arguments = _o
			}
		};

		---_
	end,

	["keycodes"] = function (config)
		---+

		local _o = {
			default = {}
		};

		for k, v in pairs(config) do
			if k == "conceal_before" then
				health.notify("deprecation", {
					option = "keycodes → conceal_before"
				});
			elseif k == "conceal_after" then
				health.notify("deprecation", {
					option = "keycodes → conceal_after"
				});
			else
				health.notify("deprecation", {
					option = "keycodes → " .. k,
					alter = "vimdoc → keycodes → default → " .. k
				});

				_o.default[k] = v;
			end
		end

		return {
			vimdoc = {
				keycodes = _o
			}
		};

		---_
	end,

	["mention_links"] = function (config)
		---+

		local _o = {
			default = {}
		};

		for k, v in pairs(config) do
			if k == "conceal_before" then
				health.notify("deprecation", {
					option = "mention_links → conceal_before"
				});
			elseif k == "conceal_after" then
				health.notify("deprecation", {
					option = "mention_links → conceal_after"
				});
			else
				health.notify("deprecation", {
					option = "mention_links → " .. k,
					alter = "vimdoc → mention_links → default → " .. k
				});

				_o.default[k] = v;
			end
		end

		return {
			vimdoc = {
				keycodes = _o
			}
		};

		---_
	end,

	["modelines"] = function (config)
		---+

		for k, _ in pairs(config) do
			health.notify("deprecation", {
				option = "modelines → " .. k,
				tip = {
					{ "See ", "Comment" },
					{ " :h helpview.nvim-vimdoc.modelines ", "DiagnosticVirtualTextHint" },
					{ " for the valid options.", "Comment" },
				}
			});
		end

		return {};

		---_
	end

	---_
};

--- Tries to fix deprecated config spec
---@param config table?
---@return table
spec.fix_config = function (config)
	---+${lua}

	if type(config) ~= "table" then
		return {};
	end

	--- Table containing valid options.
	local main = {
		renderers = config.renderers,
		highlight_groups = config.highlight_groups,

		preview = config.preview,
		vimdoc = config.vimdoc,
	};

	--- Table containing the fixed version of
	--- deprecated options.
	local fixed = {};

	for k, v in pairs(config) do
		if spec.fixup[k] then
			local _f, _r = pcall(spec.fixup[k], v);

			if _f == true then
				fixed = vim.tbl_deep_extend("force", fixed, _r);
			end
		end
	end

	if vim.tbl_isempty(fixed) == false then
		health.fixed_config = fixed;
	end

	return vim.tbl_deep_extend("force", main, fixed);
	---_
end

--- Updates user configuration table
---@param config helpview.config
spec.setup = function (config)
	---+

	config = spec.fix_config(config);
	spec.config = vim.tbl_deep_extend("force", spec.config, config);

	---_
end

--- Gets configuration option.
---@param keys string[]
---@param opts? { fallback: any, source: table?, ignore_enable : boolean }
---@return any
spec.get = function (keys, opts)
	---+

	keys = keys or {};
	opts = opts or {};

	local val = opts.source or spec.config;

	if type(val) ~= "table" and #keys > 1 then
		return opts.fallback;
	end

	for k, key in ipairs(keys) do
		val = val[key];

		if k ~= #keys then
			if type(val) ~= "table" then
				return opts.fallback;
			elseif opts.ignore_enable ~= true and val.enable == false then
				return opts.fallback;
			end
		end
	end

	if type(val) == "table" then
		if opts.ignore_enable ~= true and val.enable == false then
			return opts.fallback;
		else
			return val;
		end
	else
		return val or opts.fallback;
	end

	---_
end

return spec;
