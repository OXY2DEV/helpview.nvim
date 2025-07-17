local spec = {};

local health = require("helpview.health");
local utils = require("helpview.utils");

--- Default configuration table.
---@type helpview.config
spec.default = {
	renderers = {},

	preview = {
		enable = true,
		enable_hybrid_mode = true,

		modes = { "n", "c", "no" },
		hybrid_modes = {},
		linewise_hybrid_mode = false,

		filetypes = { "help" },
		ignore_previews = {},
		ignore_buftypes = {},
		condition = nil,

		max_buf_lines = 500,
		draw_range = { 2 * vim.o.lines, 2 * vim.o.lines },
		edit_range = { 0, 0 },

		debounce = 150,
		callbacks = {},

		icon_provider = "internal",

		splitview_winopts = { split = "right" },
		preview_winopts = { width = math.floor(80) }
	},

	vimdoc = {
		arguments = {
			enable = true,

			default = {
				hl = "Argument",
				padding_left = " ",
				padding_right = " ",
			},
		},

		code_blocks = {
			enable = true,

			border_hl = "Code",

			default = { block_hl = "HelpviewCode" },

			["diff"] = {
				block_hl = function (_, line)
					if line:match("^%s*%+") then
						return "HelpviewPalette4";
					elseif line:match("^%s*%-") then
						return "HelpviewPalette1";
					else
						return "HelpviewCode";
					end
				end
			}
		},

		headings = {
			enable = true,

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

		highlight_groups = {
			enable = true
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
					text = " ◈ "
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

		inline_codes = {
			enable = true,

			hl = "Palette5",

			padding_left = " ",
			padding_right = " ",
		},

		keycodes = {
			enable = true,

			default = {
				hl = "Keycode",

				padding_left = " ",
				padding_right = " ",
			}
		},

		modelines = {
			enable = true,

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
		},

		notes = {
			enable = true,

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

		optionlinks = {
			enable = true,

			default = {
				hl = "Optionlink",
				padding_left = " ",
				padding_right = " ",
			}
		},

		tags = {
			enable = true,

			default = {
				hl = "Tag",

				padding_left = " ",
				padding_right = " ",
			},

			["%.txt$"] = {
				hl = "Palette3",
			}
		},

		taglinks = {
			enable = true,

			default = {
				hl = "Taglink",

				padding_left = " ",
				padding_right = " ",
			}
		},

		urls = {
			enable = true,

			default = {
				icon = "󰌷 ",
				hl = "@string.special.url.vimdoc",
			},

			--- NOTE(@OXY2DEV): Github sites.

			["github%.com/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return string.match(item.label, "github%.com/([%a%d%-%_%.]+)%/?$");
				end
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>
				icon = "󰳐 ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+)%/?$");
				end
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/tree/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/tree/<branch>
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					local repo, branch = string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+)/tree/([%a%d%-%_%.]+)%/?$");
					return repo .. " at " .. branch;
				end
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/commits/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/commits/<branch>
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+/commits/[%a%d%-%_%.]+)%/?$");
				end
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/releases$"] = {
				--- github.com/<user>/<repo>/releases
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return "Releases • " .. string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+)%/releases$");
				end
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/tags$"] = {
				--- github.com/<user>/<repo>/tags
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return "Tags • " .. string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+)%/tags$");
				end
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/issues$"] = {
				--- github.com/<user>/<repo>/issues
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return "Issues • " .. string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+)%/issues$");
				end
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/pulls$"] = {
				--- github.com/<user>/<repo>/pulls
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return "Pull requests • " .. string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+)%/pulls$");
				end
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/wiki$"] = {
				--- github.com/<user>/<repo>/wiki
				icon = " ",
				hl = "HelpviewPalette0Fg",

				text = function (_, item)
					return "Wiki • " .. string.match(item.label, "github%.com/([%a%d%-%_%.]+/[%a%d%-%_%.]+)%/wiki$");
				end
			},

			--- NOTE(@OXY2DEV): Commonly used sites by programmers.

			["developer%.mozilla%.org"] = {
				priority = -9999,

				icon = "󰖟 ",
				hl = "HelpviewPalette5Fg"
			},

			["w3schools%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette4Fg"
			},

			["stackoverflow%.com"] = {
				priority = -9999,

				icon = "󰓌 ",
				hl = "HelpviewPalette2Fg"
			},

			["reddit%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette2Fg"
			},

			["github%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette6Fg"
			},

			["gitlab%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette2Fg"
			},

			["dev%.to"] = {
				priority = -9999,

				icon = "󱁴 ",
				hl = "HelpviewPalette0Fg"
			},

			["codepen%.io"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette6Fg"
			},

			["replit%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette2Fg"
			},

			["jsfiddle%.net"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette5Fg"
			},

			["npmjs%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette0Fg"
			},

			["pypi%.org"] = {
				priority = -9999,

				icon = "󰆦 ",
				hl = "HelpviewPalette0Fg"
			},

			["mvnrepository%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette1Fg"
			},

			["medium%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette6Fg"
			},

			["linkedin%.com"] = {
				priority = -9999,

				icon = "󰌻 ",
				hl = "HelpviewPalette5Fg"
			},

			["news%.ycombinator%.com"] = {
				priority = -9999,

				icon = " ",
				hl = "HelpviewPalette2Fg"
			},

			["neovim%.io/doc/user/.*#%_?.*$"] = {
				icon = " ",
				hl = "HelpviewPalette4Fg",

				text = function (_, item)
					local file, tag = string.match(item.label, "neovim%.io/doc/user/(.*)#%_?(.*)$");
					--- The actual website seems to show
					--- _ in the site name so, we won't
					--- be replacing `_`s with ` `s.
					file = string.gsub(file, "%.html$", "");

					return string.format("%s(%s) - Neovim docs", utils.normalize_str(file), tag);
				end
			},
			["neovim%.io/doc/user/.*$"] = {
				icon = " ",
				hl = "HelpviewPalette4Fg",

				text = function (_, item)
					local file = string.match(item.label, "neovim%.io/doc/user/(.*)$");
					file = string.gsub(file, "%.html$", "");

					return string.format("%s - Neovim docs", utils.normalize_str(file));
				end
			},

			["github%.com/vim/vim"] = {
				priority = -100,

				icon = " ",
				hl = "HelpviewPalette4Fg",
			},

			["github%.com/neovim/neovim"] = {
				priority = -100,

				icon = " ",
				hl = "HelpviewPalette4Fg",
			},

			["vim%.org"] = {
				icon = " ",
				hl = "HelpviewPalette4Fg",
			},

			["luals%.github%.io/wiki/?.*$"] = {
				icon = " ",
				hl = "HelpviewPalette5Fg",

				text = function (_, item)
					if string.match(item.label, "luals%.github%.io/wiki/(.-)/#(.+)$") then
						local page_mappings = {
							annotations = {
								["as"] = "@as",
								["alias"] = "@alias",
								["async"] = "@async",
								["cast"] = "@cast",
								["class"] = "@class",
								["deprecated"] = "@deprecated",
								["diagnostic"] = "@diagnostic",
								["enum"] = "@enum",
								["field"] = "@field",
								["generic"] = "@generic",
								["meta"] = "@meta",
								["module"] = "@module",
								["nodiscard"] = "@nodiscard",
								["operator"] = "@operator",
								["overload"] = "@overload",
								["package"] = "@package",
								["param"] = "@param",
								["see"] = "@see",
								["source"] = "@source",
								["type"] = "@type",
								["vaarg"] = "@vaarg",
								["version"] = "@version"
							}
						};

						local page, section = string.match(item.label, "luals%.github%.io/wiki/(.-)/#(.+)$");

						if page_mappings[page] and page_mappings[page][section] then
							section = page_mappings[page][section];
						else
							section = utils.normalize_str(string.gsub(section, "%-", " "));
						end

						return string.format("%s(%s) | Lua Language Server", utils.normalize_str(page), section);
					elseif string.match(item.label, "") then
						local page = string.match(item.label, "luals%.github%.io/wiki/(.-)/?$");

						return string.format("%s | Lua Language Server", utils.normalize_str(page));
					else
						return item.label;
					end
				end
			},
		}
	},
};

