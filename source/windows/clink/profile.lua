--[[

Clink profile for 'dotfiles' project.

See https://chrisant996.github.io/clink/clink.html for documentation. This is originally based
on the Cmder boot script (see https://github.com/cmderdev/cmder/blob/master/config/cmder.lua) but has
been somewhat heavily modified and also just out of date with most recent version.

]]

local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local color_cyan = "\x1b[36m"
local color_normal = "\x1b[m"

local settings = {
    color_vsc_unknown = "\x1b[30;1m",
    color_vsc_clean = "\x1b[1;37;40m",
    color_vsc_dirty = "\x1b[31;1m",
    color_prompt = "\x1b[93m",
    color_lambda = "\x1b[1;30;40m\x1b[1m",
    color_console = "\x1b[m",
    hg_status_detection = false,
    benchmark = false
}

profile_settings = {extension_npm_cache = 1, extension_npm = 1}

local function add_modules(input_path)
    local completions_dir = path.normalise(input_path)
    print('[clink] Loading modules from path: "' .. completions_dir .. '"')
    for _, lua_module in ipairs(clink.find_files(completions_dir .. '*.lua')) do
        -- Skip files that starts with _. This could be useful if some files should be ignored

        if profile_settings["extension_" .. lua_module:match [[(.*).lua$]]] ~= -1 then
            if not string.match(lua_module, '^_.*') then
                local filename = completions_dir .. lua_module
                -- use dofile instead of require because require caches loaded modules
                -- so config reloading using Alt-Q won't reload updated modules.
                dofile(filename)
                print('[clink] Module loaded: "' .. lua_module .. '"')
            end
        end
    end
    print('[clink] Added all modules from path: "' .. completions_dir .. '"')
end

local cwd_prompt = clink.promptfilter(30)
function cwd_prompt:filter(prompt)
    return settings.color_prompt .. os.getcwd() .. color_normal
end

-- A prompt filter that appends the current git branch.
local git_branch_prompt = clink.promptfilter(65)
function git_branch_prompt:filter(prompt)
    local line = io.popen("git branch --show-current 2>nul"):read("*a")
    local branch = line:match("(.+)\n")
    if branch then
        return prompt .. " " .. color_cyan .. "[" .. branch .. "]" .. color_normal
    end
end

-- A prompt filter that adds a line feed and angle bracket.
local bracket_prompt = clink.promptfilter(150)
function bracket_prompt:filter(prompt)
    return prompt .. "\n → "
end

add_modules(mycelio_root_dir .. "/source/windows/clink-completions/")
add_modules(mycelio_root_dir .. "/source/windows/clink/modules/")
