return {
    exclude_files = {
        ".install", ".lua", ".luarocks", "source/windows/clink-completions/modules/JSON.lua", "lua_modules"
    },
    files = {
        spec = {
            std = "+busted"
        }
    },
    ignore = {
        "212",
        "631"
    },
    globals = {
        "mycelio_log", "mycelio_log_debug", "mycelio_log_info", "mycelio_log_warning", "mycelio_log_error", "logger",
        "clink", "error", "log", "os", "path", "pause", "rl", "rl_state", "settings", "string.comparematches",
        "popenrw", "string.equalsi", "string.explode", "string.matchlen", "unicode", "path", "settings", "rl",  "usbWatcher", "keyboardLayout", "setLayout", "setHindi", "hs",
        "cmderGitStatusOptIn", "pause", "it", "describe",
        "usbDeviceCallback", "hyper", "io.popenrw", "table"
    }
}
