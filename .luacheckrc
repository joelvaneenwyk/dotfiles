return {
    exclude_files = {
        ".install", ".lua", ".luarocks", "modules/JSON.lua", "lua_modules"
    },
    files = { spec = { std = "+busted" } },
    ["$schema"] = "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
    ["addonManager.enable"] = true,
    ["codeLens.enable"] = true,
    ["completion.enable"] = true,
    diagnostics = {
        disable = { "undefined-field", "cast-local-type", "lowercase-global" },
        enable = true,
        globals = {
            "ARGHELPER_DISABLE_DESCRIPTIONS", "CLINK_EXE",
            "clink_gizmos_command_substitution", "clink", "cmderGitStatusOptIn",
            "console", "describe", "DISABLE_GIT_REMOTE_IN_PROMPT", "explode",
            "flexprompt", "fzf_bindings", "fzf_complete_force",
            "fzf_complete_internal", "fzf_complete", "fzf_directory",
            "fzf_file", "fzf_history", "fzf_selectcomplete", "hs", "it", "lfs",
            "log", "logger", "matchicons", "msbuild_parser_data", "NONL",
            "os.getcwd", "path", "pause", "rl_state", "rl", "settings",
            "string.explode", "unicode"
        }
    },
    ["format.defaultConfig"] = { indentSize = "2" },
    ["format.enable"] = true,
    ["hint.enable"] = false,
    ["hint.setType"] = true,
    ["runtime.version"] = "Lua 5.3",
    ["semantic.enable"] = true,
    ["workspace.checkThirdParty"] = false,
    ["workspace.ignoreDir"] = { ".vscode" },
    ["workspace.library"] = {
        "${3rd}/luassert/library",
        "${userHome}/AppData/Roaming/Code/User/globalStorage/sumneko.lua/addonManager/addons/busted/module/library",
        "${userHome}/AppData/Roaming/Code/User/globalStorage/sumneko.lua/addonManager/addons/lldebugger/module/library",
        "${userHome}/AppData/Roaming/Code/User/globalStorage/sumneko.lua/addonManager/addons/luafilesystem/module/library",
        "${userHome}/AppData/Roaming/Code/User/globalStorage/sumneko.lua/addonManager/addons/lualogging/module/library",
        "${userHome}/AppData/Roaming/Code/User/globalStorage/sumneko.lua/addonManager/addons/luaunit/module/library",
        "macos/.hammerspoon", "micro/.config",
        "source/windows/clink-completions", "source/windows/clink"
    },
    globals = {
        "_co_error_handler", "_compat_warning", "_error_handler",
        "_error_handler_ret", "clink", "CLINK_EXE", "console",
        "coroutine.override_isgenerator", "coroutine.override_isprompt",
        "coroutine.override_src", "io", "log", "os", "path", "pause", "rl",
        "rl_state", "settings", "string", "unicode"
    }
}