--- User configuration table.
---@type helpview.config
spec.config = vim.deepcopy(spec.default);

--- Table containing functions for
--- backwards compatibility
---@type table<string, fun(config: any): table>
spec.fixup = {
	["modes"] = function (value)
		health.notify("deprecation", {
			option = "modes",
			alter = "preview → modes"
		});

		return {
			preview = {
				modes = value
			}
		};
	end,

	["hybrid_modes"] = function (value)
		health.notify("deprecation", {
			option = "hybrid_modes",
			alter = "preview → hybrid_modes"
		});

		return {
			preview = {
				hybrid_modes = value
			}
		};
	end,

	["buf_ignore"] = function (value)
		health.notify("deprecation", {
			option = "buf_ignore",
			alter = "preview → ignore_buftypes"
		});

		return {
			preview = {
				ignore_buftypes = value
			}
		};
	end,

	["callbacks"] = function (value)
		health.notify("deprecation", {
			option = "callbacks",
			alter = "preview → callbacks"
		});

		return {
			preview = {
				callbacks = value
			}
		};
	end,

	["arguments"] = function (config)
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
	end,

	["keycodes"] = function (config)
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
	end,

	["mention_links"] = function (config)
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
	end,

	["modelines"] = function (config)
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
	end
};

--- Tries to fix deprecated config spec
---@param config table?
---@return helpview.config
spec.fix_config = function (config)
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
end

--- Updates user configuration table
---@param config helpview.config
spec.setup = function (config)
	config = spec.fix_config(config);
	spec.config = vim.tbl_deep_extend("force", spec.config, config);
end

--- Gets configuration option.
---@param keys string[]
---@param opts? { fallback: any, source: table?, ignore_enable: boolean }
---@return any
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
--- vim:foldmethod=indent:
