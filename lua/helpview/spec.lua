local spec = {};

spec.default = {
	---+${lua}

	preview = {
		-- enable = false,
		modes = { "n" },
		max_buf_lines = 500,
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

spec.config = vim.deepcopy(spec.default);

spec.setup = function (config)
	if type(config) == "table" then
		spec.config = vim.tbl_deep_extend("force", spec.config, config);
	end
end

spec.get = function (keys, opts)
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
end

return spec;
