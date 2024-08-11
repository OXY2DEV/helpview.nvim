local languages = {};

languages.ft_map = {
    ["c"] = "c",
    ["c_plus_plus"] = "cpp",
    ["java"] = "java",
    ["python"] = "py",
    ["javascript"] = "js",
    ["typescript"] = "ts",
    ["ruby"] = "rb",
    ["php"] = "php",
    ["c_sharp"] = "cs",
    ["swift"] = "swift",
    ["kotlin"] = "kt",
    ["go"] = "go",
    ["rust"] = "rs",
    ["r"] = "r",
    ["perl"] = "pl",
    ["lua"] = "lua",
    ["shell"] = "sh",
    ["powershell"] = "ps1",
    ["scala"] = "scala",
    ["haskell"] = "hs",
    ["visual_basic"] = "vb",
    ["julia"] = "jl",
    ["clojure"] = "clj",
    ["dart"] = "dart",
    ["groovy"] = "groovy",
    ["matlab"] = "m",
    ["erlang"] = "erl",
    ["elixir"] = "ex",
    ["elm"] = "elm",
    ["fortran"] = "f90",
    ["ocaml"] = "ml",
    ["verilog"] = "v",
    ["vhdl"] = "vhd",
    ["sql"] = "sql",
    ["ada"] = "adb",
    ["prolog"] = "p",
    ["tcl"] = "tcl",
    ["scheme"] = "scm",
    ["nim"] = "nim",
    ["awk"] = "awk",
    ["coffeescript"] = "coffee",
    ["f_sharp"] = "fs",
    ["pascal"] = "pas",
    ["haxe"] = "hx",
    ["haxe_shader_language"] = "hxsl",
    ["haxe_project"] = "hxproj",
    ["xquery"] = "x",
    ["idl"] = "idp",
    ["interface_definition_language"] = "idl",
    ["asp"] = "asp",
    ["lisp"] = "lsp",
    ["common_lisp"] = "cl",
    ["opencl"] = "cl",
    ["d"] = "d",
    ["gdscript"] = "gd",
    ["glsl"] = "glsl",
    ["c_header"] = "h",
    ["c_plus_plus_header"] = "hpp",
    ["erlang_header"] = "hrl",
    ["lisp_identifier"] = "lid",
    ["node_js_es_module"] = "mjs",
    ["markdown"] = "md",
    ["n"] = "n",
    ["processing"] = "pde",
    ["qml"] = "qml",
    ["red"] = "red",
    ["reason"] = "re",
    ["racket"] = "rkt",
    ["supercollider"] = "sc",
    ["solidity"] = "sol",
    ["smalltalk"] = "st",
    ["stylus"] = "styl",
    ["scheme_source"] = "sx",
    ["isabelle"] = "thy",
    ["toml"] = "toml",
    ["vala"] = "vala",
    ["vala_api"] = "vapi",
    ["vimscript"] = "vim",
    ["wix"] = "wxs",
    ["xslt"] = "xt",
    ["yaml"] = "yaml",
    ["zcml"] = "zcml",
    ["zenscript"] = "zs",
    ["zsh"] = "zsh",
    ["basic"] = "bas",
    ["batch"] = "bat",
    ["blitzmax"] = "bmx",
    ["boo"] = "boo",
    ["bluespec_systemverilog"] = "bsv",
    ["c2hs"] = "chs",
    ["clips"] = "clp",
    ["batch_script"] = "cmd",
    ["cobol"] = "cob",
    ["cobol_legacy"] = "cbl",
    ["camal"] = "cma",
    ["crmscript"] = "crm",
    ["eiffel"] = "e",
    ["eagle"] = "ea",
    ["emberscript"] = "em",
    ["elixir_script"] = "exs",
    ["f"] = "f",
    ["fennel"] = "fnl",
    ["g"] = "g",
    ["gds"] = "gd",
    ["gsl"] = "glf",
    ["google_apps_script"] = "gs",
    ["hcl"] = "hcl",
    ["haxe_project_file"] = "hxproj",
    ["agda"] = "lagda",
    ["lean"] = "lean",
    ["lassoscript"] = "ls",
    ["lasso"] = "lss",
    ["maxscript"] = "mc",
    ["mumps"] = "mu",
    ["myghty"] = "myt",
    ["runoff"] = "rno",
    ["sass"] = "scss",
    ["smarty"] = "tpl",
    ["ur"] = "ur",
    ["vbscript"] = "vbproj",
    ["wolfram"] = "wlk",
    ["xpl"] = "xpl",
    ["xquery_file"] = "xqy",
    ["xs"] = "xs",
    ["z"] = "z"
}

languages.icons = {
	["c"] = " ",
	["cpp"] = " ",
	["java"] = " ",
	["py"] = " ",
	["js"] = "󰌞 ",
	["ts"] = "󰛦 ",
	["rb"] = " ",
	["php"] = " ",
	["cs"] = "󰌛 ",
	["swift"] = "󰛥 ",
	["kt"] = "󱈙 ",
	["go"] = " ",
	["rs"] = "󱘗 ",
	["r"] = "󰟔 ",
	["pl"] = " ",
	["lua"] = " ",
	["sh"] = " ",
	["zsh"] = " ",
	["ps1"] = "󰨊 ",
	["scala"] = " ",
	["hs"] = " ",
	["jl"] = " ",
	["clj"] = " ",
	["dart"] = " ",
	["groovy"] = " ",
	["erl"] = " ",
	["ex"] = " ",
	["elm"] = " ",
	["f90"] = "󱈚 ",
	["ml"] = " ",
	["sql"] = " ",
	["ada"] = " ",
	["p"] = " ",
	["nim"] = " ",
	["coffeescript"] = " ",
	["fs"] = " ",
	["cl"] = " ",
	["gd"] = " ",
	["md"] = " ",
	["toml"] = " ",
	["html"] = " ",
	["css"] = " ",
	["scss"] = " ",
	["vim"] = " "
};

languages.get = function (name)
	if not name then
		return "󰡯 ";
	end

	if languages.ft_map[name:lower()] then
		name = languages.ft_map[name:lower()];
	end

	if languages.icons[name:lower()] then
		return languages.icons[name:lower()];
	end

	return "󰡯 ";
end

languages.name = function (str)
	if not str or str == "" then
		return "Unknown";
	end

	local name = str;

	for nm, ft in pairs(languages.ft_map) do
		if str == ft then
			name = nm;
			break;
		end
	end

	return string.gsub(name, "^%l", string.upper);
end

return languages;
